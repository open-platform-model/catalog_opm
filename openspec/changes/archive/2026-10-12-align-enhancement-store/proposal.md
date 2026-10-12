## Why

The OPM enhancements now live in an OpenSpec store (`opm-enhancements`). A decision number is not a
stable name there: an entry can be split or renumbered, so a citation of decision number 4
can point at the wrong text later. This repo cites decision numbers in 256 places (code comments, docs, archived changes) and
tells agents to write `enhancement.yaml` files that the store no longer reads. The citations must
name an enhancement by its id beside a reason in words, and the rules for agents must match.

## What Changes

- Every enhancement citation becomes an id beside a reason in words. No decision number, no lone
  id. The `enh cite-rewrite` tool does the mechanical part; the rest is rewritten by hand.
- The 13 archived `enhancement.yaml` files are deleted.
- `openspec/config.yaml` gains `references:` for the store, the `Delivers NNNN, task X.Y.` proposal
  rule, the comment rule and a pointer to read an entry. The `enhancement.yaml` and delivery-log
  rules go. `AGENTS.md` and the `catalog-change` schema templates say the same.
- The "durable decisions are landed" patch of the archive skill becomes
  `operations.archive.guidance` plus a check in `task check` (`task openspec:check`) that a change
  whose design names a promotion target names a file that exists.
- No behaviour changes. Only comments, rule text, archived text, doc text and generated
  descriptions move. `src/INDEX.md` is regenerated, never edited.

## Before / After

Not applicable: no member shape changes. The CUE that changes is comment text only.

## Impact

Consumers (`modules` fleet, subscribing platforms, `cli` fixtures) see no change; the published
catalog differs only in comment text. All commits are non-releasing types (`docs:`, `test:`,
`chore:`), so the PR title is `docs(openspec): align catalog_opm with the enhancements store` and
cuts no release.

The `.claude/skills/` files are the owner's. The `REPO-LOCAL PATCH` blocks there still ask for
`enhancement.yaml` until the owner runs `openspec update` with the pinned CLI; the design lists
them.

## Enhancement

None.

Excluded from the rewrite: `CHANGELOG.md` (release-please output, history) and `.claude/**` (the
`openspec-*` skill files, which the owner regenerates with `openspec update`). Archived text keeps
a bare decision number that names a decision of the archived change itself, of `core` or of
`docs-kit`, and keeps an enhancement id that already has words around it. A decision number in a
quoted decision title is quoted history and stays.

`skip_specs: true` is set in `.openspec.yaml`: this schema has no specs artifact, and the change
edits comments, docs and rules only.
