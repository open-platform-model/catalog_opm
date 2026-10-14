# Doc comments and descriptions

Covers how to write a doc comment, a `// WHY` block and a `metadata.description` so that the published catalog reference and `src/INDEX.md` come out right. Publishing the docs bundles is in a separate file.

## Doc comments

- Every `//` block that ends on the line directly above a field or definition is that declaration's doc comment. `cue lsp` hover, `Value.Doc()`, `cue def` and `task generate:index` replay it verbatim. One blank line ends the block, and `cue fmt` keeps that blank line.
- Tier 1, the doc comment, at most 6 lines: the contract an author needs, in this order until 6 lines are used: what it is, what it renders, what a value must satisfy, then an optional `See docs/<note>.md`.
- Tier 2, a `// WHY ...` block above the doc comment, separated from it by one blank line: rationale that must stay next to the code (measured evaluator behaviour, rendering decisions, history). The block goes above, never below the field. The blank line is load-bearing; the `WHY` prefix marks it so nobody closes the gap.
- Tier 3, `docs/<note>.md` or the enhancement entry: the full argument.
- `task docs:check` fails on every doc comment over 6 lines in the module. `.tasks/doc-check.sh` is kept byte-identical with `core`'s copy; `task docs:lint` at the workspace root checks it. `_test*` fixture fields (in `@if(fixtures)` files) are exempt; other hidden fields are not. `package` docs, `let` and comprehension clauses are not counted.
- A comment never cites an enhancement as a decision number or a lone id. `task cite-lint` checks it.
- Every comment that is not a `// WHY` block or a `////` banner is published, inside the spec block or as notes. It states what the member does today. Maintainer history goes in a `// WHY` block. A published comment never points at a WHY block, because the block is not on the page. Decision citations are stripped from the page; a link to the enhancement is the renderer's, never the comment's.
- A page states only what the source proves. Marks (**Not implemented**, **Provided by your platform**) and enforcement tags are derived, never authored (workspace `STYLE.md`, "Site Pages").
- `opm-docs build` enforces the rules (docs-kit `docs/contracts.md`, "Doc-comment rules"): a member's doc comment must open with its description, or the build refuses it. A doc-comment change reaches `edge` on the next push to `main`, and a released minor through a docs revision.

## Descriptions

- Every member of the four catalog maps carries a non-blank `metadata.description`. For a resource, trait or blueprint it is the first sentence of the member's doc comment, word for word without the closing period.
- It is the member's one-line summary in the published catalog reference (workspace `STYLE.md`, "Site Pages"). It says what the member is or does, not that it is "a trait to specify" something, and never claims behaviour no transformer has.
- `task vet:descriptions` refuses a missing or blank one. `metadata.description` is on the compatibility gate's provenance denylist (enhancement 0010, provenance is excluded by a Go-side operand filter), so rewording one is never a contract change.
- `src/INDEX.md` takes the doc comment's first sentence, up to the first period, as the member's description. Its title comes from the module path, never the directory name, because it ships in the module.

## Pitfalls

- Pointing a published comment at a `// WHY` block: the block is not on the page.
- A blank line between a doc comment and its field: the comment stops being the doc comment.
- Writing a mark such as **Not implemented** by hand: it is derived.

## Check before you finish

- [ ] `task docs:check` passes.
- [ ] A new member's `metadata.description` equals the first sentence of its doc comment.
- [ ] `task generate:index` was run and its output reviewed.
- [ ] No comment holds a decision number or a lone enhancement id.
