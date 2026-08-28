## Context

Seven transformers in `opm/transformers/` resolve the workload name through `#WorkloadName` (`name_helpers.cue`): `deployment_transformer.cue`, `statefulset_transformer.cue`, `daemonset_transformer.cue`, `job_transformer.cue`, `cronjob_transformer.cue`, `hpa_transformer.cue`, `pdb_transformer.cue`. The trait lives at `opm/traits/v1beta1/resource_name.cue` (`#ResourceNameTrait`, `#ResourceName`, `#ResourceNameSchema`). No `apiVersion` segment moves; `k8s/` is untouched.

Constraints: `#names` is only concrete when `#instance` is set, which `#Module` does at render and fixtures must do by hand (`docs/name-constraints.md`, Fixtures section). Lexical scope: `#transform` reads `#component.#names...` through the `#component` slot, which is already declared `_`, so no re-declaration is needed. The list-index form stays: `#comp.spec.resourceName | *#comp.#names.resourceName` would let the default arm win over the concrete override.

## Goals / Non-Goals

**Goals:**
- Every primary-object name in the seven transformers is a read of `#component.#names.resourceName`, or of the deprecated trait through the single seam.
- HPA `scaleTargetRef.name`, PDB selector target and StatefulSet `serviceName` stay byte-identical to the objects they reference, with a guard per coupling.
- Rendered output unchanged for every component in the shipped fixtures.

**Non-Goals:**
- Deleting the trait or `#WorkloadName` (later change, after the `modules` migration).
- Secondary names (`#instancePrefix` on env secrets, per-volume ConfigMap/Secret/PVC names via `#ImmutableName`): stay derived as today; D15 lists them as carve-outs and a prefix policy for them is a separate question.
- Non-workload transformers (routes, network policy) and `k8s/`: `catalog-names-readonly-opm-rest`, `catalog-names-readonly-k8s`.

## Decisions

**D-A. `#WorkloadName` is kept as the deprecation seam, not deleted.** During the window both authorities exist; one helper that orders them is safer than seven inline list-index expressions.

```cue
#WorkloadName: {
	#comp!: _
	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		#comp.#names.resourceName,
	][0]
}
```

The `#instance` input goes away; callers become `(#WorkloadName & {#comp: #component}).out`. When the trait is deleted the helper collapses to a direct read and is removed.

**D-B. StatefulSet `serviceName` reads `expose.name` when `#Expose` is attached, else `#names.dns.short`.** `tr.#ExposeTrait` is in `optionalTraits` (`statefulset_transformer.cue:64`), and two shipped stubs (`_testSTSStrategyComponent`, `_testSTSRollingDefaultsComponent`) carry no `#Expose`, so the outer guard is live. `expose.name` is `name!` (D22), so the inner guard is dead and goes. The fallback arm's hand-rolled formula is replaced by `#component.#names.dns.short`: the same value for every no-Expose component (the trait never touches `#names`), and a read rather than a derivation.

```cue
serviceName: [
	if #component.spec.expose != _|_ {#component.spec.expose.name},
	#component.#names.dns.short,
][0]
```
Closedness, defaults and required fields of every member are unchanged.

**D-C. Fixture stubs set `#instance` and are pinned by interpolation, and `cue eval -c` is the concreteness gate.** Each `_test*Component` gains `#instance: {name, namespace, uuid}` matching its own file's stub context (`istio`/`istio-system` in most files, `shop`/`apps` in statefulset; `clusterDomain` defaults to `cluster.local` in core's `#InstanceIdentity`) so the default arm resolves. Measured (2026-08-27, core alpha.6): without `#instance`, `"\(x.#names.resourceName)" & "istio-istiod"` is merely incomplete and `cue vet ./...` (what `task vet` runs, no `-c`) exits 0, so an interpolation guard passes vacuously in exactly this case; `cue eval -c` on the guard is what refuses. Every file that has fixtures already has a trait-named one; what is missing is a default-named fixture with a name guard for hpa, pdb, job and cronjob (the last two have no fixtures at all) and a name guard for daemonset's default stubs. New parity guards: `_testPDBNameMatchesDeployment` (the PDB's `metadata.name` equals the Deployment's; its pod target is the selector, already guarded at `pdb_transformer.cue:153`) and `_testStatefulSetServiceNameMatchesService`, in the shape of `_testHPATargetMatchesDeployment` (`hpa_transformer.cue:272`).

