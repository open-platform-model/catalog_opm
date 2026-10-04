## Context

Files and segments touched, all `v1beta1`, no segment moves:

- `src/resources/v1beta1/container.cue`: `#SecurityContextSchema` (line 249), plus three new non-member schema definitions. The schema is referenced by `#ContainerSchema.securityContext` (line 113, container scope), by `#SecurityContextTrait.spec.securityContext` (`src/traits/v1beta1/security_context.cue:32`, pod scope) and by `#StatelessWorkloadSchema.securityContext` (`src/blueprints/v1beta1/stateless_workload.cue:17`).
- `src/transformers/container_helpers.cue`: `#ToK8sContainer`'s container-level block (lines 131-159). Main, init and sidecar containers all go through it (`#ToK8sContainer` / `#ToK8sContainers`).
- Pod-level blocks: `deployment_transformer.cue:192`, `statefulset_transformer.cue:196`, `daemonset_transformer.cue:163`, `job_transformer.cue:162`, `cronjob_transformer.cue:160`. Each opens with a presence guard over the pod-level fields it renders, then renders them one by one.
- `src/traits/v1beta1/security_context.cue`: doc comment and `metadata.description` only.
- `src/resources/v1beta1/role.cue`: `#RoleSchema.subjects` (line 85).
- `src/transformers/role_transformer.cue`: `_k8sSubjects` (line 60) and the two binding arms of `output` (lines 91, 121).
- Fixtures: `container_helpers_fixtures.cue`, the five workload `*_transformer_fixtures.cue`, `role_transformer_fixtures.cue`.

Closedness: unchanged everywhere. Defaults: none added or changed. Required-field set: `#RoleSchema` loses `subjects` (required to optional); `#SecurityContextSchema` gains one optional field. Neither breaks a consumer: every value that unified before still unifies and renders the same objects.

## Goals / Non-Goals

**Goals:**

- Proposal R1 to R3: an author sets a seccomp profile at pod level (the `security-context` trait) and at container level (`#ContainerSchema.securityContext`), in the Kubernetes shape, and the rendered pod of every workload kind carries it.
- Proposal R4 and R5: a role with no subjects renders the Role or ClusterRole alone; an empty subject list stays refused.
- Proposal R6 and R7: a role with subjects, and every component that sets no seccomp profile, renders exactly as before, proven by unchanged exports of the existing goldens.
- Every new fixture fails when the behaviour it covers regresses.

**Non-Goals:**

- The four catalog rough edges the operator render hit (proposal Non-goals).
- Pod-level fields the trait accepts and no transformer renders (Risks).
- Propagating `#StatelessWorkloadSchema.securityContext` from the blueprint wrapper (Risks).
- `procMount`, `seLinuxOptions`, `appArmorProfile`, `windowsOptions`, `sysctls`: no module needs them (Principle V).

## Decisions

**D-A. Seccomp profile as a two-arm struct disjunction in the Kubernetes shape.**

```cue
#SecurityContextSchema: {
	// ...existing fields...
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
```

Kubernetes requires `localhostProfile` exactly when `type` is `Localhost`; the two arms encode that. They contradict on the present `type` field (and on a present `localhostProfile`), as `docs/struct-disjunctions.md` requires. A `RuntimeDefault` profile carrying `localhostProfile` is refused at `cue vet` (empty disjunction); a `Localhost` profile without one is incomplete and refused at render with a missing required field. The Kubernetes shape is kept, not abstracted: a seccomp profile has no OPM-level meaning beyond what the API says, and keeping its spelling lets an author copy it from any Pod Security guide. Alternative considered: a flat struct with `if type == "Localhost" {localhostProfile!: string}`; rejected because it needs a second conditional to forbid the field on the other types, and the repo already has one idiom for this.

**D-B. One field in the shared schema, rendered at both scopes.** The field goes into `#SecurityContextSchema`, not into a new pod-only schema, because Kubernetes accepts `seccompProfile` at both `PodSecurityContext` and container `SecurityContext`, and the trait and container already share this schema. The renderers copy it verbatim:

```cue
// container_helpers.cue, inside securityContext: {...}
if _sc.seccompProfile != _|_ {
	seccompProfile: _sc.seccompProfile
}

// each workload transformer's pod-level block
if _sc.runAsNonRoot != _|_ || ... || _sc.supplementalGroups != _|_ || _sc.seccompProfile != _|_ {
	securityContext: {
		// ...existing fields...
		if _sc.seccompProfile != _|_ {
			seccompProfile: _sc.seccompProfile
		}
	}
}
```

