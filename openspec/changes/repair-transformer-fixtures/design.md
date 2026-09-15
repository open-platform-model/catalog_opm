# Design: repair-transformer-fixtures

## Context

See `proposal.md` § Why. The authoring rule and the measured cause are already in `CLAUDE.md` § Working Style, landed with the D9 registration contract; the working examples are `opm/transformers/transformer_registration_transformer.cue` and `opm/transformers/pvc_transformer.cue`.

Measured 2026-09-15 (cue v0.17.1, core `v2.0.0-alpha.9`, catalog at 4.3.0), in `opm/`:

| Set | Count | Failing `cue export` |
| --- | --- | --- |
| Hidden `_test*` fields under `transformers/` | 231 | 92 |
| Rendered-output fixtures (`_testX: (#Y.#transform & {`) | 47 | 44 |
| Transformer files (excluding the four `*_helpers.cue`) | 23 | 22 carry at least one failure |

A full sweep of all 231 fields takes 42 seconds; the 47-field subset takes 9.

**Correction, measured 2026-09-15 while building the gate:** `k8s/` carries 29 transformers
and **9 rendered-output fixtures, all 9 failing**, in 6 files. The proposal's claim that
`k8s/` ships no transformers, and the Non-Goals entry that repeated it, were both wrong —
they were written from `k8s/`'s *contract* members, where the raw catalog files passthrough
schemas, not from its `transformers/` directory. The defect class is identical: six
`_test<Name>Context` definitions fill `#moduleInstanceMetadata` directly. Since `task
vet:fixtures` fans over `MODULES` and the last section wires it into `task check`, k8s has to
be repaired here or the gate cannot go green; it is repaired in its own section.

| Set | Count | Failing `cue export` |
| --- | --- | --- |
| `k8s/` rendered-output fixtures | 9 | 9 |
| `k8s/` transformer files carrying one | 6 | 6 |

## Goals / Non-Goals

**Goals**

- Every rendered-output fixture in the package evaluates, so its golden literal compares something.
- A gate that fails when one stops evaluating, wired into `task check`.
- Each disagreement between a repaired fixture and the real render is triaged rather than papered over.

**Non-Goals**

- Fixing a transformer whose rendered output turns out to be wrong. That is a `fix:` change of its own, named here.
- Component fixtures (`_test*Component`). Many are legitimately non-concrete and are not a golden-output check.
- `k8s/`'s component fixtures and passthrough schemas. Its 9 rendered-output fixtures ARE in scope — see the correction in Context.
- Any change to a published member's shape or output.

## Decisions

### The gate checks rendered-output fixtures, identified structurally

`.tasks/fixtures.sh <module-dir>` MUST enumerate fields declared as

```
_test<Name>: (#<Transformer>.#transform & {
```

under `<module>/transformers/*.cue`, and MUST run `cue export -e <field> ./transformers` on each, reporting the field name and CUE's error on failure. `task vet:fixtures` runs it per module; `task check` gains it after `vet:listing`.

The selector is the declaration form, not a naming convention: a fixture is a rendered output because it is the `.output` of a `#transform`, and a future author renaming `_testFooTransformer` to `_testFooRendered` stays covered. Restricting to that form is what keeps the gate honest: sweeping all 231 hidden fields reports 92 failures, most of them component fixtures whose attached primitives carry schemas and are non-concrete by design. A gate with 90 known-acceptable failures is a gate nobody reads.

### The repair is mechanical, but the golden literals are not

For the 21 files using the retired spelling the input edit is the same everywhere:

```cue
// before
#context: {
	#moduleInstanceMetadata: {name: …, namespace: …, fqn: …, version: …, uuid: …}
	#componentMetadata: name: …
	#runtimeName: "opm-test"
}

// after
#moduleInstance: {
	metadata: {name: …, namespace: …, fqn: …, uuid: …}
	#moduleMetadata: version: …
}
#context: #runtimeName: "opm-test"
```

`role_transformer.cue` supplies neither input and gains both.

What is not mechanical is the golden literal. Once the projection evaluates, `#context.componentLabels` reads `#component.metadata.name`, and `#context.labels` folds module, component and controller labels together. A fixture whose component never set `metadata.name` will render labels its literal does not claim. Every touched fixture MUST therefore be re-pinned against the actual export, one file at a time, and a file is done only when `cue export` succeeds AND `cue vet` still passes with the literal in place.