**D-D. Deprecation is a doc-comment contract.** `#ResourceNameTrait`, the `#ResourceName` wrapper (the symbol modules attach) and `#ResourceNameSchema` keep their shape; each doc comment gains a `Deprecated:` line naming `metadata.resourceName` and the removal plan. `#ResourceNameSchema`'s comment is already at the 6-line cap, so one sentence moves to its WHY block. The WHY block records the semantic difference a migrating author must know: the core field also moves `#names.dns.*`, and with it the `expose.name` default, while the trait renamed the workload only.

## Research & Decisions

### Where the name is read from
**Context**: Three candidate sources hold the same value today: `#context` interpolation, `#component.metadata.resourceName`, `#component.#names.resourceName`.
**Explored**: Exploration 2026-08-27 in the workspace conversation; `core/src/component.cue:194` (`#names` derives from `metadata.resourceName` and is the only home of the DNS variants); `library/opm/kernel/component_fill_test.go:39` (a transformer reading `#component.#names.resourceName` and `dns.fqdn` renders through `Kernel.Compile`).
**Decision**: `#component.#names.resourceName`.
**Rationale**: D15's own alternatives table: `metadata.resourceName` is the cascade input, `#context` is (under D12) a projection of the component; `#names` is the finalized value.

### Gates
**Context**: D15 gates the sweep on the component fill and on the D16 default flip.
**Explored**: `opm/cue.mod/module.cue` pins `core@v2.0.0-alpha.6`, which carries D16 and D20 (`~/.cache/cue/mod/extract/opmodel.dev/core@v2.0.0-alpha.6/component.cue`); library PR 70 (`093119d`) landed the fill, released in v1.0.0-alpha.14.
**Decision**: no dep bump; proceed.
**Rationale**: both gates are already in the pinned versions.

### Live trait users
**Context**: D15 named istio-cni-node, istiod and database as trait fixtures.
**Explored**: `grep` across `modules/`, `cli/tests/fixtures`, `opm-operator/test/fixtures`, `library`: only `modules/istio_ambient/components_control_plane.cue` (istiod) attaches `tr.#ResourceName`.
**Decision**: keep the trait working through the seam; migrate istiod in `modules` before deletion.
**Rationale**: the fleet pins catalog releases, so a coexistence window lets the migration land as its own PR.

## Risks / Trade-offs

- A fixture whose `#instance.name` disagrees with its `#context.#moduleInstanceMetadata.name` renders a name from one and labels from the other -> stubs build both from the same literal; D12 later removes the duplication at the source.
- `#names` non-concrete in a fixture that forgot `#instance` -> `cue vet` passes vacuously (measured); the verification task runs `cue eval -c` over the guards, and `docs/name-constraints.md`'s Fixtures section is corrected to say so.
- A consumer on a pre-fill kernel gets an empty-disjunction error on every workload -> release class `feat!:` with the kernel floor in the release note.
- Parity harness in `library` pins the catalog by release -> byte-identity is checked against a `-dev` pre-release before the release PR, not inside this repo's `task check`.

## Durable decisions

- "A transformer reads the primary object's name from `#component.#names.resourceName`; it never interpolates it from `#context` or `metadata`" -> lands in `docs/name-constraints.md` as a new section "Transformers read names, never derive them", with the `#WorkloadName` seam documented as the deprecation-window exception.
- "An interpolation guard on `#names` passes vacuously under plain `cue vet` when `#instance` is missing; `cue eval -c` on the guard is the gate" -> corrects the Fixtures section of `docs/name-constraints.md`.
- "`#ResourceNameTrait` is deprecated in favour of `metadata.resourceName`; migrating moves `#names.dns.*` and the Service default with it, and the release carrying this change raises the kernel floor to `library` >= v1.0.0-alpha.14" -> stays with the change: the trait's doc/WHY comments carry the author-facing text, and the release note carries the floor.
