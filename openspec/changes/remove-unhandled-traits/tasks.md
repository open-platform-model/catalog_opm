## 1. src/traits/v1beta1/sizing.cue, src/traits/v1beta1/encryption.cue, src/catalog.cue

- [x] 1.1 `src/catalog_fixtures.cue`: add the absence guard `_testRemovedTraitsStayRemoved` with its `identity` import (design D-B). Confirm `cue vet -t fixtures .` in `src/` fails with `incompatible list lengths (0 and 2)` before the next task.
- [x] 1.2 Delete `src/traits/v1beta1/sizing.cue` and `src/traits/v1beta1/encryption.cue`; remove the `#EncryptionConfigTrait` and `#SizingTrait` keys from `#traits` in `src/catalog.cue` (design D-A). Confirm the guard now passes.
- [x] 1.3 `task generate:index`; review the `src/INDEX.md` diff: exactly the seven rows of the two files go.
- [x] 1.4 `docs/site/authoring/attach-a-trait.md`: remove the sentence that names EncryptionConfig and Sizing from the author note of step 5.
- [x] 1.5 Measure what an author sees: in a scratch package inside `src/` (not committed), evaluate a component that embeds `tr.#Sizing`, one that embeds `tr.#EncryptionConfig`, and one that writes `spec: sizing` without the embedding; record the three error texts in design.md under Research & Decisions.
- [x] 1.6 Cross-cutting: `opm catalog publish ./src --dry-run` with the pinned cli reports no compatibility refusal (already-published as the only refusal is the CI-accepted outcome); search the repo for `sizing` and `encryption` and confirm no hit outside `openspec/changes/` and the guard.
- [x] 1.7 `task check` green, then commit `feat(traits): remove the sizing and encryption traits, which rendered nothing`
