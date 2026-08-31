## Context

See proposal.md for motivation. Files touched, all under `opm/`: `traits/v1beta1/resource_name.cue` (deleted; the `v1beta1` traits segment keeps its other members), `transformers/name_helpers.cue`, `transformers/{deployment,statefulset,daemonset,job,cronjob,hpa,pdb}_transformer.cue`, `cue.mod/module.cue`, `identity/identity.cue`, `INDEX.md`; repo docs `docs/name-constraints.md`, `CLAUDE.md`, `README.md`, `openspec/config.yaml`. No `apiVersion` segment is added or moved. `k8s/` is untouched (no reference to the trait or the seam; verified 2026-08-30).

Constraints that shape the approach:

- `#component.#names.resourceName` is concrete only once `#instance` is set. Every fixture in the seven files already sets it (landed with `catalog-names-readonly-workloads`), and `cue eval -c` on the name guards is the concreteness gate, because plain `cue vet` accepts an incomplete `#names` (`docs/name-constraints.md` § Fixtures).
- The trait declares no `#nameConstraint`, so core's `_nameConstraints` conjunction never saw it; deleting it changes no constraint on any component.
- The trait is reachable from the published catalog value through seven `optionalTraits` maps, so it is a member in the publish compat gate's eyes. Removing a member within a major is refused (0011); the crossing is forced, not chosen.
- `#ServiceName` and the Expose posture are a separate question (`service-transformer-legacy-expose-fallback`) and stay as they are.

## Goals / Non-Goals

**Goals:**
- One authority for a workload's rendered name: `#component.#names.resourceName`, read directly at each of the seven sites.
- Rendered output byte-identical for every fixture and every consumer that renders today.
- The `@v4` crossing executed exactly the way `@v3` was (`catalog-remove-legacy-secrets` design D-A).

**Non-Goals:**
- Touching `#ServiceName`, `expose.name`, or any secondary name (`#ImmutableName`, per-volume names).
- Re-pinning consumers: `modules`, the platforms and the `cli`/`opm-operator` fixtures move to `@v4` in their own repos.
- Any `k8s/` change.

## Decisions

**D-A. The seam is deleted, not narrowed.** With one authority left, `#WorkloadName` would be a one-arm helper wrapping a field read. The seven sites read the field:

```cue
// deployment_transformer.cue (statefulset, daemonset, job, cronjob, pdb: same)
metadata: name: #component.#names.resourceName

// hpa_transformer.cue
_targetName: #component.#names.resourceName
```

