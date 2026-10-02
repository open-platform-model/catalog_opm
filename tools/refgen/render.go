package main

import (
	"fmt"
	"regexp"
	"sort"
	"strings"
)

// Page locations, relative to the repository root, and the site URLs they
// publish at.
const (
	referenceDir   = "docs/site/reference"
	membersDir     = referenceDir + "/catalog-members"
	membersURL     = "/docs/reference/catalog-members/"
	rawPage        = referenceDir + "/kubernetes-resources.md"
	enforcementURL = "/docs/concepts/what-enforces-a-rule/"
	decisionsURL   = "/enhancements/0010/decisions/"
	contractURL    = "/docs/reference/catalog-contract/"
)

// kinds lists the abstraction family's member kinds in page order:
// blueprints first.
var kinds = []struct {
	dir, title, singular string
	weight               int
	what                 string
}{
	{kindBlueprint, "Blueprints", "blueprint", 1, "A blueprint composes resources and traits into one workload shape that a component attaches in one step."},
	{kindResource, "Resources", "resource", 2, "A resource is something a component deploys. Every resource a component declares is a required demand."},
	{kindTrait, "Traits", "trait", 3, "A trait adds behaviour to a component. Its optional posture decides what happens when nothing on the platform handles it."},
}

// page is one output: a whole generated file, or the generated block of an
// authored file.
type page struct {
	path  string // repository-relative
	body  string // the whole file, or the text between the markers
	block bool   // true: splice body between the markers of the existing file
}

// renderSite renders every page of both catalogs.
func renderSite(root string, abs, raw *module) ([]page, error) {
	assignPages(abs)
	roots := specRoots(abs)
	byFQN := map[string]*member{}
	for _, m := range abs.members {
		byFQN[m.fqn] = m
	}

	var pages []page
	counts := map[string]int{}
	for _, m := range abs.members {
		counts[m.kind]++
		body, err := memberPage(root, abs, m, roots, byFQN)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", m.fqn, err)
		}
		pages = append(pages, page{path: fmt.Sprintf("%s/%s/%s.md", membersDir, m.kind, m.page), body: body})
	}
	for _, k := range kinds {
		pages = append(pages, page{path: fmt.Sprintf("%s/%s/_index.md", membersDir, k.dir), body: kindIndex(abs, k.dir)})
	}
	pages = append(pages, page{path: membersDir + "/_index.md", block: true, body: fmt.Sprintf(
		"Generated from %s version %s: %d blueprints, %d resources and %d traits.",
		code(abs.path), code(abs.version), counts[kindBlueprint], counts[kindResource], counts[kindTrait])})

	rawBody, err := rawTable(raw)
	if err != nil {
		return nil, err
	}
	pages = append(pages, page{path: rawPage, block: true, body: rawBody})
	sort.Slice(pages, func(i, j int) bool { return pages[i].path < pages[j].path })
	return pages, nil
}

// assignPages names each member's page after its metadata.name, adding the
// apiVersion when two members of one kind share a name.
func assignPages(mod *module) {
	n := map[string]int{}
	for _, m := range mod.members {
		n[m.kind+"/"+m.name]++
	}
	for _, m := range mod.members {
		m.page = m.name
		if n[m.kind+"/"+m.name] > 1 {
			m.page = m.name + "-" + m.apiVersion
		}
	}
	sort.SliceStable(mod.members, func(i, j int) bool {
		a, b := mod.members[i], mod.members[j]
		if a.kind != b.kind {
			return a.kind < b.kind
		}
		return a.page < b.page
	})
}

// title is the definition name without its kind suffix: the component
// wrapper a module author embeds (`#ScalingTrait` -> `Scaling`).
func title(m *member) string {
	t := strings.TrimPrefix(m.def.name, "#")
	for _, suf := range []string{"Resource", "Trait", "Blueprint"} {
		t = strings.TrimSuffix(t, suf)
	}
	return t
}

func memberURL(m *member) string {
	return fmt.Sprintf("%s%s/%s/", membersURL, m.kind, m.page)
}

func memberLink(m *member) string {
	return fmt.Sprintf("[%s](%s)", title(m), memberURL(m))
}

// links renders fqns as member links, or as code when no page exists.
func links(fqns []string, byFQN map[string]*member) string {
	var out []string
	for _, f := range fqns {
		if m, ok := byFQN[f]; ok {
			out = append(out, memberLink(m))
		} else {
			out = append(out, code(f))
		}
	}
	if len(out) == 0 {
		return "not declared"
	}
	return strings.Join(out, ", ")
}

var (
	alphaLevel = regexp.MustCompile(`^v[0-9]+alpha[0-9]+$`)
	betaLevel  = regexp.MustCompile(`^v[0-9]+beta[0-9]+$`)
)

