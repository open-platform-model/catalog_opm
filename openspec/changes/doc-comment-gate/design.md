## Context

See proposal.md for motivation. The mechanism is a parser fact verified against cue v0.17.1 (`cue/parser/parser.go`, `next()`): a comment group is `Doc` only when its last line is immediately followed by the declaration. An empty `//` line keeps a group together; one blank line ends it. `cue fmt` preserves a single blank line and collapses two or more to one, so a detached block stays detached through formatting. The LSP hover (`internal/lsp/eval/eval.go`, `docComments`), `Value.Doc()`, `cue def` and this repo's `.tasks/generate-index.sh` all agree on that boundary.

Constraints: bash, awk and `cue` only (no Go here); two module roots (`opm/`, `k8s/`) that `Taskfile.yml` iterates over `MODULES`; the report MUST NOT fail `main` today (46 sites).

Two things differ from `core`. Rationale has no `SPEC.md` to point at; the full argument for a member lives in a `docs/<note>.md` (as `name-constraints.md` and `cue-guard-closedness-workaround.md` do) or in the enhancement entry that introduced it. And the test fixtures are not separate files but hidden `_test*` fields inline in transformer and blueprint files, so the exemption is by label, not by filename.

## Goals / Non-Goals

**Goals:**

- The rule stated in both normative sources (`CLAUDE.md`, `openspec/config.yaml`), so it reaches agents through the OpenSpec context as well as the repo guide.
- A mechanical report in the style of the existing gates, covering both modules.
- Zero change to either published module.

**Non-Goals:**

- Relocating existing comments (the follow-up sweep change, one commit per kind directory, `docs:` type).
- Failing the build before the sweep is done.
- Judging comment content.
- Touching `generate-index.sh` or either `INDEX.md`.

## Decisions

### D1. Detached notes go BELOW the field, after one blank line, prefixed `// WHY`

Same as `core` D1. A note under the field cannot be mistaken for the next field's doc, and a deleted blank line above it attaches it to nothing. The `// WHY` prefix marks the blank line as load-bearing.

### D2. Limit is 6 lines

Chosen by the user; identical to `core` so one rule reads the same across the line. Room for the contract and, where one exists, a `See docs/<note>.md` pointer.

### D3. Scope: every field and definition in `opm/**/*.cue` and `k8s/**/*.cue`, except `_test*` hidden fields

Test fixtures here are inline hidden fields (`_testDSCNIComponent`, `_testServiceUDPPortResolves`, 12 of the 46 sites). They exist to pin measured rendering and their long comments record what was measured; they are not a hover surface an author meets. Exempt by label prefix `_test`. Other hidden fields (`_updateStrategy`, `_prefix`) are in scope: they are hovered by every contributor to a transformer.

### D4. Skip `package`, `import`, `let` and comprehension clauses

The prototype flagged the `package` doc in `catalog.cue` and `identity/identity.cue` (4 sites) and one `let` in `container_helpers.cue`. Count only comment runs ending directly above a field label. Package docs are file-level documentation and not per-field hover.

### D5. Warn-only with a `--strict` switch, no baseline file

Chosen by the user. The script exits 0 and prints a count; `--strict` (or `DOC_CHECK_STRICT=1`) makes a non-zero count fail. The sweep change flips the Taskfile to strict as its last task.

### D6. One script, byte-identical to `core`'s

`.tasks/doc-check.sh` takes a directory argument, so the same file serves `src/` in `core` and each module root here. The Taskfile loops `MODULES` and passes each root. Keeping the two copies identical is a convention, not a gate; the root workspace already tracks a copy-parity check for other shared scripts (`task fixtures:lint`) and could grow one for this file later.

### D7. Where the rule text lives

`CLAUDE.md` § Working Style for Agents gains a "Doc comments" bullet group (three tiers, the limit, blank line detaches, `// WHY` below the field, `_test*` exempt, `task docs:check`). `openspec/config.yaml` § Code Style extends the existing "Every member carries a doc comment" bullet with the limit and the detach rule. The Build And Dev Commands table gains `task docs:check`. No new `docs/` note: the rule is short enough to live in the guide, and a note would be a third copy.

## Research & Decisions

### Doc-comment boundary

**Context**: Needed to know what exactly hover shows before writing a rule about it.
**Explored**: `cue/parser/parser.go` `next()` and `consumeCommentGroup` at v0.17.1; a scratch package run through `Value.Doc()`, `cue def` and `cue fmt` twice; the LSP hover path in `internal/lsp/cache/eval.go` and `internal/lsp/eval/eval.go`.
**Decision**: A single blank line is the detach mechanism; no attribute, no marker syntax.
**Rationale**: Every consumer keys on the same parser flag, and `cue fmt` is idempotent on the layout. Hover also concatenates doc groups from every declaration a field resolves through, so a member and a fragment that both document the same field would show both; no member does that today.

### Where the current length sits

**Explored**: Prototype report over `opm/` and `k8s/` at limits 4, 6, 8, 12.
**Decision**: 46 raw sites at 6, 32 after the D3 and D4 exemptions (30 in `opm`, 2 in `k8s`), listed in the sweep change's tasks rather than here.

## Risks / Trade-offs

- [Blank line above a `// WHY` block removed, re-attaching it as doc text] -> reported at the next `task check`; fails under strict.
- [Label regex misses an exotic label (interpolated, pattern constraint)] -> false negative only, never a spurious failure; recorded in the script header.
- [Warn-only output ignored until the sweep] -> accepted; the `CLAUDE.md` and `config.yaml` text carry the rule in that window.
- [The two script copies drift] -> convention for now; a root parity task is a one-line follow-up if it happens.

## Durable decisions

- The three-tier convention and the 6-line limit: lands in `CLAUDE.md` § Working Style for Agents and `openspec/config.yaml` § Code Style (task 3).
- `_test*` hidden fields are fixtures and exempt from the doc-comment limit: same `CLAUDE.md` bullet.
- Everything else stays with the change.
