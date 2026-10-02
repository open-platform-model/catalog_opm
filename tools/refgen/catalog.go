package main

import (
	"fmt"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/ast"
	"cuelang.org/go/cue/build"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/format"
	"cuelang.org/go/cue/load"
)

// Member kinds, as the catalog maps and the page directories name them.
const (
	kindResource  = "resources"
	kindTrait     = "traits"
	kindBlueprint = "blueprints"
)

// module is one loaded catalog module.
type module struct {
	label   string // module directory name: src
	path    string // module path with its major: opmodel.dev/catalogs/opm@v4
	base    string // module path without its major: opmodel.dev/catalogs/opm
	version string // identity.Version, the build these pages describe

	members      []*member      // resources, traits and blueprints, sorted by kind then page name
	transformers []*transformer // sorted by name
	src          *sourceIndex
}

// member is one resource, trait or blueprint as its catalog map lists it.
type member struct {
	kind           string
	fqn            string
	name           string
	apiVersion     string
	modulePath     string
	catalogVersion string
	description    string
	category       string
	doc            string // the doc comment, comment markers removed
	def            *defSrc

	fulfilment      string // resources and traits: catalog or provider
	optionalDefault *bool  // traits: the default of optional
	appliesTo       []string
	composedRes     []string // blueprints
	composedTraits  []string // blueprints
	matchLabels     []label
	specKey         string // the single field under spec

	page string // page file name without .md, set by renderSite
}

// label is one matchLabels or requiredLabels entry.
type label struct {
	key      string
	value    string // CUE text: a quoted string, or a constraint such as a disjunction
	concrete string // the value when it is a concrete string
	required bool
}

// transformer is one entry of a catalog's #transformers map.
type transformer struct {
	name        string
	fqn         string
	description string
	reqLabels   []label
	reqRes      []string
	optRes      []string
	reqTraits   []string
	optTraits   []string
}

// loadModule loads one catalog module from <root>/<label> and reads its
// members and transformers from the catalog maps.
func loadModule(root, label string) (*module, error) {
	dir := filepath.Join(root, label)
	insts := load.Instances([]string{"."}, &load.Config{Dir: dir})
	if len(insts) != 1 {
		return nil, fmt.Errorf("%s: expected one root package, got %d", label, len(insts))
	}
	if err := insts[0].Err; err != nil {
		return nil, fmt.Errorf("%s: load: %w", label, err)
	}
	ctx := cuecontext.New()
	cat := ctx.BuildInstance(insts[0])
	if err := cat.Err(); err != nil {
		return nil, fmt.Errorf("%s: evaluate: %w", label, err)
	}

	m := &module{label: label}
	var err error
	if m.path, err = str(cat, "metadata.modulePath"); err != nil {
		return nil, fmt.Errorf("%s: %w", label, err)
	}
	if m.version, err = str(cat, "metadata.version"); err != nil {
		return nil, fmt.Errorf("%s: %w", label, err)
	}
	m.base = stripMajor(m.path)

	src, err := indexSource(root, m.base, insts[0])
	if err != nil {
		return nil, fmt.Errorf("%s: %w", label, err)
	}
	m.src = src

	defs, err := memberDefs(ctx, src)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", label, err)
	}

	for _, kind := range []string{kindResource, kindTrait, kindBlueprint} {
		entries, err := mapEntries(cat, "#"+kind)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", label, err)
		}
		for _, e := range entries {
			mem, err := readMember(kind, e.key, e.val, defs)
			if err != nil {
				return nil, fmt.Errorf("%s: %s: %w", label, e.key, err)
			}
			m.members = append(m.members, mem)
		}
	}
	entries, err := mapEntries(cat, "#transformers")
	if err != nil {
		return nil, fmt.Errorf("%s: %w", label, err)
	}
	for _, e := range entries {
		t, err := readTransformer(e.val)
		if err != nil {
			return nil, fmt.Errorf("%s: %s: %w", label, e.key, err)
		}
		m.transformers = append(m.transformers, t)
	}
	sort.Slice(m.transformers, func(i, j int) bool { return m.transformers[i].name < m.transformers[j].name })
	return m, nil
}

type entry struct {
	key string
	val cue.Value
}

