## Context

Two member files and one segment are touched: `src/traits/v1beta1/sizing.cue` and `src/traits/v1beta1/encryption.cue`, both `v1beta1`. Their keys are lines 54 and 73 of `src/catalog.cue`. No other `.cue` file under `src/` names either (search on `origin/main` 9595963: only the two files, `catalog.cue` and the generated `INDEX.md`). `docs/site/authoring/attach-a-trait.md` names both in an author note.

Listing is enforced in both directions by `task vet:listing`, so the file and its key go in the same commit.

## Goals / Non-Goals

**Goals:**

- Both traits MUST be gone from the published module: no definition, no key, no index row, no doc mention.
- A standing check MUST fail if either key returns to `#traits`.

**Non-Goals:**

- No transformer for either trait, and no replacement member.
- No new gate that every advisory trait has a transformer. HostNetwork on a stateless workload shows the general case is per transformer, not per catalog.
- No deprecation release. A deprecated trait that still renders nothing keeps the trap open for one more release and adds a state the catalog has no vocabulary for.

## Decisions

### D-A: Delete the files; no stub, no alias

The two files are deleted and the two keys removed. Considered:

1. Status quo: keep both. Refused by the proposal: a setting that is accepted and ignored.
2. Keep the definitions, unlist them. `task vet:listing` refuses a member with an `fqn` that is not a key, and an importable definition that no platform can see is the same trap.
3. Move both to `v1alpha1`. Alpha promises nothing (0010 D34), but the members would still render nothing; Principle V says to leave such a member out.
4. Delete (chosen).

No closedness, default or required-field set of a remaining definition changes.

### D-B: The standing check is an absence guard on `#traits`

```cue
// src/catalog_fixtures.cue
@if(fixtures)

package opm

import id "opmodel.dev/catalogs/opm/identity"

_testRemovedTraitsStayRemoved: [for k, _ in #traits if k == "\(id.kindPrefix.traits)/sizing@v1beta1" || k == "\(id.kindPrefix.traits)/encryption@v1beta1" {k}] & []
```

It uses the repo's `] & []` absence idiom and lives in the existing tagged fixture file of package `opm`, so `task vet` (`cue vet -t fixtures ./...`) runs it and a plain build never loads it. The keys are spelled from `id.kindPrefix`, never from the deleted definitions.

Considered: a shell gate in `.tasks/`. Refused: a new script for two names, where CUE already compares the map.

## Research & Decisions

### The guard fails before the change

**Context**: the brief asks for a test that fails before the change.
**Explored**: on `origin/main` 9595963, with the guard appended to `src/catalog_fixtures.cue`, `cue vet -t fixtures .` in `src/` (cue v0.17.1) prints `_testRemovedTraitsStayRemoved: incompatible list lengths (0 and 2)` and exits 1; `cue vet .` without the tag exits 0.
**Decision**: use the guard as written in D-B.
**Rationale**: it fails on the old tree for the stated reason and is invisible to consumers.

### The publish gate does not judge a removed member

**Context**: `ci.yml` runs `opm catalog publish ./src --dry-run` on every PR; a refusal would block the change.
**Explored**: cli `internal/publish/compat.go`: `compatScan` iterates the members of the build being published and looks each one up in a predecessor; nothing iterates the predecessor's members.
**Decision**: no override is needed; task 1.6 confirms it with a dry run.
**Rationale**: read from source at cli `v1.0.0-beta.10`, the pinned version.

### What an author sees after the removal

**Context**: the release note must say what a module that still attaches a removed trait gets.
**Explored**: scratch package inside `src/` on this branch (not committed), cue v0.17.1, a component that embeds `bp.#StatelessWorkload`.
- Embedding the wrapper, the form `docs/site/authoring/attach-a-trait.md` teaches: `tr.#Sizing` gives `web: undefined field: #Sizing:` with the file and line of the embedding; `tr.#EncryptionConfig` gives `web: undefined field: #EncryptionConfig:`. Exit 1 from `cue vet`, before any render.
- Keying `#traits` by the definition (`(tr.#SizingTrait.metadata.fqn): tr.#SizingTrait`): `cue vet -c` exits 1, but the first lines are `web.spec.restartPolicy: field not allowed` and `web.spec.scaling: field not allowed`, not the missing definition. `cue vet -c=false` exits 0. This form is not the documented one.
- Writing `spec: sizing` or `spec: encryption` with no attachment: not told apart from a control component by raw `cue vet` in this harness. `attach-a-trait.md` states such a field is refused as "field not allowed"; that was true before this change too, and was not measured here through `opm module build`.
**Decision**: the release note and the PR body name the embedding case and its `undefined field` error.
**Rationale**: it is the documented attachment form and the one case with a clean, measured message.

### The publish dry run

**Context**: task 1.6.
**Explored**: `opm catalog publish ./src --dry-run` with a cli built from the `cli` checkout at `v1.0.0-beta.10-11-gef54c046` (the pinned `v1.0.0-beta.10` binary is not installed on this machine): `member gate 69 members checked, 0 refused`, `posture gate 26 traits checked, 0 refused`, `compat gate 36 compared, 0 refused, 8 alpha-exempt, 0 prerelease-exempt, 0 new`; the one refusal is `already holds v4.6.0`.
**Decision**: nothing to change.
**Rationale**: already-published as the only refusal is the outcome `ci.yml` accepts outside a release.

## Risks / Trade-offs

- [A third-party module attached one of the traits] -> It fails to evaluate at its next pin bump with a CUE error that names the missing definition; the fix is to delete the attachment. The release note says the traits had no effect. The module's current pin keeps working: published builds are immutable.
- [A break ships in a minor] -> Owner decision (proposal, Release class). The PR body states the exception.
- [Someone re-adds `sizing` later with a transformer] -> The guard fails and its comment says why it exists; a re-add with a transformer deletes the guard entry in the same change.

## Durable decisions

None. The guard's own comment carries the one thing a future author must know; Principle V of `openspec/config.yaml` already says a member without a consumer stays out.
