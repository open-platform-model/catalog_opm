// Command kindgen generates src/schemas/kinds/table.cue, the table the
// objects resource dispatches on: every built-in Kubernetes kind, keyed by
// apiVersion then kind, with its closed cue.dev/x/k8s.io definition and its
// scope.
//
// It joins two inputs:
//
//   - Schemas: every package of the cue.dev/x/k8s.io version that
//     src/cue.mod/module.cue pins, loaded through that module the way
//     `cue vet` loads it. A definition whose apiVersion and kind are concrete,
//     and whose kind does not end in List, is a kind.
//   - Scope: the OpenAPI spec (api/openapi-spec/swagger.json) of the
//     Kubernetes tag that x/k8s.io version is generated from. A kind served
//     under a /namespaces/{namespace}/ path is Namespaced, otherwise Cluster
//     (see scopes).
//
// The table is the union of both: a kind in the spec with no definition
// carries only its scope, and a definition the spec does not serve carries
// only its schema. x/k8s.io does not record its Kubernetes tag, so the
// caller names it; a wrong tag shows up as long lists in the summary this
// command prints.
//
// Usage, from anywhere:
//
//	go run -C tools/kindgen . -repo <repo root> -kubernetes v1.36.0
//	go run -C tools/kindgen . -repo <repo root> -kubernetes v1.36.0 -swagger swagger.json
package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"
)

func main() {
	repo := flag.String("repo", "", "path to the catalog_opm repository root (required)")
	tag := flag.String("kubernetes", "", "Kubernetes release tag the pinned cue.dev/x/k8s.io tracks, e.g. v1.36.0 (required)")
	swagger := flag.String("swagger", "", "local copy of that tag's api/openapi-spec/swagger.json (default: download it)")
	flag.Parse()
	if *repo == "" || *tag == "" {
		fmt.Fprintln(os.Stderr, "kindgen: -repo and -kubernetes are required")
		os.Exit(2)
	}
	if err := run(*repo, *tag, *swagger); err != nil {
		fmt.Fprintln(os.Stderr, "kindgen:", err)
		os.Exit(1)
	}
}

func run(repo, tag, swaggerPath string) error {
	root, err := filepath.Abs(repo)
	if err != nil {
		return err
	}
	opmDir := filepath.Join(root, "src")
	ctx := context.Background()

	spec, err := readSpec(ctx, tag, swaggerPath)
	if err != nil {
		return err
	}
	scope, err := scopes(spec)
	if err != nil {
		return fmt.Errorf("Kubernetes %s spec: %w", tag, err)
	}
	version, defs, err := loadKinds(ctx, opmDir)
	if err != nil {
		return err
	}

	t := join(defs, scope)
	src, err := render(t, version, tag)
	if err != nil {
		return err
	}
	out := filepath.Join(opmDir, "schemas", "kinds", "table.cue")
	if err := os.MkdirAll(filepath.Dir(out), 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(out, src, 0o644); err != nil {
		return err
	}
	summarize(os.Stderr, t, version, tag)
	return nil
}

// readSpec returns the swagger.json of tag, from path when it is set.
func readSpec(ctx context.Context, tag, path string) ([]byte, error) {
	if path != "" {
		return os.ReadFile(path)
	}
	url := "https://raw.githubusercontent.com/kubernetes/kubernetes/" + tag + "/api/openapi-spec/swagger.json"
	ctx, cancel := context.WithTimeout(ctx, 2*time.Minute)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("downloading %s: %w", url, err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("downloading %s: %s", url, resp.Status)
	}
	return io.ReadAll(resp.Body)
}

// summarize prints the table's size and both one-sided sets, the evidence
// that the -kubernetes tag matches the pinned x/k8s.io.
func summarize(w io.Writer, t []entry, version, tag string) {
	var scoped, noScope, noSchema []string
	gvs := map[string]bool{}
	for _, e := range t {
		gvs[e.apiVersion] = true
		if e.scope != "" {
			scoped = append(scoped, e.key())
		} else {
			noScope = append(noScope, e.key())
		}
		if e.schema == nil {
			noSchema = append(noSchema, e.key())
		}
	}
	fmt.Fprintf(w, "kindgen: %d kinds over %d group-versions, %d with a scope (x/k8s.io %s, Kubernetes %s)\n",
		len(t), len(gvs), len(scoped), version, tag)
	fmt.Fprintf(w, "kindgen: schema but no scope in the spec (%d): %v\n", len(noScope), noScope)
	fmt.Fprintf(w, "kindgen: scope but no x/k8s.io definition (%d): %v\n", len(noSchema), noSchema)
}