// mapEntries returns a catalog map's entries in key order.
func mapEntries(v cue.Value, path string) ([]entry, error) {
	mv := v.LookupPath(cue.ParsePath(path))
	if !mv.Exists() {
		return nil, nil
	}
	it, err := mv.Fields()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	var out []entry
	for it.Next() {
		out = append(out, entry{key: it.Selector().Unquoted(), val: it.Value()})
	}
	sort.Slice(out, func(i, j int) bool { return out[i].key < out[j].key })
	return out, nil
}

// memberDefs builds every resource, trait and blueprint package of the
// module and maps each member definition's evaluated fqn to its source.
func memberDefs(ctx *cue.Context, src *sourceIndex) (map[string]*defSrc, error) {
	out := map[string]*defSrc{}
	for _, p := range src.sortedPkgs() {
		rel := strings.TrimPrefix(p.importPath, src.base+"/")
		kind, _, ok := strings.Cut(rel, "/")
		if !ok || (kind != kindResource && kind != kindTrait && kind != kindBlueprint) {
			continue
		}
		pv := ctx.BuildInstance(p.inst)
		if err := pv.Err(); err != nil {
			return nil, fmt.Errorf("%s: %w", p.importPath, err)
		}
		for _, d := range p.sortedDefs() {
			if strings.HasPrefix(d.name, "_") {
				continue
			}
			dv := pv.LookupPath(cue.ParsePath(d.name))
			k, err := dv.LookupPath(cue.ParsePath("kind")).String()
			if err != nil || (k != "Resource" && k != "Trait" && k != "Blueprint") {
				continue
			}
			fqn, err := dv.LookupPath(cue.ParsePath("metadata.fqn")).String()
			if err != nil {
				continue
			}
			if prev, dup := out[fqn]; dup {
				return nil, fmt.Errorf("%s is declared by both %s and %s", fqn, prev.name, d.name)
			}
			out[fqn] = d
		}
	}
	return out, nil
}

// readMember reads one catalog map entry.
func readMember(kind, fqn string, v cue.Value, defs map[string]*defSrc) (*member, error) {
	d, ok := defs[fqn]
	if !ok {
		return nil, fmt.Errorf("no definition under %s/ declares this fqn", kind)
	}
	m := &member{kind: kind, fqn: fqn, def: d}
	var err error
	for _, f := range []struct {
		path string
		dst  *string
	}{
		{"metadata.name", &m.name},
		{"metadata.apiVersion", &m.apiVersion},
		{"metadata.modulePath", &m.modulePath},
		{"metadata.catalogVersion", &m.catalogVersion},
		{"metadata.description", &m.description},
	} {
		if *f.dst, err = str(v, f.path); err != nil {
			return nil, err
		}
	}
	m.description = strings.TrimSpace(m.description)
	if m.description == "" {
		return nil, fmt.Errorf("metadata.description is blank (task vet:descriptions)")
	}
	cat := strings.TrimSuffix(kind, "s") + ".opmodel.dev/category"
	if c, err := v.LookupPath(cue.MakePath(cue.Str("metadata"), cue.Str("labels"), cue.Str(cat))).String(); err == nil {
		m.category = c
	}
	m.doc = docText(d.field)

	if kind != kindBlueprint {
		fv, _ := v.LookupPath(cue.ParsePath("fulfilment")).Default()
		if m.fulfilment, err = fv.String(); err != nil {
			return nil, fmt.Errorf("fulfilment: %w", err)
		}
	}
	if kind == kindTrait {
		ov, ok := v.LookupPath(cue.ParsePath("optional")).Default()
		if !ok {
			return nil, fmt.Errorf("optional states no default posture")
		}
		b, err := ov.Bool()
		if err != nil {
			return nil, fmt.Errorf("optional: %w", err)
		}
		m.optionalDefault = &b
		if m.appliesTo, err = fqnList(v, "appliesTo"); err != nil {
			return nil, err
		}
	}
	if kind == kindBlueprint {
		if m.composedRes, err = fqnList(v, "composedResources"); err != nil {
			return nil, err
		}
		if m.composedTraits, err = fqnList(v, "composedTraits"); err != nil {
			return nil, err
		}
	}
	if m.matchLabels, err = labels(v.LookupPath(cue.ParsePath("matchLabels"))); err != nil {
		return nil, fmt.Errorf("matchLabels: %w", err)
	}
	// A constraint rather than a value evaluates together with core's label
	// type; show it as the catalog wrote it.
	for i, l := range m.matchLabels {
		if l.concrete == "" {
			if a := authoredLabel(d, l.key); a != "" {
				m.matchLabels[i].value = a
			}
		}
	}
	keys, err := fieldNames(v.LookupPath(cue.ParsePath("spec")))
	if err != nil || len(keys) != 1 {
		return nil, fmt.Errorf("spec: expected exactly one field, got %v", keys)
	}
	m.specKey = keys[0]
	return m, nil
}