func level(apiVersion string) string {
	switch {
	case alphaLevel.MatchString(apiVersion):
		return "alpha"
	case betaLevel.MatchString(apiVersion):
		return "beta"
	default:
		return "GA"
	}
}

// service is one transformer's demand on a member.
type service struct {
	t      *transformer
	demand string // required or optional
}

// servedBy lists the transformers of the member's own catalog that serve it.
func servedBy(mod *module, m *member) []service {
	var out []service
	for _, t := range mod.transformers {
		var req, opt []string
		switch m.kind {
		case kindResource:
			req, opt = t.reqRes, t.optRes
		case kindTrait:
			req, opt = t.reqTraits, t.optTraits
		case kindBlueprint:
			if blueprintSatisfies(m, t) {
				out = append(out, service{t: t, demand: "required"})
			}
			continue
		}
		switch {
		case contains(req, m.fqn):
			out = append(out, service{t: t, demand: "required"})
		case contains(opt, m.fqn):
			out = append(out, service{t: t, demand: "optional"})
		}
	}
	return out
}

// blueprintSatisfies reports whether a transformer requires only what the
// blueprint supplies: every required label answered by its matchLabels with
// the same value, and every required resource and trait composed by it. A
// transformer that requires nothing at all is never listed.
func blueprintSatisfies(m *member, t *transformer) bool {
	if len(t.reqLabels) == 0 && len(t.reqRes) == 0 && len(t.reqTraits) == 0 {
		return false
	}
	for _, rl := range t.reqLabels {
		ok := false
		for _, ml := range m.matchLabels {
			if ml.key == rl.key && ml.concrete != "" && ml.concrete == rl.concrete {
				ok = true
			}
		}
		if !ok {
			return false
		}
	}
	for _, r := range t.reqRes {
		if !contains(m.composedRes, r) {
			return false
		}
	}
	for _, r := range t.reqTraits {
		if !contains(m.composedTraits, r) {
			return false
		}
	}
	return true
}

func contains(xs []string, x string) bool {
	for _, y := range xs {
		if y == x {
			return true
		}
	}
	return false
}

// alert writes a GitHub alert with a bold title line.
func alert(b *strings.Builder, kind, heading, body string) {
	fmt.Fprintf(b, "> [!%s]\n> **%s**\n>\n> %s\n\n", kind, heading, body)
}

// mark returns the alert for a member no transformer in its catalog serves,
// or false when it is served or is a blueprint.
func mark(m *member, served []service) (kind, heading, body string, ok bool) {
	if len(served) > 0 || m.kind == kindBlueprint {
		return "", "", "", false
	}
	noun := strings.TrimSuffix(m.kind, "s")
	uses := "attaches it"
	if m.kind == kindResource {
		uses = "declares it"
	}
	var without string
	switch {
	case m.kind == kindTrait && *m.optionalDefault:
		without = fmt.Sprintf("a component that %s still renders, and the render warns that the trait is not handled and ignores its values", uses)
	default:
		without = fmt.Sprintf("rendering a component that %s fails", uses)
	}
	if m.fulfilment == "provider" {
		return "IMPORTANT", "Provided by your platform", fmt.Sprintf(
			"This catalog defines the contract and ships no transformer for it. Your platform needs exactly one catalog that implements it. Without one, %s; with two, the kernel refuses every render on that platform.",
			without), true
	}
	return "WARNING", "Not implemented", fmt.Sprintf(
		"This catalog defines the %s and ships no transformer that handles it. On a platform where no other catalog handles it, %s.",
		noun, without), true
}