### A disagreement is triaged, not overwritten

These literals have never been compared against a real render, so a disagreement has two possible causes and they are not interchangeable:

1. The literal was written by hand against an intended output and the transformer renders something else. That is a rendering defect, possibly shipped, and MUST NOT be silently absorbed by rewriting the literal.
2. The literal encodes an assumption the projection changed (a label whose source moved). That is the fixture being stale and is repaired here.

Any case of (1) MUST be recorded in this design under a "Findings" heading with the transformer, the expected and actual bytes, and MUST be fixed in its own `fix:` change. This change never changes a transformer's output.

### Section order keeps every boundary green

The gate lands **unwired** in section 1 and is wired into `task check` only in the last section. Wiring it first would make `task check` red for every intermediate section, which the mergeable-sections invariant forbids. Between those, the repair runs in two batches, each ending with `cue export` clean for its own files and `task check` green.

## Research & Decisions

### What the gate should enumerate

**Context**: The obvious gate is "export every hidden `_test*` field", and it is wrong.
**Explored**: Both sweeps, scripted in the scratchpad and run against the tree at 4.3.0 (2026-09-15): all 231 hidden fields, then only the 47 declared as `(#X.#transform & {`.
**Decision**: The structural selector, 47 fields.
**Rationale**: the broad sweep reports 92 failures. Spot-checking them, `_testTransformerRegistrationComponent` fails while its sibling output fixture passes: a component fixture holds primitives whose `spec` is a schema, so it is non-concrete by design. Gating on that would either demand concreteness the design forbids or ship with a suppression list.

### The committed baseline

**Context**: sections 2, 3 and 4 need a fixed target, not a count re-measured per run.
**Explored**: `bash .tasks/fixtures.sh opm` then `… k8s` at HEAD of section 1 (cue v0.17.1, core `v2.0.0-alpha.9`, catalog at 4.3.0, 2026-09-15).
**Decision**: the list below is the baseline. A section is done when every one of its entries exports.
**Rationale**: 53 fixtures across 28 files — 44 in 22 `opm` files, 9 in 6 `k8s` files. Every one fails with the same root error, `#moduleInstance.metadata undefined as #moduleInstance is incomplete (type _)`, either directly or through `#context.componentLabels`'s interpolation.