// readTransformer reads one #transformers entry.
func readTransformer(v cue.Value) (*transformer, error) {
	t := &transformer{}
	var err error
	if t.name, err = str(v, "metadata.name"); err != nil {
		return nil, err
	}
	if t.fqn, err = str(v, "metadata.fqn"); err != nil {
		return nil, err
	}
	if t.description, err = str(v, "metadata.description"); err != nil {
		return nil, err
	}
	if t.reqLabels, err = labels(v.LookupPath(cue.ParsePath("requiredLabels"))); err != nil {
		return nil, err
	}
	for _, f := range []struct {
		path string
		dst  *[]string
	}{
		{"requiredResources", &t.reqRes},
		{"optionalResources", &t.optRes},
		{"requiredTraits", &t.reqTraits},
		{"optionalTraits", &t.optTraits},
	} {
		if *f.dst, err = fieldNames(v.LookupPath(cue.ParsePath(f.path))); err != nil {
			return nil, fmt.Errorf("%s: %w", f.path, err)
		}
	}
	return t, nil
}

// str reads a concrete string at path.
func str(v cue.Value, path string) (string, error) {
	s, err := v.LookupPath(cue.ParsePath(path)).String()
	if err != nil {
		return "", fmt.Errorf("%s: %w", path, err)
	}
	return s, nil
}

// fieldNames returns the regular field names of a struct in source order; an
// absent struct has none.
func fieldNames(v cue.Value) ([]string, error) {
	if !v.Exists() {
		return nil, nil
	}
	it, err := v.Fields()
	if err != nil {
		return nil, err
	}
	var out []string
	for it.Next() {
		out = append(out, it.Selector().Unquoted())
	}
	return out, nil
}

// fqnList reads a list of members and returns their fqns in list order.
func fqnList(v cue.Value, path string) ([]string, error) {
	lv := v.LookupPath(cue.ParsePath(path))
	if !lv.Exists() {
		return nil, nil
	}
	it, err := lv.List()
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	var out []string
	for it.Next() {
		f, err := it.Value().LookupPath(cue.ParsePath("metadata.fqn")).String()
		if err != nil {
			return nil, fmt.Errorf("%s: %w", path, err)
		}
		out = append(out, f)
	}
	return out, nil
}

// labels reads a label map, required and optional fields included, in
// source order.
func labels(v cue.Value) ([]label, error) {
	if !v.Exists() {
		return nil, nil
	}
	it, err := v.Fields(cue.Optional(true))
	if err != nil {
		return nil, err
	}
	var out []label
	for it.Next() {
		sel := it.Selector()
		l := label{key: sel.Unquoted(), required: sel.ConstraintType() == cue.RequiredConstraint}
		fv := it.Value()
		if s, err := fv.String(); err == nil && fv.IsConcrete() {
			l.concrete = s
			l.value = strconv.Quote(s)
		} else {
			b, err := format.Node(fv.Syntax())
			if err != nil {
				return nil, fmt.Errorf("%s: %w", l.key, err)
			}
			l.value = strings.TrimSpace(string(b))
		}
		out = append(out, l)
	}
	return out, nil
}

var majorSuffix = regexp.MustCompile(`@v[0-9]+$`)

// stripMajor drops a trailing @vN and a :package qualifier from an import
// or module path.
func stripMajor(p string) string {
	if i := strings.IndexByte(p, ':'); i >= 0 {
		p = p[:i]
	}
	return majorSuffix.ReplaceAllString(p, "")
}

// sourceIndex holds the parsed source of every package of one module that
// the catalog package reaches.
type sourceIndex struct {
	root string // repository root, for repo-relative file names
	base string // module path without its major
	pkgs map[string]*sourcePkg
}