// memberPage renders one member's page, in the fixed order: summary, at a
// glance, spec, notes, served by, enforcement. The example part is never
// written: no member carries one.
func memberPage(root string, mod *module, m *member, roots map[string]*member, byFQN map[string]*member) (string, error) {
	notes, err := splitDoc(m.doc, m.description)
	if err != nil {
		return "", fmt.Errorf("%s (%s): %w", m.def.name, m.def.filename, err)
	}
	spec, err := renderSpec(mod, m, roots)
	if err != nil {
		return "", err
	}
	served := servedBy(mod, m)
	noun := strings.TrimSuffix(m.kind, "s")

	var b strings.Builder
	fmt.Fprintf(&b, "---\ntitle: %s\ndescription: %s\ntype: reference\n---\n\n%s\n\n",
		yamlString(title(m)), yamlString(m.description), beginMarker)

	// Summary.
	fmt.Fprintf(&b, "%s.\n\n", mdText(m.description))

	// At a glance.
	b.WriteString("## At a glance\n\n")
	if k, h, body, ok := mark(m, served); ok {
		alert(&b, k, h, body)
	}
	b.WriteString("| Field | Value |\n| --- | --- |\n")
	row := func(k, v string) { fmt.Fprintf(&b, "| %s | %s |\n", k, cell(v)) }
	row("FQN", code(m.fqn))
	row("API version", fmt.Sprintf("%s, %s ([contract levels](%s))", code(m.apiVersion), level(m.apiVersion), contractURL))
	row("Module path", code(m.modulePath))
	row("Definition", fmt.Sprintf("%s in %s", code(m.def.name), code(m.def.filename)))
	if w, ok := m.def.pkg.defs["#"+title(m)]; ok && w != m.def {
		row("Component wrapper", code(w.name))
	}
	row("Catalog", fmt.Sprintf("%s version %s", code(mod.path), code(mod.version)))
	if m.category != "" {
		row("Category", code(m.category))
	}
	switch m.fulfilment {
	case "catalog":
		row("Fulfilment", code("catalog")+": the declaring catalog implements it")
	case "provider":
		row("Fulfilment", code("provider")+": a catalog on the platform implements it, never this one")
	}
	if m.kind == kindTrait {
		if *m.optionalDefault {
			row("Optional posture", "advisory: "+code("optional")+" defaults to "+code("true")+", so an unhandled trait warns and the render continues; a module may override it where it attaches the trait")
		} else {
			row("Optional posture", "load-bearing: "+code("optional")+" defaults to "+code("false")+", so an unhandled trait fails the render; a module may override it where it attaches the trait")
		}
		row("Applies to (declared)", links(m.appliesTo, byFQN))
	}
	if m.kind == kindBlueprint {
		row("Composed resources", links(m.composedRes, byFQN))
		row("Composed traits", links(m.composedTraits, byFQN))
	}
	for _, l := range m.matchLabels {
		v := code(fmt.Sprintf("%q: %s", l.key, l.value))
		if l.required {
			v = code(fmt.Sprintf("%q!: %s", l.key, l.value)) + " (required)"
		}
		row("Match label", v)
	}
	b.WriteString("\n")

	// Spec.
	b.WriteString("## Spec\n\n")
	fmt.Fprintf(&b, "A component writes this %s's fields under %s.\n\n", noun, code("spec."+m.specKey))
	fmt.Fprintf(&b, "```cue\n%s\n```\n\n", spec.code)
	if len(spec.linked)+len(spec.external) > 0 {
		b.WriteString("Defined elsewhere:\n\n")
		for _, r := range spec.linked {
			fmt.Fprintf(&b, "- %s: the spec of %s\n", code(r.display()), memberLink(r.owner))
		}
		for _, r := range spec.external {
			what := "from " + code(r.pkg)
			if strings.Contains(stripMajor(r.pkg), vendoredPrefix) {
				what += ", the vendored Kubernetes API types"
			}
			fmt.Fprintf(&b, "- %s: %s\n", code(r.display()), what)
		}
		b.WriteString("\n")
	}

	// Notes.
	if len(notes) > 0 {
		b.WriteString("## Notes\n\n")
		b.WriteString(notesMarkdown(root, notes))
		b.WriteString("\n\n")
	}

	// Served by.
	b.WriteString("## Served by\n\n")
	switch {
	case m.kind == kindBlueprint && len(served) > 0:
		fmt.Fprintf(&b, "These transformers in %s require only what this blueprint supplies: its match labels answer their required labels, and it composes every resource and trait they require.\n\n", code(mod.path))
		b.WriteString("| Transformer | What it does |\n| --- | --- |\n")
		for _, s := range served {
			fmt.Fprintf(&b, "| %s | %s |\n", code(s.t.name), cell(mdText(s.t.description)))
		}
		b.WriteString("\n")
	case m.kind == kindBlueprint:
		fmt.Fprintf(&b, "No transformer in %s requires only what this blueprint supplies.\n\n", code(mod.path))
	case len(served) > 0:
		fmt.Fprintf(&b, "These transformers in %s version %s require this %s or read it when present.\n\n", code(mod.path), code(mod.version), noun)
		b.WriteString("| Transformer | Demand | What it does |\n| --- | --- | --- |\n")
		for _, s := range served {
			fmt.Fprintf(&b, "| %s | %s | %s |\n", code(s.t.name), s.demand, cell(mdText(s.t.description)))
		}
		b.WriteString("\n")
	default:
		fmt.Fprintf(&b, "No transformer in %s requires this %s or reads it.\n\n", code(mod.path), noun)
	}

	// Enforcement.
	b.WriteString("## Enforcement\n\n")
	fmt.Fprintf(&b, "Each rule names what refuses a violation ([What enforces a rule](%s)).\n\n", enforcementURL)
	b.WriteString("| Rule | Enforced by |\n| --- | --- |\n")
	erow := func(rule, by string) { fmt.Fprintf(&b, "| %s | %s |\n", cell(rule), by) }
	erow(fmt.Sprintf("A value under %s satisfies the schema in Spec, or it does not evaluate.", code("spec."+m.specKey)), code("cue"))
	for _, l := range m.matchLabels {
		if l.required {
			erow(fmt.Sprintf("A component carrying this %s answers its required match label %s.", noun, code(l.key)), code("cue"))
		}
	}
	if m.fulfilment == "provider" {
		erow(fmt.Sprintf("A platform carries exactly one catalog whose transformers require this contract; with two, every render on that platform is refused ([0010:D32](%s)).", decisionsURL), code("kernel"))
	}
	if m.kind == kindTrait && !*m.optionalDefault {
		erow(fmt.Sprintf("When no transformer matched to the component handles this trait, the render is refused, unless the attachment sets %s ([0010:D28](%s)).", code("optional: true"), decisionsURL), code("kernel"))
	}
	b.WriteString("\n")
	b.WriteString(endMarker + "\n")
	return b.String(), nil
}

