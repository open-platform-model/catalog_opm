## Context

Files: `opm/transformers/http_route_transformer.cue`, `grpc_route_transformer.cue`, `tcp_route_transformer.cue`, `tls_route_transformer.cue`, `network_policy_transformer.cue`; docs `docs/name-constraints.md`, `CLAUDE.md` (Working Style, Naming bullet). No member under `opm/<kind>/<apiVersion>/` changes. Depends on `catalog-names-readonly-workloads` having landed (`#WorkloadName` seam, `#instance` fixture idiom in use).

Route transformers reference the backing Service by name in `backendRefs`; today that is the same `_name` as the route's own name, which is only correct while the Service keeps its default name. None of the four requires `#ExposeTrait` (`requiredTraits` holds only the route trait, `optionalTraits: {}`, e.g. `http_route_transformer.cue:30-33`), and the route traits carry no backend name field (`route_common.cue:16-18`). `#StatefulSetTransformer` reads `expose.name` for `serviceName` when Expose is attached (workloads slice); routes always need the Service, so they require it.

## Goals / Non-Goals

**Goals:**
- Zero hand-rolled primary-object names left in `opm/transformers/`.
- Every exact-name site carries an `// exact` comment naming the external contract it honours.
- Authoring rules for name reads and label copies live in `docs/` and `CLAUDE.md`.

**Non-Goals:**
- Secondary-name prefix policy (`#instancePrefix` on env-secret refs uses the instance name; volume ConfigMap/Secret names use `<instance>-<component>`); unchanged here, flagged as a follow-up question for the enhancement.
- `k8s/` (next slice).

## Decisions

**D-A. Routes require `#ExposeTrait` and reference the Service through `expose.name`.**

```cue
requiredTraits: {
	(tr.#HttpRouteTrait.metadata.fqn): tr.#HttpRouteTrait
	(tr.#ExposeTrait.metadata.fqn):    tr.#ExposeTrait
}
#transform: {
	_name:        #component.#names.resourceName
	_backendName: #component.spec.expose.name
}
```
With Expose required, `expose.name` (`name!`, defaulted on the wrapper) is concrete on every matched component, so no fallback arm exists and no derived name survives. The alternative, Expose in `optionalTraits` with `[if expose != _|_ {expose.name}, #names.dns.short][0]`, preserves matching for a route-without-Service component, which is a component that renders a dangling reference; refusing it at match time is the better failure. Matching semantics change for that one shape; closedness, defaults and required fields of every member are unchanged.

**D-B. Exact-name sites are audited, not rewritten.** `namespace` (externally referenced), `crd` (`<plural>.<group>`), the two webhook configurations (patched by name at runtime), `admission_policy` policy and binding names, `role` (Role, RoleBinding, ClusterRole, ClusterRoleBinding, all `_role.name`) and `sa_resource` (via `#ToK8sServiceAccount`, `sa_helpers.cue:27`) render authored names verbatim. `namespace` and the webhooks already carry an inline `// exact` comment; `crd`, `admission_policy`, `role` and `sa_helpers` gain one. `service` reads `expose.name` and is already compliant. `configmap` and `secret` emit content-hashed per-item names through `#ImmutableName` / `#SecretImmutableName`; `pvc` emits one prefixed name per persistent volume (`pvc_transformer.cue:57`); all three stay as they are.

**D-C. Two rules become text.** In `docs/name-constraints.md`: (1) the read rule with the three carve-out classes from D15; (2) "never copy `resourceName` into a label value": `app.kubernetes.io/name` and the selector labels carry the component name (`#NameType`, ≤63 runes), never `resourceName` (≤253). `CLAUDE.md`'s Naming bullet gains one sentence pointing at both.

## Research & Decisions

### Which opm transformers still derive a primary name
**Context**: D15 counted five formula shapes across the catalog.
**Explored**: `grep` for `#moduleInstanceMetadata.name)-` and `#WorkloadName` across `opm/transformers/*_transformer.cue` and the helper files (2026-08-27): seven workloads covered by the previous slice; routes and network_policy interpolate inline; seven exact; three secondary; `service` reads `expose.name`; `container_helpers`, `pod_helpers`, `sa_helpers` derive no primary name. Verified by a read-only sweep of all 20 transformer files.
**Decision**: five transformers in scope, seven audited, three left derived, one already compliant.
**Rationale**: matches D15's carve-out classes one to one.

### Label-copy rule enforcement
**Context**: D19 asks the sweep to turn "safe by construction" into a contract.
**Explored**: `core/src/transformer.cue:173`, `componentLabels` are built from the component name; no catalog transformer writes `resourceName` into a label.
**Decision**: a documented review rule, no structural guard.
**Rationale**: CUE cannot forbid a string copy; the docs note plus catalog review is the enforcement D15 chose for the read rule too.

## Risks / Trade-offs

- A route component without `#Expose` stops matching -> intended; sweep the `modules` fleet for that shape before release and record the result here. **Swept 2026-08-28:** every module attaching a route trait on `modules` `main` (11 modules) and on the `v1` branch (11 modules) also attaches `#Expose`; no consumer is affected.
- Secondary-name prefixes disagree today for non-`opm-secrets` Secrets (env `secretKeyRef` prefixes with the instance name, `secret_transformer.cue:65` renders `<instance>-<component>-<name>`), and job/cronjob pass no volume prefix -> pre-existing, out of scope, filed as a follow-up question on enhancement 0019.
- Override-honouring changes route/policy names for a component with explicit `metadata.resourceName` -> intended; no consumer sets it on those components; called out in the release note.

## Durable decisions

- "A transformer reads the primary object's name from `#component.#names.resourceName`, with exact-name kinds, secondary/multi-object names and cross-object references as the three carve-out classes" -> `docs/name-constraints.md`, section "Transformers read names, never derive them" (created by the workloads slice, completed here with the carve-outs).
- "No transformer copies `resourceName` into a label value" -> `docs/name-constraints.md` (same section) and a sentence in `CLAUDE.md`'s Naming bullet.
- "Cross-object references (route `backendRefs`, StatefulSet `serviceName`) follow the referenced object's naming rule (`expose.name` for a Service)" -> `docs/name-constraints.md`.