- `opm/transformers/mutating_webhook_transformer.cue` — `_testMutatingWebhooksTransformer`
- `opm/transformers/namespace_transformer.cue` — `_testNamespacesTransformer`
- `opm/transformers/sa_resource_transformer.cue` — `_testSAResourceTransformer`
- `opm/transformers/validating_webhook_transformer.cue` — `_testValidatingWebhooksTransformer`
- `opm/transformers/admission_policy_transformer.cue` — `_testVAPTransformer`
- `opm/transformers/crd_transformer.cue` — `_testCRDTransformer`
- `opm/transformers/crd_transformer.cue` — `_testCRDBareTransformer`
- `opm/transformers/network_policy_transformer.cue` — `_testNetPolTransformer`
- `opm/transformers/grpc_route_transformer.cue` — `_testGrpcRouteTransformer`
- `opm/transformers/http_route_transformer.cue` — `_testHttpRouteTransformer`
- `opm/transformers/http_route_transformer.cue` — `_testHttpRouteLegacyExposeTransformer`
- `opm/transformers/service_transformer.cue` — `_testServiceDefaultNameTransformer`
- `opm/transformers/service_transformer.cue` — `_testServiceExactNameTransformer`
- `opm/transformers/service_transformer.cue` — `_testServiceUDPTransformer`
- `opm/transformers/service_transformer.cue` — `_testServiceLegacyExposeTransformer`
- `opm/transformers/tcp_route_transformer.cue` — `_testTcpRouteTransformer`
- `opm/transformers/tls_route_transformer.cue` — `_testTlsRouteTransformer`
- `opm/transformers/configmap_transformer.cue` — `_testConfigMapNamingTransformer`
- `opm/transformers/secret_transformer.cue` — `_testSecretNamingTransformer`
- `opm/transformers/cronjob_transformer.cue` — `_testCronJobDefaultNameTransformer`
- `opm/transformers/cronjob_transformer.cue` — `_testCronJobExactNameTransformer`
- `opm/transformers/daemonset_transformer.cue` — `_testDSCNITransformer`
- `opm/transformers/daemonset_transformer.cue` — `_testDSRuntimeClassTransformer`
- `opm/transformers/daemonset_transformer.cue` — `_testDSStrategyTransformer`
- `opm/transformers/daemonset_transformer.cue` — `_testDSRollingDefaultsTransformer`
- `opm/transformers/hpa_transformer.cue` — `_testHPAAutoTransformer`
- `opm/transformers/hpa_transformer.cue` — `_testHPADefaultNameTransformer`
- `opm/transformers/job_transformer.cue` — `_testJobDefaultNameTransformer`
- `opm/transformers/job_transformer.cue` — `_testJobExactNameTransformer`
- `opm/transformers/statefulset_transformer.cue` — `_testSTSDefaultTransformer`
- `opm/transformers/statefulset_transformer.cue` — `_testSTSExactTransformer`
- `opm/transformers/statefulset_transformer.cue` — `_testSTSStrategyTransformer`
- `opm/transformers/statefulset_transformer.cue` — `_testSTSRollingDefaultsTransformer`
- `opm/transformers/statefulset_transformer.cue` — `_testSTSLegacyExposeTransformer`
- `opm/transformers/role_transformer.cue` — `_testNsRoleTransformer`
- `opm/transformers/role_transformer.cue` — `_testClusterRoleTransformer`
- `opm/transformers/role_transformer.cue` — `_testExtendedRulesTransformer`
- `opm/transformers/role_transformer.cue` — `_testEmbeddedRoleOutput`
- `opm/transformers/deployment_transformer.cue` — `_testDeployDefaultNameTransformer`
- `opm/transformers/deployment_transformer.cue` — `_testDeployExactTransformer`
- `opm/transformers/deployment_transformer.cue` — `_testDeployRecreateTransformer`
- `opm/transformers/deployment_transformer.cue` — `_testDeployRollingDefaultsTransformer`
- `opm/transformers/pdb_transformer.cue` — `_testPDBTransformer`
- `opm/transformers/pdb_transformer.cue` — `_testPDBDefaultNameTransformer`
- `k8s/transformers/apiservice_transformer.cue` — `_testAPIServiceOverrideIgnoredTransformer`
- `k8s/transformers/csidriver_transformer.cue` — `_testCSIDriverExactNameTransformer`
- `k8s/transformers/csidriver_transformer.cue` — `_testCSIDriverOverrideIgnoredTransformer`
- `k8s/transformers/deployment_transformer.cue` — `_testDeploymentDefaultNameTransformer`
- `k8s/transformers/object_transformer.cue` — `_testObjectDefaultNameTransformer`
- `k8s/transformers/storageclass_transformer.cue` — `_testStorageClassDefaultNameTransformer`
- `k8s/transformers/storageclass_transformer.cue` — `_testStorageClassOverrideNameTransformer`
- `k8s/transformers/volumesnapshotclass_transformer.cue` — `_testVolumeSnapshotClassDefaultNameTransformer`
- `k8s/transformers/volumesnapshotclass_transformer.cue` — `_testVolumeSnapshotClassOverrideNameTransformer`

### `cue vet -c` is not an alternative

**Context**: The cheap fix would be to run the existing vet with `-c`.
**Explored**: `cue vet -c ./transformers` on the unrepaired tree.
**Decision**: Not usable; the gate needs `cue export` per field.
**Rationale**: it exits 0. `cue vet -c` does not check hidden fields, which is the same property the library's own pin files record, and every fixture here is hidden on purpose so that an importing package never evaluates them.

## Findings

### Section 2 (workload transformers): None.

No golden literal moved. All 17 fixtures across the five files (`deployment`, `statefulset`,
`daemonset`, `job`, `cronjob`) export concretely after the input edit alone, and `cue vet ./...`
still passes with every literal exactly as committed — verified by diffing the batch: the only
changed lines are the `#moduleInstance` / `#context` plumbing.

The design expected label drift (a component with no `metadata.name` rendering a different
`app.kubernetes.io/name` than its literal claims). It did not occur here because every one of
these fixtures already declared `#componentMetadata: name:` equal to its component's own
`metadata.name`, so the projection computes the same value the hand-written fill did.

### Section 3 (the remaining 17 `opm` files): one stale literal, no rendering defect.

**`role_transformer.cue` — stale, repaired here.** Its four fixtures supplied neither
`#moduleInstance` nor `#runtimeName`; instead they filled `#context: {namespace, labels,
componentAnnotations}` by hand. Two consequences, both fixture bugs rather than render bugs:

