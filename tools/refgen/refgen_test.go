package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestSplitDoc(t *testing.T) {
	cases := []struct {
		name, doc, desc string
		want            []string
		wantErr         string
	}{
		{name: "description only", doc: "A thing.", desc: "A thing"},
		{name: "rest of the paragraph and later paragraphs", doc: "A thing. It renders\nan object.\n\nSecond paragraph.", desc: "A thing",
			want: []string{"It renders an object.", "Second paragraph."}},
		{name: "wrapped first sentence", doc: "A long\nthing. More.", desc: "A long thing", want: []string{"More."}},
		{name: "no doc comment", doc: "", desc: "A thing", wantErr: "no doc comment"},
		{name: "disagreeing doc comment", doc: "Another thing.", desc: "A thing", wantErr: "must open with the description"},
		{name: "description without its period", doc: "A thing, and more.", desc: "A thing", wantErr: "must open with the description"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got, err := splitDoc(c.doc, c.desc)
			if c.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), c.wantErr) {
					t.Fatalf("err = %v, want one containing %q", err, c.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if strings.Join(got, "|") != strings.Join(c.want, "|") {
				t.Fatalf("got %q, want %q", got, c.want)
			}
		})
	}
}

func TestMdText(t *testing.T) {
	cases := map[string]string{
		"pods are <sts>-<n>.<svc>":      `pods are \<sts\>-\<n\>.\<svc\>`,
		"keep `a_b|<c>` as code":        "keep `a_b|<c>` as code",
		"no {{< opm/x >}} shortcode":    `no {\{\< opm/x \>}} shortcode`,
		"a [link](x) and *stars* and |": `a \[link\](x) and \*stars\* and \|`,
	}
	for in, want := range cases {
		if got := mdText(in); got != want {
			t.Errorf("mdText(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestCodeAndCell(t *testing.T) {
	if got := code("a`b"); got != "``a`b``" {
		t.Errorf("code = %q", got)
	}
	if got := cell(code(`"a" | "b"`)); got != "`\"a\" \\| \"b\"`" {
		t.Errorf("cell = %q", got)
	}
	if got := yamlString(`say "hi" \o/`); got != `"say \"hi\" \\o/"` {
		t.Errorf("yamlString = %q", got)
	}
}

func TestSplice(t *testing.T) {
	old := "intro\n\n" + beginMarker + "\nold block\n" + endMarker + "\n\n## See also\n"
	got, err := splice(old, "new block\n", "page.md")
	if err != nil {
		t.Fatal(err)
	}
	want := "intro\n\n" + beginMarker + "\n\nnew block\n\n" + endMarker + "\n\n## See also\n"
	if got != want {
		t.Fatalf("got %q, want %q", got, want)
	}
	if _, err := splice("no markers\n", "x", "page.md"); err == nil {
		t.Fatal("splice without markers succeeded")
	}
	if _, err := splice(endMarker+"\n"+beginMarker+"\n", "x", "page.md"); err == nil {
		t.Fatal("splice with markers out of order succeeded")
	}
}

func TestLevel(t *testing.T) {
	for in, want := range map[string]string{"v1alpha1": "alpha", "v2beta3": "beta", "v1": "GA"} {
		if got := level(in); got != want {
			t.Errorf("level(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestBlueprintSatisfies(t *testing.T) {
	bp := &member{
		kind:        kindBlueprint,
		matchLabels: []label{{key: "workload-type", concrete: "stateless"}},
		composedRes: []string{"res/container"}, composedTraits: []string{"traits/scaling"},
	}
	cases := []struct {
		name string
		t    *transformer
		want bool
	}{
		{"label and resource", &transformer{reqLabels: []label{{key: "workload-type", concrete: "stateless"}}, reqRes: []string{"res/container"}}, true},
		{"composed trait", &transformer{reqRes: []string{"res/container"}, reqTraits: []string{"traits/scaling"}}, true},
		{"other label value", &transformer{reqLabels: []label{{key: "workload-type", concrete: "stateful"}}, reqRes: []string{"res/container"}}, false},
		{"trait not composed", &transformer{reqRes: []string{"res/container"}, reqTraits: []string{"traits/expose"}}, false},
		{"requires nothing", &transformer{}, false},
	}
	for _, c := range cases {
		if got := blueprintSatisfies(bp, c.t); got != c.want {
			t.Errorf("%s: got %v, want %v", c.name, got, c.want)
		}
	}
}

func TestMark(t *testing.T) {
	yes, no := true, false
	served := []service{{t: &transformer{name: "x"}, demand: "required"}}
	cases := []struct {
		name    string
		m       *member
		served  []service
		heading string
		says    string
	}{
		{"served", &member{kind: kindTrait, fulfilment: "catalog", optionalDefault: &yes}, served, "", ""},
		{"blueprint", &member{kind: kindBlueprint}, nil, "", ""},
		{"advisory catalog trait", &member{kind: kindTrait, fulfilment: "catalog", optionalDefault: &yes}, nil, "Not implemented", "still renders"},
		{"load-bearing provider trait", &member{kind: kindTrait, fulfilment: "provider", optionalDefault: &no}, nil, "Provided by your platform", "attaches it fails"},
		{"advisory provider trait", &member{kind: kindTrait, fulfilment: "provider", optionalDefault: &yes}, nil, "Provided by your platform", "still renders"},
		{"provider resource", &member{kind: kindResource, fulfilment: "provider"}, nil, "Provided by your platform", "declares it fails"},
	}
	for _, c := range cases {
		_, h, body, ok := mark(c.m, c.served)
		if h != c.heading || ok != (c.heading != "") || !strings.Contains(body, c.says) {
			t.Errorf("%s: got %q %v %q", c.name, h, ok, body)
		}
	}
}

func TestStripCitations(t *testing.T) {
	cases := map[string]string{
		"failing the render loudly (0010 D28) beats it":            "failing the render loudly beats it",
		"refuses it structurally (0015 D10), so nothing is gated": "refuses it structurally, so nothing is gated",
		"with no fallback (0019:D22). Required.":                   "with no fallback. Required.",
		"per 0010:D4:R2 and 0010:D49 the key moves":                "the key moves",
		"no citation here (see docs/x.md)":                         "no citation here (see docs/x.md)",
	}
	for in, want := range cases {
		if got := stripCitations(in); got != want {
			t.Errorf("stripCitations(%q) = %q, want %q", in, got, want)
		}
	}
	code := "spec: x: #S\n\n#S: {\n\t// The name, with no fallback (0019\n\t// D22). Required.\n\tname!: string // Example: \"a\" (0010:D4)\n\t// Untouched\n\t//   indented example\n\tother?: int\n}"
	want := "spec: x: #S\n\n#S: {\n\t// The name, with no fallback. Required.\n\tname!: string // Example: \"a\"\n\t// Untouched\n\t//   indented example\n\tother?: int\n}"
	if got := stripCodeCitations(code); got != want {
		t.Errorf("stripCodeCitations:\n%s\nwant:\n%s", got, want)
	}
}

func TestOrphansNamesARetiredPage(t *testing.T) {
	root := t.TempDir()
	if got, err := orphans(root, nil); err != nil || len(got) != 0 {
		t.Fatalf("empty tree: got %v, %v; want none", got, err)
	}
	retired := filepath.Join(root, retiredPages[0])
	if err := os.MkdirAll(filepath.Dir(retired), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(retired, []byte("back\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := orphans(root, nil)
	if err != nil || len(got) != 1 || got[0] != retiredPages[0] {
		t.Fatalf("got %v, %v; want [%s]", got, err, retiredPages[0])
	}
}
