package main

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"

	"cuelang.org/go/cue"
	"cuelang.org/go/cue/cuecontext"
	"cuelang.org/go/cue/load"
	"cuelang.org/go/mod/modconfig"
	"cuelang.org/go/mod/modfile"
	"cuelang.org/go/mod/module"
)

// k8sModule is the dependency the table is generated from, with its major.
const k8sModule = "cue.dev/x/k8s.io@v0"

// def is one x/k8s.io definition that is a kind.
type def struct {
	importPath string // cue.dev/x/k8s.io/api/apps/v1
	name       string // #Deployment
}

// loadKinds returns the x/k8s.io version opm pins and every definition in it
// whose apiVersion and kind are concrete and whose kind does not end in List.
func loadKinds(ctx context.Context, opmDir string) (string, map[gvk]def, error) {
	modPath := filepath.Join(opmDir, "cue.mod", "module.cue")
	data, err := os.ReadFile(modPath)
	if err != nil {
		return "", nil, err
	}
	mf, err := modfile.Parse(data, modPath)
	if err != nil {
		return "", nil, err
	}
	dep, ok := mf.Deps[k8sModule]
	if !ok {
		return "", nil, fmt.Errorf("%s does not depend on %s", modPath, k8sModule)
	}

	pkgs, err := packages(ctx, dep.Version)
	if err != nil {
		return "", nil, err
	}
	// Loaded through the opm module, so the imports resolve to its pin.
	insts := load.Instances(pkgs, &load.Config{Dir: opmDir})
	cctx := cuecontext.New()
	defs := map[gvk]def{}
	for _, inst := range insts {
		if inst.Err != nil {
			return "", nil, fmt.Errorf("loading %s: %w", inst.ImportPath, inst.Err)
		}
		v := cctx.BuildInstance(inst)
		if err := v.Err(); err != nil {
			return "", nil, fmt.Errorf("evaluating %s: %w", inst.ImportPath, err)
		}
		it, err := v.Fields(cue.Definitions(true))
		if err != nil {
			return "", nil, fmt.Errorf("%s: %w", inst.ImportPath, err)
		}
		for it.Next() {
			if !it.Selector().IsDefinition() {
				continue
			}
			av, err1 := it.Value().LookupPath(cue.ParsePath("apiVersion")).String()
			kind, err2 := it.Value().LookupPath(cue.ParsePath("kind")).String()
			if err1 != nil || err2 != nil || strings.HasSuffix(kind, "List") {
				continue
			}
			k := gvk{apiVersion: av, kind: kind}
			d := def{importPath: inst.ImportPath, name: it.Selector().String()}
			if prev, dup := defs[k]; dup {
				return "", nil, fmt.Errorf("%s %s is defined twice: %s.%s and %s.%s",
					av, kind, prev.importPath, prev.name, d.importPath, d.name)
			}
			defs[k] = d
		}
	}
	return dep.Version, defs, nil
}

// packages lists the import path of every package in x/k8s.io at version,
// fetched through the CUE registry ($CUE_REGISTRY, cached like `cue` does).
// CUE cannot expand "..." in an external import path, so the module's tree
// is walked instead.
func packages(ctx context.Context, version string) ([]string, error) {
	reg, err := modconfig.NewRegistry(nil)
	if err != nil {
		return nil, err
	}
	mv, err := module.NewVersion(k8sModule, version)
	if err != nil {
		return nil, err
	}
	loc, err := reg.Fetch(ctx, mv)
	if err != nil {
		return nil, fmt.Errorf("fetching %s: %w", mv, err)
	}
	base := strings.SplitN(k8sModule, "@", 2)[0]
	seen := map[string]bool{}
	err = fs.WalkDir(loc.FS, loc.Dir, func(p string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() && d.Name() == "cue.mod" {
			return fs.SkipDir
		}
		if d.IsDir() || !strings.HasSuffix(p, ".cue") {
			return nil
		}
		rel := strings.TrimPrefix(strings.TrimPrefix(path.Dir(p), loc.Dir), "/")
		if rel != "" && rel != "." {
			seen[base+"/"+rel] = true
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	out := make([]string, 0, len(seen))
	for p := range seen {
		out = append(out, p)
	}
	sort.Strings(out)
	return out, nil
}
