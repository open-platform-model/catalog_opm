## 1. opm/transformers/name_helpers.cue

- [ ] 1.1 Rewrite `#WorkloadName`: drop `#instance!`, second arm becomes `#comp.#names.resourceName`; update the file header block, the doc comment and the WHY block to describe the deprecation seam (D-A).

## 2. opm/transformers workload callers

- [ ] 2.1 `deployment_transformer.cue`, `daemonset_transformer.cue`: callers become `(#WorkloadName & {#comp: #component}).out`; every `_test*Component` stub gains `#instance` matching its file's stub context (D-C); daemonset's default-named stubs get a name guard.
- [ ] 2.2 `statefulset_transformer.cue`: same caller change; `serviceName` becomes the two-arm list of D-B; stubs gain `#instance` (`shop`/`apps`); add `_testStatefulSetServiceNameMatchesService` (Expose stub) and a guard that a no-Expose stub's `serviceName` equals `#names.dns.short`.
- [ ] 2.3 `hpa_transformer.cue`: caller change; stubs gain `#instance`; add a default-named stub whose `scaleTargetRef.name` is pinned to `"istio-istiod"`; keep `_testHPATargetMatchesDeployment` green.
- [ ] 2.4 `pdb_transformer.cue`: caller change; stub gains `#instance`; add a default-named stub with a name guard and `_testPDBNameMatchesDeployment` in the HPA guard's shape.
- [ ] 2.5 `job_transformer.cue`, `cronjob_transformer.cue`: caller change; add a stub context, a default-named stub with `#instance` and an interpolation name guard, and a trait-named stub proving the seam honours the trait (no fixtures exist in either file today).

## 3. opm/traits/v1beta1/resource_name.cue

- [ ] 3.1 Add `Deprecated:` lines to the `#ResourceNameTrait`, `#ResourceName` and `#ResourceNameSchema` doc comments (≤6 lines each; `#ResourceNameSchema` is at the cap, move its pod-selector sentence to the WHY block) naming `metadata.resourceName`; extend the WHY block with the `#names.dns.*` / `expose.name` semantic difference (D-D).

## 4. Durable decisions

- [ ] 4.1 `docs/name-constraints.md`: add section "Transformers read names, never derive them" with the read rule and the `#WorkloadName` seam as the documented window exception.
- [ ] 4.2 `docs/name-constraints.md`, Fixtures section: replace "fails loudly" with the measured behaviour (vacuous pass under `cue vet`, `cue eval -c` is the gate).

## 5. Verification

- [ ] 5.1 `task generate:index` (doc comments changed on `#WorkloadName` and the trait).
- [ ] 5.2 `task check`.
- [ ] 5.3 Concreteness: `cue eval -c ./transformers -e <guard>` for every name guard added or touched (from `opm/`); a guard left incomplete is a fixture missing `#instance`.
- [ ] 5.4 Byte-identity: `cue export` a default-named and the istiod exact-named fixture before and after and `diff`; record the result in this change's design.md Research section.
