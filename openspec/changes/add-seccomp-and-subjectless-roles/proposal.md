## Why

The opm-operator is about to ship as an OPM module that renders its controller through this catalog's workload and role resources, and the catalog cannot yet carry it. `#SecurityContextSchema` (`src/resources/v1beta1/container.cue:249`) has no seccomp field (`grep -r seccomp src` finds nothing), so no catalog-rendered pod can satisfy the Kubernetes Pod Security `restricted` profile: not the operator's, not any other module's. `#RoleSchema` (`src/resources/v1beta1/role.cue:85`) requires at least one subject and `#RoleTransformer` (`src/transformers/role_transformer.cue`) always renders a binding beside the role, so the five ClusterRoles the operator ships unbound, for administrators to bind to users, cannot be expressed. A render of the operator through catalog `opm` 4.5.2 measured both gaps (design.md, Research).

## What Changes

- `src/resources/v1beta1/container.cue`: `#SecurityContextSchema` gains an optional `seccompProfile?: #SeccompProfileSchema`, a two-arm struct disjunction (`RuntimeDefault` / `Unconfined`, or `Localhost` with a required `localhostProfile`). The schema is shared, so the field reaches the container resource's main, init and sidecar containers, the `security-context` trait (pod level) and the stateless-workload blueprint's schema at once.
- `src/transformers/container_helpers.cue`: `#ToK8sContainer` renders `securityContext.seccompProfile` when set (container level).
- `src/transformers/{deployment,statefulset,daemonset,job,cronjob}_transformer.cue`: the pod-level `securityContext` block renders `seccompProfile` when set, and its presence guard names the new field, so a pod-level security context holding only a seccomp profile still renders.
- `src/traits/v1beta1/security_context.cue`: the doc comment and `metadata.description` name the seccomp profile.
- `src/resources/v1beta1/role.cue`: `subjects!` becomes `subjects?`; when present it is still a non-empty list.
- `src/transformers/role_transformer.cue`: the RoleBinding and ClusterRoleBinding render only when `subjects` is present; a role with subjects renders exactly as before.
- Fixtures that fail when the behaviour regresses (presence and length guards, not only goldens), in the embedded form.
- `docs/transformer-authoring.md`: the shared-security-context wiring rule and the presence-list assertion rule.

Nothing is **BREAKING**: both edits only accept values the published schema refused, and every value it accepted renders the same objects. No member moves `apiVersion` segment.

## Requirements

Each requirement is satisfied by the CUE in Before / After and the transformer edits above, and each is proven by a fixture that fails when it regresses (tasks.md).

