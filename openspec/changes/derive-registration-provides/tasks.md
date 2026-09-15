# Tasks: derive-registration-provides

Two sections. design.md's two research entries are readings of this repo (the `fulfilment:` hits
under `opm/` and `.tasks/listing.sh`'s member detection), not assumptions to prove, so section 1 is
not a spike.

## 1. opm — the pre-bound registration helper

- [x] 1.1 Add `#PreBoundRegistration` to `opm/resources/v1alpha1/transformer_registration.cue`, beside the contract it configures: `#identity` typed with `c.#ModulePathType` / `c.#VersionType`, `#transformers` typed openly, and `_providerSet` folding over both demand maps with an `!= _|_` guard on each, deduplicated through struct keys. `spec.transformerRegistration` derives `catalog`, `version` and `provides`. Verify: the definition carries no `fqn` (design.md § The listing gate keys on fqn) and `task vet:listing` stays green with no `catalog.cue` change.
- [x] 1.2 Write the helper's doc comment and its `WHY` block per `CLAUDE.md`'s doc-comment tiers: the doc comment (at most 6 lines) says what it is and what a provider catalog passes it; the `WHY` block above it records that it carries no `fqn` deliberately because it is not a catalog member, and that `opm`'s own transformer map folds to empty by the provider-fulfilled rule. Verify: `task docs:check` passes and the `fqn` note is present, so a later reader does not add one.
- [x] 1.3 Add golden fixtures covering the cases a real provider catalog hits: a synthetic transformer whose `requiredTraits` names `\(id.kindPrefix.traits)/backup@v1alpha1` yields exactly that FQN; a transformer with only `requiredResources`; one declaring neither map; two transformers requiring the same contract yielding one entry; and a non-provider `fulfilment` that must not appear. Verify: `task vet:fixtures` exports them — a fixture that only `cue vet`s proves nothing about a hidden field.
- [x] 1.4 Remove the "Authored today; a provider catalog derives it from its own transformer map once 0015 D11's fold ships" note from `provides!`'s doc comment, and say what fills it now. `provides!` stays required (design.md § provides stays required on the resource). Verify: the field is still `!`-required and the stale note is gone.
- [x] 1.5 `task generate:index` (the helper's doc comment is new INDEX content), then `task check` green — fmt check, vet, layering, listing, rendered-output fixtures, INDEX freshness and the doc-comment limit — then commit `feat(resources): derive a provider catalog's registration from its own transformers`.

## 2. Durable decision

- [x] 2.1 Add a line to `CLAUDE.md`'s Listing bullet (design.md § Durable decisions): `task vet:listing` keys on a member's `fqn` field, not on its location, so a definition filed under a kind directory with no `fqn` is deliberately not a member and needs no `catalog.cue` entry. The current text reads as though everything under `<kind>/` must be listed. Verify: the line sits with the existing listing guidance rather than in a new section.
- [x] 2.2 Append a second section to `docs/cue-guard-closedness-workaround.md` (design.md § Durable decisions): unifying two closed definitions closes the result to the intersection of their allowed fields, so a helper that extends a definition EMBEDS it rather than being unified beside it. Carry the reduced case and the measured `metadata.name: field not allowed` failure. Verify: the note's existing guard rule is untouched and the new section stands beside it.
- [x] 2.3 `task check` green, then commit `docs: record the two closedness rules vet and the listing gate depend on`.