The guard must name the field: without it a pod security context holding only a seccomp profile renders no `securityContext` at all. The operator happens to set `runAsNonRoot` too, which would mask the bug for it.

**D-C. `subjects` becomes optional, still non-empty when present.**

```cue
#RoleSchema: {
	name!: string
	scope: "namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects?: [...#RoleSubjectSchema] & [_, ...]
}
```

Absence is the one spelling of "no binding". `subjects: []` stays refused, as today: an empty list most often means a comprehension that matched nothing, and rendering no binding for it silently would hide that. Alternative considered: `subjects: [...] | *[]` with "empty means unbound"; rejected because it adds a default (a contract change the compat gate tracks) and two spellings of one intent.

**D-D. The binding arms are guarded on presence of `subjects`.**

```cue
_k8sSubjects: [if _role.subjects != _|_ for s in _role.subjects {...}]

output: [
	if _role.scope == "namespace" {/* Role, unchanged */},
	if _role.scope == "namespace" && _role.subjects != _|_ {/* RoleBinding, unchanged */},
	if _role.scope == "cluster" {/* ClusterRole, unchanged */},
	if _role.scope == "cluster" && _role.subjects != _|_ {/* ClusterRoleBinding, unchanged */},
]
```

The object bodies are untouched, so a role with subjects renders the same list (proposal R6). The transformer's `metadata.description` and `requiredResources` do not change.

**D-E. The trait's description names what it renders.** `#SecurityContextTrait`'s doc comment and `metadata.description` become "Pod-level security settings for a workload: user, groups and seccomp profile". The current text claims "privilege and capabilities", which no workload transformer renders at pod level (they are container-only fields in Kubernetes); AGENTS.md § Descriptions forbids claiming behaviour no transformer has. `metadata.description` is on the compat gate's provenance denylist (0010:D30), so this is not a contract change.

**D-F. Fixtures assert presence and absence with list guards, not interpolation alone.** Interpolating a missing optional field (`"\(x.seccompProfile.type)" & "RuntimeDefault"`) is incomplete, not an error, so `cue vet` passes it when the field is not rendered (measured, Research below). Presence is asserted with `[if x.f != _|_ {x.f.type}] & ["RuntimeDefault"]`, absence with `[if x.f != _|_ {"leaked"}] & []`, and the role output's object count with `(len(out) + 0) & 1`. Each new component is written in the embedded form (`{res.#X, ...}`). The new transform outputs are declared `_test<Name>: (#<T>.#transform & {...}).output` so `task vet:fixtures` exports them.

## Research & Decisions

### Measured gap: the operator rendered through catalog `opm` 4.5.2

**Context**: the opm-operator's planned module renders its controller through this catalog's workload and role resources; before planning, the operator was rendered that way to see what the catalog could not carry.
**Explored**: 2026-10-04, operator v1.0.0-beta.5, core v2.0.0-beta.2, catalog `opm` 4.5.2, CLI 1.0.0-beta.7. A scratch module rendered all 19 objects of the operator's install manifest (4 CRDs, Namespace, Deployment, ServiceAccount, Service, one namespaced Role, two bound ClusterRoles, three bindings, five unbound ClusterRoles) and a script compared them field by field with the manifest. Findings that concern this change:
- The rendered Deployment's pod lost `securityContext.seccompProfile: {type: RuntimeDefault}`, which the manifest sets; the compare reported `.spec.template.spec.securityContext.seccompProfile: {"type": "RuntimeDefault"} -> "<absent>"`. Without it the pod fails Pod Security `restricted`. `grep -r seccomp src` found no field at either level. Every other pod-level field the operator sets (`runAsNonRoot`) rendered.
- The five unbound ClusterRoles (`metrics-reader`, the ModuleInstance admin, editor and viewer roles, the TransformerRegistration admin role, none with an aggregation rule) could not go through `#Role`, because `#RoleSchema.subjects` requires at least one subject and the transformer always adds a binding. They were rendered through `objects@v1alpha1` instead, so a subject-less catalog role has never been rendered; the spike below is the first.
- The bound roles (one namespaced Role, two ClusterRoles) rendered equal to the manifest through `#Role`, apart from the binding names the catalog derives from the role name. That naming is not changed here.
- Four further render failures, each reported only as "N errors in empty disjunction" and each avoidable in the module, are listed in the proposal's Non-goals.
**Decision**: add the seccomp field at both scopes and make `subjects` optional; nothing else from that render is in scope.
**Rationale**: these two are the only gaps the operator module cannot write around without leaving the catalog's abstractions; the rest have workarounds and stay follow-ups.