Alternative: keep `#WorkloadName` as `out: #comp.#names.resourceName` so HPA and PDB keep naming the workload through one symbol. Rejected: the coupling the seam protected (HPA `scaleTargetRef.name`, the PDB's name and the StatefulSet `serviceName` matching the workload) is already guarded by `_testHPATargetMatchesDeployment`, `_testPDBNameMatchesDeployment` and `_testStatefulSetServiceNameMatchesService`, and a helper with one arm hides the read D15 wants visible. `#ServiceName` keeps two arms and stays.

**D-B. The trait leaves `optionalTraits` with no replacement.** A component built against `@v4` cannot attach a trait that does not exist, and a component built against `@v2` or `@v3` cannot render on a `@v4` platform at all (different module path). No closedness, default or required-field change reaches any surviving member: an `optionalTraits` entry constrains the transformer's match set, not a component's schema.

**D-C. Fixtures migrate to `metadata.resourceName`; the StatefulSet comments are rewritten.** Each exact-name fixture drops `tr.#ResourceName` and `spec.resourceName` and gains `metadata: resourceName:`; every pinned string stays (`istiod` in deployment, hpa and pdb; `istio-cni-node` in daemonset; `nightly-sync` in job and cronjob; `database` and `database-headless` in statefulset). The StatefulSet exact fixture used to prove that the trait renames the StatefulSet only, not its Service. That fact no longer exists. What it proves after this change: `metadata.resourceName: "database"` moves `#names.dns.short` along with the object name, so the Expose wrapper's default Service name would be `database` too; the explicit `expose.name: "database-headless"` wins over that default, and `serviceName` follows the Service that renders, not the workload's own name (0019 D22, carve-out 3). The two comments, final text:

```cue
// At the serviceName field:
// WHY: Deliberately NOT metadata.name. serviceName is a cross-object
// reference to the governing Service (0019 D22, carve-out 3), whose one
// authoritative name is expose.name, and an author may set that apart from
// the workload's resourceName. The read goes through #ServiceName so it
// stays byte-identical to the Service transformer's, including the fallback
// for a component compiled against a build whose expose.name was optional.

// Above _testSTSExactComponent:
// serviceName names the GOVERNING SERVICE, so it follows expose.name through
// #ServiceName, the seam the Service transformer renders through (0019 D22).
//
// resourceName and expose.name are set to DIFFERENT values on purpose.
// metadata.resourceName moves #names.dns.short along with the object name,
// so the Expose wrapper would default the Service to "database" as well; the
// explicit expose.name wins over that default, and the StatefulSet must point
// at the Service that actually renders, not at its own name. If serviceName
// ever collapses onto metadata.name, the second assertion fails.
```

The "Trait naming" and "Default naming" section comments in job, cronjob, deployment, daemonset, hpa and pdb that mention the trait or the seam are reworded to name `metadata.resourceName` and the direct read.

**D-D. The major crossing mirrors the `@v3` one.** `cue.mod/module.cue` and `identity.ModulePath` move to `opmodel.dev/catalogs/opm@v4` by hand; `identity.Version` is written by `opm catalog version set 4.0.0 ./opm`, never by hand (core asserts the major of `Version` agrees with `ModulePath`); `task tidy` afterwards; `.tasks/branch-tag.sh` confirms the branch tag derives `v4.0.0-0.dev.*`. Docs that state the major (`CLAUDE.md`, `README.md`, `openspec/config.yaml`) move with it.

## Research & Decisions

### Trait attachments outside the catalog
**Context**: sweep 3 is safe only if nothing attaches the trait.
**Explored**: `grep` for `ResourceNameTrait`, `#ResourceName`, `WorkloadName`, `resource-name` across `modules/`, `cli/tests`, `cli/examples`, `opm-operator/test`, `opm-operator/config`, `library/testdata`, `library/opm` on 2026-08-30. `istio_ambient` sets `metadata.resourceName` at three sites (istiod, istio-cni-node, ztunnel) and attaches no trait.
**Decision**: no coexistence window; delete in one change.
**Rationale**: zero attachments; the seam's trait arm is dead code in every consumer.

### Release class
**Context**: D15 said "removed outright, no deprecation cycle" under the alpha stance.
**Explored**: `opm-v3.0.0` published 2026-08-30T17:08Z (`catalog-remove-legacy-secrets`); `CLAUDE.md` release table (removing a definition is `feat!:`, and a `feat!:` bumps the module path since the alpha line closed at 2.0.0); the compat gate refuses a removed member within a major; zero consumers pin `@v3` (the fleet, the sample Platform, the template seed and every fixture still pin `@v2`).
**Decision**: `feat!:`, cutting `@v4` now, as its own change on its own branch.
**Rationale**: the crossing is free while every consumer still owes the `@v2` to `@v3` re-pin; waiting for another break to share a major has no scheduled partner. Recorded as enhancement 0019 D25.

### Name-constraint collection
**Context**: 0019 D21 collects every attached primitive's `#nameConstraint`.
**Explored**: `resource_name.cue` declares none (slot defaults to top).
**Decision**: nothing to do.
**Rationale**: unifying top is the identity; the conjunction is unchanged with the trait gone.

## Risks / Trade-offs

- [A guard passes vacuously because a fixture lost `#instance`] -> every touched fixture keeps its `#instance`; task 3.5 runs `cue eval -c` on every name guard, not `cue vet`.
- [A consumer still attaches the trait after re-pinning to `@v4`] -> impossible silently: `tr.#ResourceName` is an undefined reference and `spec.resourceName` a disallowed field, both refused at `cue vet` with the symbol named.
- [A stale `@v3` string survives in docs] -> task 4.4 enumerates every hit measured on 2026-08-30 and task 7.3 greps again at the end.
- [`library/testdata/parity` fixtures pinned to `catalogs/opm` 2.0.0 keep rendering the old catalog] -> not this change's concern; they attach no trait, and the parity harness re-pins at `library`'s own pace (`test(fixtures)` there).

## Durable decisions

- "Exact names are authored on `metadata.resourceName`; the catalog has no trait-based exact name" -> `docs/name-constraints.md` § "Transformers read names, never derive them" already states the read; the seam sentences are removed there (task 5.1) and the trait doc comments go with the file. Nothing new is promoted.
- The `@v4` crossing procedure -> stays with the change (`catalog-remove-legacy-secrets` design D-A is the durable statement; `CLAUDE.md` already carries the release-class rule).
