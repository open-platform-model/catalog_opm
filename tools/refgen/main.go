// Command refgen generates the catalog reference pages under
// docs/site/reference/ from the catalog module of this repository.
//
// It loads src/ the way `cue vet` does, evaluates the four catalog maps
// (#resources, #traits, #blueprints and #transformers) and reads each
// member's doc comment and spec schema from the source. Every fact on a page
// is computed from the catalog; nothing is transcribed by hand (workspace
// STYLE.md, "Site Pages").
//
// What it derives:
//
//   - The summary is the member's metadata.description, which MUST open the
//     member's doc comment (followed by a period); the rest of the doc comment
//     is the notes. A member that breaks this is refused. The summary is the
//     page's front-matter description, which the site shows as the lead, so
//     the body does not repeat it.
//   - Decision citations ("0010 D28", "0019:D22") are stripped from the notes
//     and from the comments in a spec block: a reader cannot resolve them.
//   - The spec is the authored `spec:` field and every definition it
//     references in the same module, transitively, printed with cue/format.
//     Another member's own spec schema is linked rather than repeated, and
//     anything outside the module (core, the vendored Kubernetes types) is
//     named rather than expanded.
//   - Served by lists the transformers of the same catalog that require or
//     optionally read the member. A blueprint, which no transformer can
//     demand, lists the transformers that require only what it supplies.
//   - A member no transformer in its own catalog serves is marked
//     "Not implemented" (fulfilment "catalog") or "Provided by your platform"
//     (fulfilment "provider").
//   - Enforcement rows are tagged only where the source proves the enforcer:
//     the spec schema and required match labels by CUE; a provider-fulfilled
//     contract's single provider (0010:D32) and the refused render of a
//     load-bearing trait (0010:D28) by the kernel.
//
// What it does not derive: examples (no member carries one).
//
// Usage, from anywhere:
//
//	go run -C tools/refgen . -repo <repo root>          # write the pages
//	go run -C tools/refgen . -repo <repo root> -check   # fail when stale
package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	repo := flag.String("repo", "", "path to the catalog_opm repository root (required)")
	check := flag.Bool("check", false, "compare the generated pages with the committed ones and fail when any differs")
	flag.Parse()
	if *repo == "" {
		fmt.Fprintln(os.Stderr, "refgen: -repo is required")
		os.Exit(2)
	}
	root, err := filepath.Abs(*repo)
	if err != nil {
		fatal(err)
	}
	if err := run(root, *check); err != nil {
		fatal(err)
	}
}

func fatal(err error) {
	fmt.Fprintf(os.Stderr, "refgen: %v\n", err)
	os.Exit(1)
}

// run loads the catalog, renders every page and either writes them or
// compares them with what is committed.
func run(root string, check bool) error {
	abs, err := loadModule(root, "src")
	if err != nil {
		return err
	}
	pages, err := renderSite(root, abs)
	if err != nil {
		return err
	}
	if check {
		return checkPages(root, pages)
	}
	return writePages(root, pages)
}
