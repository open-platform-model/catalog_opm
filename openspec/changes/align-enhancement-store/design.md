## Context

The store design is in the swarm design `T2.3` (sections 6 and 9). This repo holds 256 citations
of a decision number: the spoken form (`enhancement NNNN Dn`, 191 places) and the colon form
(`NNNN:Dn`, 65 places). They sit in 77 CUE
and Go comment lines, `AGENTS.md`, `docs/`, workflows, `.tasks/listing.sh` and 134 places in
archived changes. Generated `src/INDEX.md` repeats comment text and is regenerated.

No member file changes shape. Files touched are named by the rewrite tool's worklist, not
repeated here.

## Goals / Non-Goals

**Goals:**
- `enh cite-lint` reports 0 findings and `enh cite-rewrite --dry-run` reports 0 edits.
- The repo rules (`config.yaml`, `AGENTS.md`, schema templates) say the new rule.

**Non-Goals:**
- Any behaviour change. `CHANGELOG.md`, `vendor/` and `.claude/**` are not touched.
- The CI call of the lint (a later change).

## Decisions

### The rewrite runs once, by tool, then by hand
The tool writes the mechanical forms and a worklist of rows it cannot decide (lone ids, path
references, citations inside generated files). Each row is rewritten by the comment rule or left
with a reason. Commits are by place (code, live docs, archived changes) so a reviewer reads one
place at a time.

### Comment rule
An enhancement id appears only beside a reason in words, never alone, never with a decision number.
A `// WHY` block that held only an id gets the reason written out.

### Durable-decision check
`.tasks/openspec-check.sh` (run by `task openspec:check`, part of `task check`) reads each active
change's `design.md`. The `## Durable decisions` section must exist. If it is not "None.", it must
name a target: a `docs/` or `AGENTS.md` path that exists, or the words "stays with the change".
The check does not read the archive.

### Archive guidance replaces the skill patch
`operations.archive.guidance` carries the "durable decisions are landed" rule and the line "If the
change delivers a line of an enhancement's `tasks.md`, a PR on `enhancements` ticks that line."

## Risks / Trade-offs

- A rewritten citation can lose meaning -> the tool output is spot-read (40 edits at least) and
  the hand edits are listed in the report with `path:line`.
- Archived text is history -> only the citation form changes, never the decision or its outcome.
- The `REPO-LOCAL PATCH` blocks in `.claude/skills/` stay until the owner runs `openspec update`.
  They are listed in the report: `openspec-new-change` and `openspec-propose` (two blocks each:
  the `skip_specs` metadata, which OpenSpec 1.14.1 writes itself, and "declare the enhancement now",
  replaced by `rules.proposal`) and `openspec-archive-change` step 3b (replaced by
  `operations.archive.guidance` and `task openspec:check`).

## Durable decisions

- The comment rule (an enhancement id only beside a reason in words, never alone, never a decision
  number) lands in `AGENTS.md`.
- The rule that a change declares its enhancement with `Delivers NNNN, task X.Y.` lands in
  `AGENTS.md`.