**R1. Pod-level seccomp profile.** A module author sets a seccomp profile on a workload through the `security-context` trait, and the pod rendered by every workload transformer (Deployment, StatefulSet, DaemonSet, Job, CronJob) carries it at `spec.template.spec.securityContext.seccompProfile` (for a CronJob, inside the job template's pod spec).

- WHEN a component's trait sets only `securityContext: seccompProfile: type: "RuntimeDefault"` and no other pod-level field, THEN the rendered pod's `securityContext` exists and its `seccompProfile` is `{type: "RuntimeDefault"}`.
- WHEN the trait sets a seccomp profile beside other pod-level fields (`runAsNonRoot`, `fsGroup`, ...), THEN every one of them renders, unchanged from today.

**R2. Container-level seccomp profile.** A module author sets a seccomp profile on a container's `securityContext` (main, init or sidecar), and the rendered container carries it.

- WHEN a container sets `securityContext: seccompProfile: {type: "Localhost", localhostProfile: "profiles/a.json"}`, THEN the rendered container's `securityContext.seccompProfile` carries both fields.

**R3. The seccomp profile has the Kubernetes shape and refuses invalid combinations.** `type` is one of `RuntimeDefault`, `Unconfined`, `Localhost`; `localhostProfile` is a non-empty string, required when `type` is `Localhost` and refused otherwise.

- WHEN a profile is `{type: "RuntimeDefault", localhostProfile: "x"}`, THEN it does not unify with `#SeccompProfileSchema` (refused at `cue vet`).
- WHEN a profile is `{type: "Localhost"}` with no `localhostProfile`, THEN the render fails on a missing required field.
- WHEN a profile names any other `type`, THEN it is refused.

**R4. A role with no subjects renders the role alone, at both scopes.** `subjects` is optional on the role resource.

- WHEN a namespace-scoped role sets `rules` and no `subjects`, THEN `#RoleTransformer` renders exactly one object, a `Role`.
- WHEN a cluster-scoped role sets `rules` and no `subjects` (including a `nonResourceURLs` rule), THEN it renders exactly one object, a `ClusterRole`.

**R5. An empty subject list is still refused.** Absence is the one spelling of "no binding".

- WHEN a role sets `subjects: []`, THEN it does not unify with `#RoleSchema`.

**R6. A role with subjects renders exactly as before.**

- WHEN a namespace-scoped or cluster-scoped role sets one or more subjects, THEN the transformer renders the same two objects (role and binding, same names, labels and fields) as `opm` 4.5.2, proven by goldens at both scopes and an export byte-identical to `origin/main`.

**R7. Existing components render unchanged and the change is additive.**

- WHEN a component sets no `seccompProfile` at either level, THEN no `seccompProfile` key appears in the rendered pod or container, and every existing workload golden exports unchanged.
- WHEN `opm catalog publish ./src --dry-run` runs the compatibility gate, THEN it reports no violation for `container@v1beta1`, `security-context@v1beta1`, `role@v1beta1` or `stateless-workload@v1beta1`.

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

- **Upstream gate: none.** This change depends on nothing unreleased. Task 1.1 confirms the base before any edit.
- **Downstream gate:** the opm-operator change `add-operator-module` must not start until an `opm` catalog release carrying this change is published (release-please minor, `opm` 4.6.0 or later). That change pins the release; this change does not wait for it.

## Impact

- **Members touched, all staying at `v1beta1`:** `container@v1beta1`, `security-context@v1beta1`, `role@v1beta1`, the `stateless-workload@v1beta1` blueprint (through the shared schema), and the five workload transformers plus the role transformer. Adding an optional field and relaxing a required field to optional are both additive under 0010 D4 and pass the publish compatibility gate (`cli/internal/compat/compat.go` flags only removed fields, added required fields, narrowed domains, changed defaults and optional-made-required).
- **`modules` fleet, `opm-modules`:** nothing to do. Every existing component renders byte-identical objects.
- **Subscribing platforms:** nothing to do; they pick up the minor through the release cascade.
- **`cli` fixtures under `testing.opmodel.dev`:** nothing to do.
- **opm-operator:** its `add-operator-module` change pins the release and uses both features (seccomp `RuntimeDefault` at pod level, five subject-less ClusterRoles).
- **Release class:** section 1 `feat(catalog)`, section 2 `feat(catalog)`, section 3 `docs(catalog)`. PR title: `feat(catalog): add seccomp profiles and roles with no subjects`. A minor release; no major, no path move.

## Principle V

Both additions have a named consumer today: the operator module sets `RuntimeDefault` at pod level and ships five unbound ClusterRoles. Beyond it, `restricted` Pod Security is a baseline for any production workload, and its seccomp requirement cannot be met through the catalog at all today. Only `seccompProfile` is added; `procMount`, `seLinuxOptions`, `appArmorProfile`, `windowsOptions` and `sysctls` stay out until a module needs them.

## Non-goals

The same operator render hit four catalog rough edges, each a render failure reported only as "N errors in empty disjunction". The operator module works around each, so they are follow-ups, not part of this change: a whole-number CPU string (`"2"`) passes `#ResourceRequirementsSchema` but fails `#NormalizeCPU`, which converts only `"<n>m"`; `#ToK8sServiceAccount` reads the optional `automountToken` unguarded, so leaving it unset fails the render; the workload blueprint requires `restartPolicy` and `updateStrategy`, which have API defaults; an `emptyDir` volume needs `readOnly` set explicitly. Also out: pod-level fields the trait accepts but no transformer renders, and the blueprint's unpropagated `securityContext` (design.md Risks).
