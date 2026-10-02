package main

import (
	"fmt"
	"strings"

	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/format"
)

// ref is a reference to a definition: a package-local `#Name`, or an
// imported `alias.#Name`.
type ref struct {
	pkg   string // import path as written (the defining package for a local ref)
	name  string
	alias string // the import alias, empty for a local reference
}

func (r ref) key() string { return stripMajor(r.pkg) + "." + r.name }

// display is the reference as an author writes it.
func (r ref) display() string {
	if r.alias == "" {
		return r.name
	}
	return r.alias + "." + r.name
}

// specView is a member's spec, rendered for its page.
type specView struct {
	code     string    // the spec field and every expanded definition, formatted CUE
	linked   []specRef // references to another member's own spec schema
	external []specRef // references outside the module, or into vendored types
}

type specRef struct {
	ref
	owner *member // linked: the member whose spec schema it is
}

// vendoredPrefix marks the vendored Kubernetes types: they are upstream API
// shapes, named on a page rather than printed in full.
const vendoredPrefix = "/schemas/kubernetes/"

// specField finds the `spec:` field of a member definition: a field of the
// struct literal the definition unifies with its core kind.
func specField(e ast.Expr) *ast.Field {
	switch x := e.(type) {
	case *ast.BinaryExpr:
		if f := specField(x.X); f != nil {
			return f
		}
		return specField(x.Y)
	case *ast.StructLit:
		for _, el := range x.Elts {
			if f, ok := el.(*ast.Field); ok {
				if n, _, err := ast.LabelName(f.Label); err == nil && n == "spec" {
					return f
				}
			}
		}
	case *ast.ParenExpr:
		return specField(x.X)
	}
	return nil
}

// refsIn lists the definition references in n, in source order and without
// repeats. Field labels are not references; a local name counts only when
// the package declares it at top level.
func refsIn(n ast.Node, ctx *defSrc) []ref {
	var out []ref
	seen := map[string]bool{}
	add := func(r ref) {
		if !seen[r.key()] {
			seen[r.key()] = true
			out = append(out, r)
		}
	}
	var before func(ast.Node) bool
	before = func(n ast.Node) bool {
		switch x := n.(type) {
		case *ast.Field:
			if x.Value != nil {
				ast.Walk(x.Value, before, nil)
			}
			return false
		case *ast.SelectorExpr:
			if id, ok := x.X.(*ast.Ident); ok {
				if path, ok := ctx.imports[id.Name]; ok {
					if sel, _, err := ast.LabelName(x.Sel); err == nil && isDefName(sel) {
						add(ref{pkg: path, name: sel, alias: id.Name})
					}
					return false
				}
			}
		case *ast.Ident:
			if isDefName(x.Name) {
				if _, ok := ctx.pkg.defs[x.Name]; ok {
					add(ref{pkg: ctx.pkg.importPath, name: x.Name})
				}
			}
		}
		return true
	}
	ast.Walk(n, before, nil)
	return out
}

// specRoots maps every definition a member's spec field references directly
// to that member. A spec root of another member is linked, not repeated.
func specRoots(mods ...*module) map[string]*member {
	roots := map[string]*member{}
	for _, mod := range mods {
		for _, m := range mod.members {
			sf := specField(m.def.field.Value)
			if sf == nil {
				continue
			}
			for _, r := range refsIn(sf, m.def) {
				if _, taken := roots[r.key()]; !taken {
					roots[r.key()] = m
				}
			}
		}
	}
	return roots
}

// renderSpec prints a member's spec field, then every definition of the
// module it references, transitively, grouped by package: the member's own
// package first, then each other package in order of first reference.
func renderSpec(mod *module, m *member, roots map[string]*member) (*specView, error) {
	sf := specField(m.def.field.Value)
	if sf == nil {
		return nil, fmt.Errorf("%s: no spec field in %s", m.fqn, m.def.name)
	}
	own := map[string]bool{}
	queue := refsIn(sf, m.def)
	for _, r := range queue {
		own[r.key()] = true
	}

	view := &specView{}
	seen := map[string]bool{}
	var order []string              // package import paths, in order of first expansion
	byPkg := map[string][]*defSrc{} // expanded definitions per package
	aliasOf := map[string]string{}  // package -> alias at its first reference
	for len(queue) > 0 {
		r := queue[0]
		queue = queue[1:]
		if seen[r.key()] {
			continue
		}
		seen[r.key()] = true
		if owner, ok := roots[r.key()]; ok && owner != m && !own[r.key()] {
			view.linked = append(view.linked, specRef{ref: r, owner: owner})
			continue
		}
		d, ok := mod.src.lookup(r.pkg, r.name)
		if !ok || strings.Contains(stripMajor(r.pkg), vendoredPrefix) {
			view.external = append(view.external, specRef{ref: r})
			continue
		}
		p := d.pkg.importPath
		if _, ok := byPkg[p]; !ok {
			order = append(order, p)
			aliasOf[p] = r.alias
		}
		byPkg[p] = append(byPkg[p], d)
		queue = append(queue, refsIn(d.field.Value, d)...)
	}

	var b strings.Builder
	code, err := formatNode(sf)
	if err != nil {
		return nil, err
	}
	b.WriteString(code)
	ownPkg := m.def.pkg.importPath
	// The member's own package first, whatever order the walk found it in.
	pkgs := []string{}
	if _, ok := byPkg[ownPkg]; ok {
		pkgs = append(pkgs, ownPkg)
	}
	for _, p := range order {
		if p != ownPkg {
			pkgs = append(pkgs, p)
		}
	}
	for _, p := range pkgs {
		if p != ownPkg {
			fmt.Fprintf(&b, "\n\n// Defined in %s, imported as %s.", p, aliasOf[p])
		}
		for _, d := range byPkg[p] {
			code, err := formatNode(d.field)
			if err != nil {
				return nil, err
			}
			b.WriteString("\n\n")
			b.WriteString(code)
		}
	}
	view.code = b.String()
	return view, nil
}

// formatNode prints one declaration with cue/format.
func formatNode(n ast.Node) (string, error) {
	out, err := format.Node(n)
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}