type sourcePkg struct {
	importPath string // without the major
	inst       *build.Instance
	defs       map[string]*defSrc
}

// defSrc is one top-level definition and the file context it was written in.
type defSrc struct {
	pkg      *sourcePkg
	name     string
	field    *ast.Field
	filename string            // repository-relative
	imports  map[string]string // alias -> import path, as written in the file
}

// indexSource walks the catalog instance and its imports and indexes every
// top-level definition of the module's own packages.
func indexSource(root, base string, inst *build.Instance) (*sourceIndex, error) {
	idx := &sourceIndex{root: root, base: base, pkgs: map[string]*sourcePkg{}}
	var walk func(*build.Instance) error
	walk = func(in *build.Instance) error {
		p := stripMajor(in.ImportPath)
		if p != base && !strings.HasPrefix(p, base+"/") {
			return nil
		}
		if _, seen := idx.pkgs[p]; seen {
			return nil
		}
		sp := &sourcePkg{importPath: p, inst: in, defs: map[string]*defSrc{}}
		idx.pkgs[p] = sp
		for _, f := range in.Files {
			rel, err := filepath.Rel(root, f.Filename)
			if err != nil {
				return err
			}
			imports := map[string]string{}
			for spec := range f.ImportSpecs() {
				path, err := strconv.Unquote(spec.Path.Value)
				if err != nil {
					return err
				}
				alias := ""
				if spec.Name != nil {
					alias = spec.Name.Name
				} else {
					alias = filepath.Base(stripMajor(path))
				}
				imports[alias] = path
			}
			for _, decl := range f.Decls {
				fd, ok := decl.(*ast.Field)
				if !ok {
					continue
				}
				name, _, err := ast.LabelName(fd.Label)
				if err != nil || !isDefName(name) {
					continue
				}
				stripMaintainerComments(fd)
				sp.defs[name] = &defSrc{pkg: sp, name: name, field: fd, filename: filepath.ToSlash(rel), imports: imports}
			}
		}
		for _, imp := range in.Imports {
			if err := walk(imp); err != nil {
				return err
			}
		}
		return nil
	}
	if err := walk(inst); err != nil {
		return nil, err
	}
	return idx, nil
}

func (s *sourceIndex) sortedPkgs() []*sourcePkg {
	out := make([]*sourcePkg, 0, len(s.pkgs))
	for _, p := range s.pkgs {
		out = append(out, p)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].importPath < out[j].importPath })
	return out
}

func (p *sourcePkg) sortedDefs() []*defSrc {
	out := make([]*defSrc, 0, len(p.defs))
	for _, d := range p.defs {
		out = append(out, d)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].name < out[j].name })
	return out
}

// lookup finds a definition by normalised import path and name.
func (s *sourceIndex) lookup(pkg, name string) (*defSrc, bool) {
	p, ok := s.pkgs[stripMajor(pkg)]
	if !ok {
		return nil, false
	}
	d, ok := p.defs[name]
	return d, ok
}

func isDefName(name string) bool {
	return strings.HasPrefix(name, "#") || strings.HasPrefix(name, "_#")
}

// docText returns the declaration's doc comment, the `//` block directly
// above it, with the comment markers removed and paragraph breaks kept.
func docText(f *ast.Field) string {
	for _, cg := range ast.Comments(f) {
		if cg.Doc {
			return strings.TrimSpace(cg.Text())
		}
	}
	return ""
}

// stripMaintainerComments removes, everywhere inside a declaration, the
// comment groups that are rationale for maintainers rather than contract: a
// `// WHY` block and a `////` banner.
func stripMaintainerComments(n ast.Node) {
	ast.Walk(n, func(n ast.Node) bool {
		cgs := ast.Comments(n)
		if len(cgs) == 0 {
			return true
		}
		kept := cgs[:0:0]
		for _, cg := range cgs {
			if len(cg.List) > 0 {
				first := strings.TrimSpace(strings.TrimPrefix(cg.List[0].Text, "//"))
				if strings.HasPrefix(first, "WHY") || strings.HasPrefix(first, "//") {
					continue
				}
			}
			kept = append(kept, cg)
		}
		if len(kept) != len(cgs) {
			ast.SetComments(n, kept)
		}
		return true
	}, nil)
}