- `#context.namespace` is not a `#TransformerContext` field at all. The transformer reads
  `#context.#moduleInstanceMetadata.namespace`, so that fill was inert and the rendered
  namespace was never checked. It now comes from `#moduleInstance.metadata.namespace`.
- `#context.labels` IS a field, but a computed fold. Filling it with `labels: app: "<x>"`
  replaced the fold wholesale, and the golden literal recorded that fake. Expected (old
  literal): `labels: {app: "cert-manager"}`. Actual render: `{app.kubernetes.io/name,
  app.kubernetes.io/instance, app.kubernetes.io/managed-by, module-instance.opmodel.dev/name}`,
  all four `"cert-manager"`, and no `app` key. The literal is re-pinned to those four.

**Six component fixtures gained `metadata: name:`** (`admission_policy`, `configmap`,
`mutating_webhook`, `namespace`, `secret`, `validating_webhook`). Their old `#context`
fills supplied `#componentMetadata: name:` for components that never declared one; with the
projection live, `#context.componentLabels` reads `#component.metadata.name` and the export
fails `required field missing: name`. The name moves from the context onto the component, which
is where it now belongs. This is the label drift the design predicted, in its benign form: the
value is unchanged, only its source moved.

**No rendering defect found.** Verified mechanically rather than by eye: in a scratch copy of the
module each of the 10 fixtures that carries a separate golden literal block had that block
renamed to `<field>__GOLDEN`, making the render and the literal two independent fields, and every
leaf of the golden was compared against the render at the same path. All 10 are exact subsets —
229 leaves total, every one agreeing, none injecting a path the render does not produce.

### Measured: a golden literal unifies ONTO the render, so it asserts presence, never absence

This is what let `role`'s bogus `app: "cert-manager"` survive: the literal is unified onto the
rendered value, so a key the render does not produce is silently ADDED rather than rejected, and
an omitted key is not asserted absent. Two of the ten goldens are nearly vacuous as a result —
`_testServiceDefaultNameTransformer`'s asserts a single leaf and `_testCRDTransformer`'s eight.
Strengthening them is out of scope here (this change repairs evaluation, it does not raise
coverage), but the property is worth knowing before trusting a golden block: absence is checked
only by the explicit `] & []` comprehension guards the workload transformers use, never by a
golden literal.

### Measured: `cue vet` DOES catch an error-class conflict in a hidden field

Worth recording because it bounds exactly what the new gate adds. Reverting
`_testDeployDefaultNameResolves`'s pin from `"istio-istiod"` to `"istio-WRONG"` makes
`cue vet ./...` fail naming the field, even though it is hidden. What `cue vet` cannot see is the
*incomplete* class: a fixture whose inputs no longer make the output concrete, where the
interpolation guard is merely unresolved rather than conflicting.

So the two checks are complementary and both are needed: `cue vet` enforces the golden literals,
and `task vet:fixtures` enforces that there is something concrete for them to be enforced against.
`cue vet -c` closes neither gap — it does not descend into hidden fields at all.

## Risks / Trade-offs

- [Re-pinning 44 fixtures is a large mechanical diff in which a real defect could hide] -> two batches with a per-file rule: export must succeed and vet must still pass, and any literal that had to change in a way not explained by the projection is recorded as a Finding before the section's commit.
- [The repair uncovers a genuine rendering defect] -> expected, and the reason this change is `test:` only. The defect gets its own `fix:` change; this change's design names it.
- [The gate adds time to `task check`] -> measured 42 seconds for all 231 fields, so the 47-field subset is well under that; acceptable for a gate that runs in CI and before a commit.
- [A future author adds a fixture in a shape the selector misses] -> the selector keys on the `#transform` form every fixture must already use to render anything; a fixture that does not call `#transform` is not a rendered-output fixture.

## Durable decisions

- **The rendered-output fixture rule** is already in `CLAUDE.md` § Working Style. This change updates its "Known breakage, not yet repaired" sub-bullet: it is replaced by a pointer to `task vet:fixtures` as the standing gate.
- **`cue vet`, including `-c`, does not check hidden fixtures; `cue export` does** — stated once beside the gate's row in the commands table, so the next author does not re-discover it.
- Both land in `CLAUDE.md` in the last section, with the gate.

## Open Questions

None.
