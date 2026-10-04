## Why

The opm-operator is about to ship as an OPM module rendered through this catalog (`enhancements/0028` D2), and the catalog cannot yet carry it. `#SecurityContextSchema` (`src/resources/v1beta1/container.cue:249`) has no seccomp field (`grep -r seccomp src` finds nothing), so no catalog-rendered pod can satisfy the Kubernetes Pod Security `restricted` profile, the operator's or any other module's. `#RoleSchema` (`src/resources/v1beta1/role.cue:85`) requires at least one subject and `#RoleTransformer` (`src/transformers/role_transformer.cue:91`, `:121`) always renders a binding, so the five ClusterRoles the operator ships for administrators to bind cannot be expressed. Experiment 01 of 0028 measured both gaps.

## What Changes

- `src/resources/v1beta1/container.cue`: `#SecurityContextSchema` gains an optional `seccompProfile?: #SeccompProfileSchema`, a two-arm struct disjunction (`RuntimeDefault` / `Unconfined`, or `Localhost` with a required `localhostProfile`). The schema is shared, so the field reaches the container resource's container, init and sidecar containers, the `security-context` trait (pod level) and the stateless-workload blueprint's schema at once.
- `src/transformers/container_helpers.cue`: `#ToK8sContainer` renders `securityContext.seccompProfile` when set (container level).
- `src/transformers/{deployment,statefulset,daemonset,job,cronjob}_transformer.cue`: the pod-level `securityContext` block renders `seccompProfile` when set, and its presence guard names the new field, so a pod-level security context holding only a seccomp profile still renders.
- `src/traits/v1beta1/security_context.cue`: the doc comment and `metadata.description` name the seccomp profile.
- `src/resources/v1beta1/role.cue`: `subjects!` becomes `subjects?`; when present it is still a non-empty list.
- `src/transformers/role_transformer.cue`: the RoleBinding and ClusterRoleBinding render only when `subjects` is present; a role with subjects renders exactly as before.
- Fixtures that fail when the behaviour regresses (presence and length guards, not only goldens), in the embedded form.
- `docs/transformer-authoring.md`: the shared-security-context wiring rule.

Nothing is **BREAKING**: both edits only accept values the published schema refused, and every value it accepted renders the same objects. No member moves `apiVersion` segment.

## Before / After

**Before**

```cue
// src/resources/v1beta1/container.cue
#SecurityContextSchema: {
	privileged?:   bool
	runAsNonRoot?: bool
	runAsUser?:    int
	runAsGroup?:   int
	fsGroup?:      int
	supplementalGroups?: [...int]
	readOnlyRootFilesystem?:   bool
	allowPrivilegeEscalation?: bool
	capabilities?: {
		add?: [...string]
		drop?: [...string] | ["ALL"]
	}
}

// src/resources/v1beta1/role.cue
#RoleSchema: {
	name!: string
	scope: "namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects!: [...#RoleSubjectSchema] & [_, ...]
}
// #RoleTransformer output: [Role, RoleBinding] | [ClusterRole, ClusterRoleBinding]
```

**After**

```cue
// src/resources/v1beta1/container.cue
#SecurityContextSchema: {
	// ...every field above, unchanged...
	seccompProfile?: #SeccompProfileSchema
}

#SeccompProfileSchema: #SeccompProfileBuiltinSchema | #SeccompProfileLocalhostSchema

#SeccompProfileBuiltinSchema: {
	type!:             "RuntimeDefault" | "Unconfined"
	localhostProfile?: _|_ // present -> not this form
}

#SeccompProfileLocalhostSchema: {
	type!:             "Localhost"
	localhostProfile!: string & !=""
}

// src/resources/v1beta1/role.cue
#RoleSchema: {
	name!: string
	scope: "namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects?: [...#RoleSubjectSchema] & [_, ...]
}
// #RoleTransformer output:
//   subjects set:    [Role, RoleBinding] | [ClusterRole, ClusterRoleBinding] (unchanged)
//   subjects absent: [Role] | [ClusterRole]
```

## Dependencies / gates

- **Upstream gate: none.** This change is wave 1 of the 0028 delivery; it depends on nothing unreleased. Task 1.1 confirms the base before any edit.
- **Downstream gate:** the opm-operator change `add-operator-module` (0028:D2) must not start until an `opm` catalog release carrying this change is published (release-please minor, `opm` 4.6.0 or later). That change pins the release; this change does not wait for it.

## Impact

- **Members touched, all staying at `v1beta1`:** `container@v1beta1`, `security-context@v1beta1`, `role@v1beta1`, the `stateless-workload@v1beta1` blueprint (through the shared schema), and the five workload transformers plus the role transformer. Adding an optional field and relaxing a required field to optional are both additive under 0010 D4 and pass the publish compatibility gate (`cli/internal/compat/compat.go` flags only removed fields, added required fields, narrowed domains, changed defaults and optional-made-required).
- **`modules` fleet, `opm-modules`:** nothing to do. Every existing component renders byte-identical objects.
- **Subscribing platforms:** nothing to do; they pick up the minor through the release cascade.
- **`cli` fixtures under `testing.opmodel.dev`:** nothing to do.
- **opm-operator:** its `add-operator-module` change pins the release and uses both features (seccomp `RuntimeDefault` at pod level, five subject-less ClusterRoles).
- **Release class:** section 1 `feat(catalog)`, section 2 `feat(catalog)`, section 3 `docs(catalog)`. PR title: `feat(catalog): add seccomp profiles and roles with no subjects`. A minor release; no major, no path move.

## Non-goals

Experiment 01's four catalog rough edges are follow-ups, excluded by 0028:D12 itself: a whole-number CPU string that passes the schema but fails `#NormalizeCPU`; the service account helper reading the optional `automountToken` unguarded; the workload blueprint requiring `restartPolicy` and `updateStrategy` that have API defaults; an `emptyDir` volume needing `readOnly` set explicitly. Also out: pod-level fields the trait accepts but no transformer renders (see design.md Risks).

## Enhancement

`enhancements/0028` D12 (R1, R2, R3), whole. Declared in `enhancement.yaml`.
