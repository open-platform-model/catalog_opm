## Context

The controller is renamed `opm-controller`; see proposal.md. The catalog touches it only in prose. Files
touched: `src/transformers/transformer_registration_transformer.cue`,
`src/transformers/transformer_registration_transformer_fixtures.cue` (fixtures-tagged),
`src/resources/v1alpha1/transformer_registration.cue` (segment `v1alpha1`), the generated
`src/INDEX.md`, `AGENTS.md`, `.github/workflows/release.yml` and `.tasks/branch-tag.sh`. No closedness,
default or required-field set changes.

## Goals / Non-Goals

**Goals:**
- Every live mention of the product names `opm-controller` or "the controller".

**Non-Goals:**
- The Kubernetes `operator:` fields, third-party operators and the human role.
- `.tasks/cascade/wiring-check.sh` (a `.github`-owned byte-identical copy).
- `CHANGELOG.md` and the OpenSpec archive (history).
- A catalog release.

## Decisions

- **Exact strings, never a bare `operator` rule.** Each site is replaced by its full phrase
  (`opm-operator` → `opm-controller`, "the operator's" → "the controller's"). A word-level replace
  would hit `operator: "In"` selectors and toleration fields that are Kubernetes API.
- **Hidden commit types.** The edits are comments, so `docs` is the honest class; a `fix:` to force a
  release would publish an `opm` version whose only change is wording. The plan batches the text with
  the next functional change instead.
- **Cite as `0015:D3`** on the touched line, per the workspace reference format. Untouched citations
  on neighbouring lines are left for their own change.

## Risks / Trade-offs

- [The published `opm` module keeps the old wording until the next functional release] → accepted;
  the plan batches it, and the docs bundle rebuilds from that release.
- [The comments name `opm-controller` before the GitHub repo is renamed] → the branch merges only in
  the cutover sitting, after the rename.

## Durable decisions

- The product vocabulary ("controller" for the product, "reconcilers" for its per-kind loops,
  "operator" only for the human role, Kubernetes fields and third-party operators) is a workspace
  rule. Its home is the rename's enhancement entry and the workspace `AGENTS.md`; it stays with the
  change here, since no catalog authoring rule changes.
