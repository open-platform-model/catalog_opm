package main

import (
	"regexp"
	"strings"
	"unicode/utf8"
)

// Comments in the catalogs cite enhancement decisions for contributors
// ("0010 D28", "0019:D22"), which a reader of the site cannot resolve. The
// rules below remove them from every published text, the notes and the
// comments inside a spec block, the way core's reference generator does.
// The catalog sources use both the "0010:D28" form and the older "0010 D28".

const cite = `\d{4}[: ](?:D|OQ)\d+(?::R\d+(?:/R\d+)*)?(?:/(?:D|OQ)?\d+(?::R\d+(?:/R\d+)*)?)*`

var (
	citeList = cite + `(?:\s*(?:[,;]|and)\s*(?:` + cite + `|D\d+))*`
	// A parenthetical that holds nothing but a citation, with an optional
	// lead-in word.
	reCiteParen = regexp.MustCompile(`\s*\((?:(?:see|per|enhancement)\s+)?` + citeList + `\)`)
	// A citation inside running text, with the comma or lead-in before it.
	reCiteInline = regexp.MustCompile(`(?:[,;]\s*)?(?:(?:per|enhancement)\s+)?` + citeList)
	reCiteAny    = regexp.MustCompile(cite)
	// Clean-up after a removal.
	reEmptyParen  = regexp.MustCompile(`\(\s*[,;]?\s*\)`)
	reSpaceBefore = regexp.MustCompile(`\s+([,.;:)])`)
	reSpaceAfter  = regexp.MustCompile(`\(\s+`)
	reCommaParen  = regexp.MustCompile(`[,;]\s*\)`)
	reParenComma  = regexp.MustCompile(`\(\s*[,;]\s*`)
	reSpaces      = regexp.MustCompile(`[ \t]{2,}`)
	reCommentLine = regexp.MustCompile(`^(\s*)//(.*)$`)
)

// stripCitations removes decision citations from one paragraph of prose
// (lines already joined with single spaces).
func stripCitations(s string) string {
	if !reCiteAny.MatchString(s) {
		return s
	}
	s = reCiteParen.ReplaceAllString(s, "")
	s = reCiteInline.ReplaceAllString(s, "")
	s = reEmptyParen.ReplaceAllString(s, "")
	s = reCommaParen.ReplaceAllString(s, ")")
	s = reParenComma.ReplaceAllString(s, "(")
	s = reSpaceAfter.ReplaceAllString(s, "(")
	s = reSpaceBefore.ReplaceAllString(s, "$1")
	s = reSpaces.ReplaceAllString(s, " ")
	return strings.TrimSpace(s)
}

// stripCodeCitations removes decision citations from the comments of a
// formatted CUE block. A comment paragraph (a run of `//` lines at one
// indent, up to a blank `//` line) the rules leave unchanged keeps its line
// breaks; a changed one is re-wrapped. A trailing comment after code is
// cleaned in place.
func stripCodeCitations(code string) string {
	lines := strings.Split(code, "\n")
	var out []string
	var run []string // texts of the current comment paragraph
	indent := ""
	flush := func() {
		if len(run) == 0 {
			return
		}
		joined := strings.Join(trimAll(run), " ")
		c := stripCitations(joined)
		switch {
		case c == joined:
			for _, t := range run {
				out = append(out, commentLine(indent, t))
			}
		case c != "":
			width := 80 - utf8.RuneCountInString(strings.ReplaceAll(indent, "\t", "    ")) - 3
			if width < 40 {
				width = 40
			}
			for _, w := range wrap(c, width) {
				out = append(out, commentLine(indent, w))
			}
		}
		run = nil
	}
	for _, l := range lines {
		m := reCommentLine.FindStringSubmatch(l)
		if m == nil {
			flush()
			if i := strings.Index(l, " // "); i >= 0 && reCiteAny.MatchString(l[i:]) {
				if c := stripCitations(l[i+4:]); c != "" {
					l = l[:i] + " // " + c
				} else {
					l = l[:i]
				}
			}
			out = append(out, l)
			continue
		}
		text := strings.TrimPrefix(m[2], " ")
		if m[1] != indent || strings.TrimSpace(text) == "" {
			flush()
		}
		indent = m[1]
		if strings.TrimSpace(text) == "" {
			out = append(out, commentLine(indent, ""))
			continue
		}
		run = append(run, text)
	}
	flush()
	return strings.Join(out, "\n")
}

func commentLine(indent, text string) string {
	if text == "" {
		return indent + "//"
	}
	return indent + "// " + text
}

func trimAll(ls []string) []string {
	out := make([]string, len(ls))
	for i, l := range ls {
		out[i] = strings.TrimSpace(l)
	}
	return out
}

// wrap breaks s into lines of at most width runes, at spaces.
func wrap(s string, width int) []string {
	var out []string
	line := ""
	for _, w := range strings.Fields(s) {
		if line != "" && utf8.RuneCountInString(line)+1+utf8.RuneCountInString(w) > width {
			out = append(out, line)
			line = w
			continue
		}
		if line == "" {
			line = w
		} else {
			line += " " + w
		}
	}
	if line != "" {
		out = append(out, line)
	}
	return out
}
