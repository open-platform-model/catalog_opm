## Context

See proposal.md for motivation. The mechanism is unchanged from the gate change: a `//` group is a doc comment only when its last line sits directly above the declaration (cue v0.17.1 parser, `Doc` flag); one blank line detaches it and `cue fmt` preserves one blank line.

Files touched, all comments only. `opm/blueprints/v1beta1/stateless_workload.cue`; `opm/identity/identity.cue`, `k8s/identity/identity.cue`; `opm/resources/v1alpha1/namespace.cue`; `opm/resources/v1beta1/{configmap,container,crd,volume}.cue`; `opm/traits/v1beta1/{disruption_budget,expose,network_policy,pod_metadata,resource_name,runtime_class}.cue`; `opm/transformers/{container_helpers,daemonset_transformer,deployment_transformer,hpa_transformer,name_helpers,network_policy_transformer,pdb_transformer,pod_helpers,sa_helpers,secret_transformer,service_transformer,statefulset_transformer}.cue`; `k8s/resources/v1/object.cue`. No `apiVersion` segment is added or moved. Rule text in `CLAUDE.md`, `openspec/config.yaml`, `.tasks/doc-check.sh`, `Taskfile.yml`.

Constraints: no closedness, default or required-field change anywhere (the whole point is that the modules evaluate identically); `generate-index.sh` extracts the first sentence of a definition's doc comment, so first sentences MUST survive; `identity/identity.cue` is written by `opm catalog version set` (the only identity writer, 0011 D15), so its comment layout must survive that writer.

## Goals / Non-Goals

**Goals:**

- Zero sites reported by `task docs:check` in both modules, then the strict flip.
- Every sentence that exists today still exists afterwards, in the doc comment or in the WHY block above it.
- Both modules evaluate to byte-identical output; both INDEX files unchanged.
- Rule text and script in this repo agree with `core` (WHY block above).

**Non-Goals:**

- Rewriting, shortening or judging rationale. A WHY block MAY be long.
- Touching `_test*` fixture fields, `package` docs, `let` clauses.
- New `docs/<note>.md` files. Nothing in the 32 sites is a full argument that outgrows a WHY block; `name-constraints.md` and `cue-guard-closedness-workaround.md` already exist and are pointed at where relevant.
- Changing `generate-index.sh`.

## Decisions

### D1. The WHY block goes ABOVE the doc comment (amends gate D1)

The gate change placed it below the field. Review of the `core` sweep settled the opposite: every comment above a declaration is read as belonging to the declaration below it, so a block after the field reads as the NEXT field's rationale, and a block above the doc comment reads correctly at a glance. Layout at every site:

```cue
	// WHY ...: rationale, measured behaviour, history.
	// May span many lines and contain empty `//` lines.

	// Doc comment: the contract, at most 6 lines.
	// Optionally ends with `See docs/<note>.md`.
	field?: T
```

The blank line between the two groups is load-bearing: it is what stops the parser attaching the WHY block to the field. The `WHY` prefix marks it. This is the first commit of the change so no comment is moved under the stale rule.

### D2. Preserve, do not edit

Each sentence is moved, not rewritten. The doc comment keeps the sentences that state the contract; the rest move verbatim into the WHY block, in original order. Empty `//` separator lines inside the original stay inside the WHY block. Rationale: this change is reviewable only if a reader can confirm nothing was lost, and a sentence-level diff (every sentence of the old comment appears in the new file) is a mechanical check. Wording improvements are a separate `docs:` change.

### D3. Doc comment content rule

Keep in the doc comment, in this order of priority until 6 lines are used: what the field or definition is; what it renders to; what a value must satisfy (units, ranges, mutual exclusion); the pointer `See docs/<note>.md` when a note exists. Everything else is rationale: "because", "measured", "Kubernetes rejects otherwise", examples of real deployments, history ("was", "renamed in").

### D4. One commit per kind directory, mechanically checked

Commits: (1) rule correction; (2) `opm/blueprints`; (3) `opm/identity` and `k8s/identity`; (4) `opm/resources`; (5) `opm/traits`; (6) `opm/transformers`; (7) `k8s/resources`; (8) strict flip. Each commit MUST pass, per touched file: `cue fmt` idempotent; code identity (`grep -v '^\s*//' | grep -v '^\s*$'` of the file equals the same projection of `main:<file>`); every line of the old comment text present in the new file (sentence preservation); a blank line follows every WHY block; `bash .tasks/doc-check.sh <module>` reports zero sites for that file; `task generate:index:check` and `task vet` green. Same harness as the `core` sweep.

### D5. `identity/identity.cue` comments survive the writer

`kindPrefix` is a 7-line doc in both modules. Before moving it, `opm catalog version set --dry-run` (or the writer's source in `cli`) is checked to confirm the writer edits the two value tokens in place and preserves comments. If it re-serialises the file, the WHY block MUST be placed where the writer keeps it (file-level comment above the definition) instead of inside the struct.

### D6. Pointers

`opm/traits/v1beta1/resource_name.cue`, `opm/transformers/name_helpers.cue` (`#WorkloadName`) and `opm/traits/v1beta1/expose.cue` (`name`) end their doc comment with `See docs/name-constraints.md`. No other site has a note to point at; the enhancement entry, where one is cited, stays cited inside the WHY block.

## Research & Decisions

### Placement of the detached block

**Context**: The gate change put the block below the field.
**Explored**: The `core` sweep, PR core#55, moved 50 blocks and was reviewed at the nameConstraint and matchLabels sites; core's `design.md` D8 records the outcome.
**Decision**: Above the doc comment, one blank line between.
**Rationale**: Comments above a declaration are read as belonging to it. A below-the-field block reads as the next field's rationale.

### Effect on INDEX.md

**Context**: `generate:index:check` is part of `task check`.
**Explored**: `.tasks/generate-index.sh` takes the first sentence of a definition's doc comment.
**Decision**: Keep every first sentence in place (D2/D3); verify with `task generate:index:check` in every commit.
**Rationale**: The INDEX files should not change from a comment relocation; a diff there would mean a first sentence was lost.

## Risks / Trade-offs

- [A sentence dropped during a move] -> per-commit sentence-preservation check; `git diff --stat` must show comment-only line deltas of zero net loss.
- [A WHY block accidentally re-attached by a missing blank line] -> per-commit blank-line check plus `docs:check` (the block would count again and overflow).
- [Substitution collides with a repeated comment in the same file, mangling it] -> edit by explicit text-keyed replacement, review `git diff` per file, code-identity check.
- [`opm catalog version set` rewrites `identity.cue` and drops comments] -> D5, checked before the identity commit.
- [Strict flip breaks a PR opened before this lands] -> the report names file:line and the fix is a blank line; acceptable.

## Durable decisions

- D1 (WHY block above the doc comment, blank line between): lands in `CLAUDE.md` § Working Style for Agents "Doc comments" bullets and `openspec/config.yaml` § Code Style in the first commit; `.tasks/doc-check.sh` header carries it too.
- D3 (what stays in the doc comment): lands in the same `CLAUDE.md` bullet group, one sentence.
- Strict gate: `CLAUDE.md` command table and `openspec/config.yaml` say `task docs:check` fails on overruns (drop "warn-only").
- D2, D4, D5, D6: stay with the change.
