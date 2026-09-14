# Tasks: transformer-registration-contract

Three sections. design.md carries no unverified assumption, so section 1 is not a spike: the rendered shape was measured before the design was written (design.md, Research & Decisions), and section 1 lands the contract that measurement validated.

## 1. opm/resources/v1alpha1/transformer_registration.cue

- [x] 1.1 Add `#TransformerRegistrationResource` per design.md § The contract: `fulfilment: "catalog"`, no `matchLabels`, `spec.transformerRegistration` with `catalog!`, `version!` and `provides!` typed on core's `#ModulePathType`, `#VersionType` and `#ContractFQNType`. Doc-comment the three required fields and why the contract names a catalog, never a module. Verify: `(cd opm && cue vet ./...)` passes.
- [x] 1.2 Add a `#TransformerRegistration` component wrapper beside it, the idiom every member here follows (`#resources: (fqn): <Resource>`). Verify: a component attaching it with all three spec fields vets, and one omitting `catalog` fails naming the field (run once, in place, then remove the failing case).
- [x] 1.3 List the member in `opm/catalog.cue` `#resources`, keyed by its `metadata.fqn`. Verify: `task vet:listing` passes; commenting the entry out makes it fail naming the key.
- [x] 1.4 `task generate:index`, then `task check` green, then commit `feat(resources): add the transformer-registration contract at v1alpha1`.

## 2. opm/transformers/transformer_registration_transformer.cue

- [ ] 2.1 Add `#TransformerRegistrationTransformer` per design.md § The transformer: `requiredResources` on the contract FQN alone, empty label and trait maps, `producesKinds: ["TransformerRegistration"]`, and a struct `output` whose `metadata.name` is the dot-joined instance namespace and name (D12) and whose `spec.providerRef` is stamped from the same projected metadata (D11). Carry the group, version and kind as literals with a doc comment naming opm-operator as the other side. Verify: `(cd opm && cue vet ./...)` passes.
- [ ] 2.2 Add the golden fixture in the same file, in the shape design.md's second research entry requires: supply `#transform.#moduleInstance` (metadata name, namespace, fqn, uuid plus `#moduleMetadata.version`) and `#context: #runtimeName`, never `#moduleInstanceMetadata`. Pin the whole rendered object. Verify: `cue export -e '<fixture>' ./transformers` prints the object concretely (the pre-existing fixtures fail this, which is the point), and changing one expected byte makes `cue vet` fail.
- [ ] 2.3 List the transformer in `opm/catalog.cue` `#transformers`, keyed by its `metadata.fqn`. Verify: `task vet:listing` passes.
- [ ] 2.4 `task generate:index`, then `task check` green, then commit `feat(transformers): render the transformer-registration claim as the cluster-scoped CR`.

## 3. Durable decisions

- [ ] 3.1 `CLAUDE.md` Working Style: a transformer fixture supplies `#transform.#moduleInstance`, never `#context.#moduleInstanceMetadata`, with the measured reason (the 0019 D12 projection; `cue vet` stays green because the failure is incomplete-class, so `cue export` is what checks a fixture). Verify: the rule names both the wrong and the right spelling.
- [ ] 3.2 Record the pre-existing breakage as a follow-up rather than fixing it here: one line in `CLAUDE.md` beside the rule, or a `docs/` note, stating that 21 of the 23 transformer fixtures predate the projection and are unchecked until their own change. Verify: the count and the date are stated, so the follow-up change has its scope.
- [ ] 3.3 `task check` green, then commit `docs(claude): require the moduleInstance fixture shape for transformers`.
