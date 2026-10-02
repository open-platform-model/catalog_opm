package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// generatedDirs are owned by the generator: a page in one of them that the
// catalogs no longer produce is stale.
func generatedDirs() []string {
	var out []string
	for _, k := range kinds {
		out = append(out, membersDir+"/"+k.dir)
	}
	return out
}

// content returns what a page's file must hold: the generated file itself,
// or the existing authored file with its marked block replaced.
func content(root string, p page) (string, error) {
	if !p.block {
		return p.body, nil
	}
	old, err := os.ReadFile(filepath.Join(root, p.path))
	if err != nil {
		return "", fmt.Errorf("%s: %w (an authored page needs its marker comments)", p.path, err)
	}
	return splice(string(old), p.body, p.path)
}

// splice replaces the text between the marker lines with body.
func splice(old, body, name string) (string, error) {
	lines := strings.Split(old, "\n")
	begin, end := -1, -1
	for i, l := range lines {
		switch strings.TrimSpace(l) {
		case beginMarker:
			if begin >= 0 {
				return "", fmt.Errorf("%s: more than one begin marker", name)
			}
			begin = i
		case endMarker:
			if end >= 0 {
				return "", fmt.Errorf("%s: more than one end marker", name)
			}
			end = i
		}
	}
	if begin < 0 || end < begin {
		return "", fmt.Errorf("%s: needs the lines\n  %s\n  %s\nin that order", name, beginMarker, endMarker)
	}
	out := append([]string{}, lines[:begin+1]...)
	out = append(out, "", strings.TrimRight(body, "\n"), "")
	out = append(out, lines[end:]...)
	return strings.Join(out, "\n"), nil
}

// orphans lists the pages in the generated directories that no output names.
func orphans(root string, pages []page) ([]string, error) {
	want := map[string]bool{}
	for _, p := range pages {
		want[p.path] = true
	}
	var out []string
	for _, d := range generatedDirs() {
		err := filepath.WalkDir(filepath.Join(root, d), func(path string, e fs.DirEntry, err error) error {
			if errors.Is(err, fs.ErrNotExist) {
				return nil
			}
			if err != nil {
				return err
			}
			if e.IsDir() {
				return nil
			}
			rel, err := filepath.Rel(root, path)
			if err != nil {
				return err
			}
			if rel = filepath.ToSlash(rel); !want[rel] {
				out = append(out, rel)
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	sort.Strings(out)
	return out, nil
}

// writePages writes every page and removes orphans.
func writePages(root string, pages []page) error {
	for _, p := range pages {
		c, err := content(root, p)
		if err != nil {
			return err
		}
		path := filepath.Join(root, p.path)
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(path, []byte(c), 0o644); err != nil {
			return err
		}
	}
	gone, err := orphans(root, pages)
	if err != nil {
		return err
	}
	for _, o := range gone {
		if err := os.Remove(filepath.Join(root, o)); err != nil {
			return err
		}
		fmt.Printf("removed %s\n", o)
	}
	fmt.Printf("refgen: wrote %d pages\n", len(pages))
	return nil
}

// checkPages fails when any page differs from what the catalogs produce, or
// a generated directory holds a page they no longer produce.
func checkPages(root string, pages []page) error {
	var stale []string
	for _, p := range pages {
		want, err := content(root, p)
		if err != nil {
			return err
		}
		have, err := os.ReadFile(filepath.Join(root, p.path))
		if err != nil || string(have) != want {
			stale = append(stale, p.path)
		}
	}
	gone, err := orphans(root, pages)
	if err != nil {
		return err
	}
	for _, o := range gone {
		stale = append(stale, o+" (no longer generated)")
	}
	if len(stale) > 0 {
		return fmt.Errorf("the catalog reference is stale; run task generate:reference:\n  %s", strings.Join(stale, "\n  "))
	}
	fmt.Printf("refgen: OK, %d pages up to date\n", len(pages))
	return nil
}