// kindIndex renders a kind's section page.
func kindIndex(mod *module, dir string) string {
	var k = kinds[0]
	for _, c := range kinds {
		if c.dir == dir {
			k = c
		}
	}
	var ms []*member
	for _, m := range mod.members {
		if m.kind == dir {
			ms = append(ms, m)
		}
	}
	var b strings.Builder
	fmt.Fprintf(&b, "---\ntitle: %s\ndescription: %s\nweight: %d\n---\n\n%s\n\n",
		yamlString(k.title),
		yamlString(fmt.Sprintf("The %d %s of the abstraction catalog, one generated page each.", len(ms), strings.ToLower(k.title))),
		k.weight, beginMarker)
	fmt.Fprintf(&b, "%s Generated from %s version %s.\n\n", k.what, code(mod.path), code(mod.version))

	var notImpl, provided []string
	for _, m := range ms {
		if _, h, _, ok := mark(m, servedBy(mod, m)); ok {
			if h == "Not implemented" {
				notImpl = append(notImpl, memberLink(m))
			} else {
				provided = append(provided, memberLink(m))
			}
		}
	}
	if len(notImpl) > 0 {
		fmt.Fprintf(&b, "No transformer in this catalog handles these %s, so they are marked **Not implemented**: %s.\n\n", strings.ToLower(k.title), strings.Join(notImpl, ", "))
	}
	if len(provided) > 0 {
		fmt.Fprintf(&b, "These %s are provider-fulfilled, so they are marked **Provided by your platform**: %s. Your platform needs exactly one catalog that implements each.\n\n", strings.ToLower(k.title), strings.Join(provided, ", "))
	}
	b.WriteString(endMarker + "\n")
	return b.String()
}

// rawTable renders the raw Kubernetes family's table.
func rawTable(mod *module) (string, error) {
	var b strings.Builder
	n := 0
	for _, m := range mod.members {
		if m.kind == kindResource {
			n++
		}
	}
	fmt.Fprintf(&b, "Generated from %s version %s: %d resources, each served by the transformer named beside it.\n\n", code(mod.path), code(mod.version), n)
	b.WriteString("| Resource | FQN | Description | Served by |\n| --- | --- | --- | --- |\n")
	ms := append([]*member(nil), mod.members...)
	sort.Slice(ms, func(i, j int) bool {
		a, b := strings.ToLower(title(ms[i])), strings.ToLower(title(ms[j]))
		if a != b {
			return a < b
		}
		return ms[i].fqn < ms[j].fqn
	})
	for _, m := range ms {
		if m.kind != kindResource {
			return "", fmt.Errorf("%s: the raw catalog lists a %s; the table holds only resources", m.fqn, strings.TrimSuffix(m.kind, "s"))
		}
		if _, err := splitDoc(m.doc, m.description); err != nil {
			return "", fmt.Errorf("%s (%s): %w", m.def.name, m.def.filename, err)
		}
		var by []string
		for _, s := range servedBy(mod, m) {
			by = append(by, fmt.Sprintf("%s (%s)", code(s.t.name), s.demand))
		}
		servedText := strings.Join(by, ", ")
		if servedText == "" {
			servedText = "none, **Not implemented**"
			if m.fulfilment == "provider" {
				servedText = "none, **Provided by your platform**"
			}
		}
		fmt.Fprintf(&b, "| %s | %s | %s | %s |\n", title(m), cell(code(m.fqn)), cell(mdText(m.description)), cell(servedText))
	}
	return b.String(), nil
}