### Spike: both changes render, and the assertions bite

**Context**: the design rests on three assumptions: the seccomp disjunction resolves for an embedded component, the role transformer's guarded comprehension renders one object, and the planned fixtures fail on regression.
**Explored**: 2026-10-04, cue v0.17.1, a scratch copy of `src/` at `origin/main` f59af69 with D-A to D-D applied to `container.cue`, `container_helpers.cue`, `deployment_transformer.cue`, `role.cue` and `role_transformer.cue`, plus an embedded-form fixture file. `cue vet ./...` and `cue vet -t fixtures ./...` passed; `cue export -t fixtures` of the subject-less ClusterRole, subject-less Role and seccomp Deployment outputs succeeded. The Deployment rendered `seccompProfile: {type: "RuntimeDefault"}` at pod level and `{type: "Localhost", localhostProfile: "profiles/a.json"}` on the container. The subject-less ClusterRole rendered a one-element list. A `RuntimeDefault` profile with `localhostProfile` and a role with `subjects: []` were both refused. `cue export -t fixtures -e _testExtendedRulesTransformer` was byte-identical before and after (md5 `dd61bf91…`). Mutation checks: dropping `&& _role.subjects != _|_` from the ClusterRoleBinding arm failed `cue vet -t fixtures` with `conflicting values 2 and 1`; dropping `|| _sc.seccompProfile != _|_` from the Deployment's pod guard was NOT caught by an interpolation pin, and was caught by the presence-list guard (`incompatible list lengths (0 and 1)`).
**Decision**: D-A to D-D as written; fixtures per D-F. No spike section is needed in tasks.md.
**Rationale**: every assumption was measured, and the one that failed (interpolation pins catch a missing field) changed the fixture idiom, not the design.

### Compatibility gate

**Context**: `opm catalog publish` runs the 0010:D27 additive-only walk on beta members.
**Explored**: `cli/internal/compat/compat.go` `walkStruct`: violations are field removed, field added without optional or default, field made required (optional to required only), domain narrowed, default changed or removed.
**Decision**: no segment move; `role@v1beta1`, `container@v1beta1`, `security-context@v1beta1` and the blueprint stay where they are.
**Rationale**: required to optional and a new optional field are none of those kinds. CI's `opm catalog publish ./src --dry-run` confirms it on the PR.

## Risks / Trade-offs

- The trait accepts `privileged`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation` and `capabilities` at pod level and no transformer renders them; `job` and `cronjob` also drop `fsGroup` at pod level (`job_transformer.cue:164`, `cronjob_transformer.cue:162`). -> Pre-existing, out of scope; D-E stops the description from claiming them. Follow-up.
- `#StatelessWorkloadSchema.securityContext` is accepted and never propagated by the blueprint wrapper (`stateless_workload.cue` lines 82-96 propagate other fields only), so a seccomp profile set there is silently dropped. -> Pre-existing (also flagged in `docs/site/extending/write-a-blueprint.md`); the trait path works and is what the operator module uses. Follow-up.
- An author writes `subjects: []` expecting an unbound role. -> Refused at vet, as today; the role's doc comment says to omit the field.
- A Localhost profile without `localhostProfile` surfaces as a missing required field at render, not at `cue vet` of a non-concrete module. -> Same class as every other required field in the catalog.

## Durable decisions

- "`#SecurityContextSchema` is shared by pod and container scope. A new field that Kubernetes accepts at pod scope is wired into the pod-level block of all five workload transformers, in its presence guard as well as its body; a container-scope field is wired into `#ToK8sContainer`. Each is asserted by a presence-list guard at each scope." -> `docs/transformer-authoring.md`, new section 7.
- "An interpolation pin on an optional output field does not fail `cue vet` when the field is absent; assert presence with a one-element list guard." -> same section of `docs/transformer-authoring.md` (the deployment fixtures' header comment says it; no doc did).
