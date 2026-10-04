## Context

Files and segments touched, all `v1beta1`, no segment moves:

- `src/resources/v1beta1/container.cue`: `#SecurityContextSchema` (line 249), plus one new non-member schema definition, `#SeccompProfileSchema`. The schema is referenced by `#ContainerSchema.securityContext` (line 113, container scope), by `#SecurityContextTrait.spec.securityContext` (`src/traits/v1beta1/security_context.cue:32`, pod scope) and by `#StatelessWorkloadSchema.securityContext` (`src/blueprints/v1beta1/stateless_workload.cue:17`, accepted but never propagated, Risks).
- `src/transformers/container_helpers.cue`: `#ToK8sContainer`'s container-level block (lines 131-159). Main, init and sidecar containers all go through it (`#ToK8sContainer` / `#ToK8sContainers`).
- Pod-level blocks: `deployment_transformer.cue:192`, `statefulset_transformer.cue:196`, `daemonset_transformer.cue:163`, `job_transformer.cue:162`, `cronjob_transformer.cue:160`. Each opens with a presence guard over the pod-level fields it renders, then renders them one by one.
- `src/traits/v1beta1/security_context.cue`: doc comment and `metadata.description` only.
- `src/resources/v1beta1/role.cue`: `#RoleSchema.subjects` (line 85).
- `src/transformers/role_transformer.cue`: `_k8sSubjects` (line 60) and the two binding arms of `output` (lines 91, 121).
- Fixtures: `container_helpers_fixtures.cue`, the five workload `*_transformer_fixtures.cue`, `role_transformer_fixtures.cue`.

Closedness: unchanged everywhere. Defaults: none authored, added or changed (the compatibility gate nevertheless reports one for `subjects`; Compatibility gate below). Required-field set: `#RoleSchema` loses `subjects` (required to optional); `#SecurityContextSchema` gains one optional field. Neither breaks a consumer: every value that unified before still unifies and renders the same objects.

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
- The seccomp types `Unconfined` and `Localhost` (and `localhostProfile`): no module needs them; widening `type` later is additive (D-A).

## Decisions

**D-A. Seccomp profile in the Kubernetes shape, `RuntimeDefault` only.**

```cue
#SecurityContextSchema: {
	// ...existing fields...
	seccompProfile?: #SeccompProfileSchema
}

#SeccompProfileSchema: {
	type!: "RuntimeDefault"
}
```

The only consumer, the operator module, sets `RuntimeDefault` at pod level, and `RuntimeDefault` is what Pod Security `restricted` asks for. The definition is closed, so `localhostProfile` and any other key are refused at `cue vet`, as is any other `type`. The Kubernetes spelling is kept, not abstracted: a seccomp profile has no OPM-level meaning beyond what the API says, and keeping the shape lets an author copy it from any Pod Security guide and lets the renderers copy it verbatim. Alternative considered: the full Kubernetes domain, a two-arm struct disjunction of `RuntimeDefault | Unconfined` against `Localhost` with a required `localhostProfile`; rejected under Principle V because no module needs the other two types, it costs a disjunction, a `_|_` arm, a WHY block and extra negative fixtures, and once published those values can never be removed from `v1beta1`. Adding them later is additive under the compatibility gate (a widened `type` domain and a new optional `localhostProfile`), and a disjunction then becomes the shape to revisit.

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

**D-F. Fixtures assert presence and absence with list guards, not interpolation alone.** Interpolating a missing optional field (`"\(x.seccompProfile.type)" & "RuntimeDefault"`) is incomplete, not an error, so `cue vet` passes it when the field is not rendered (measured, Research below). Presence is asserted with `[if x.f != _|_ {x.f.type}] & ["RuntimeDefault"]`, absence with `[if x.f != _|_ {"leaked"}] & []`, and the role output's object count with `(len(out) + 0) & 1`. An optional schema field is pinned optional by exporting the spec that omits it through a `#transform`-form fixture (`.tasks/fixtures.sh` exports those, and a missing required field fails export); an output guarded on `!= _|_` stays concrete either way. Each new component is written in the embedded form (`{res.#X, ...}`). The new transform outputs are declared `_test<Name>: (#<T>.#transform & {...}).output` so `task vet:fixtures` exports them.

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

**Context**: the design rests on three assumptions: the seccomp field resolves for an embedded component, the role transformer's guarded comprehension renders one object, and the planned fixtures fail on regression.
**Explored**: 2026-10-04, cue v0.17.1, a scratch copy of `src/` at `origin/main` f59af69 with D-A to D-D applied to `container.cue`, `container_helpers.cue`, `deployment_transformer.cue`, `role.cue` and `role_transformer.cue`, plus an embedded-form fixture file. `cue vet ./...` and `cue vet -t fixtures ./...` passed; `cue export -t fixtures` of the subject-less ClusterRole, subject-less Role and seccomp Deployment outputs succeeded. The Deployment rendered `seccompProfile: {type: "RuntimeDefault"}` at pod level and `{type: "Localhost", localhostProfile: "profiles/a.json"}` on the container. The subject-less ClusterRole rendered a one-element list. A `RuntimeDefault` profile with `localhostProfile` and a role with `subjects: []` were both refused. `cue export -t fixtures -e _testExtendedRulesTransformer` was byte-identical before and after. Mutation checks: dropping `&& _role.subjects != _|_` from the ClusterRoleBinding arm failed `cue vet -t fixtures` with `conflicting values 2 and 1`; dropping `|| _sc.seccompProfile != _|_` from the Deployment's pod guard was NOT caught by an interpolation pin, and was caught by the presence-list guard (`incompatible list lengths (0 and 1)`).
That spike used the wider two-arm disjunction D-A now rejects; the narrowed `{type!: "RuntimeDefault"}` is its `RuntimeDefault` arm without the `localhostProfile?: _|_` line, so the pod and container renders carry over unchanged. Measured separately for the narrowed schema (cue v0.17.1): `{type: "Foo"}`, `{type: "Localhost"}` and `{type: "RuntimeDefault", localhostProfile: "x"}` each fail to unify, and the negative guard `[if (v & #SeccompProfileSchema) != _|_ {"accepted"}] & []` passes `cue vet` for all three and fails with `incompatible list lengths (0 and 1)` when given `{type: "RuntimeDefault"}`.
**Decision**: D-A to D-D as written; fixtures per D-F. No spike section is needed in tasks.md.
**Rationale**: every assumption was measured, and the one that failed (interpolation pins catch a missing field) changed the fixture idiom, not the design.

### Compatibility gate

**Context**: `opm catalog publish` runs the 0010:D27 additive-only walk on beta members; the release publish from main runs the same gate, and the command has no override.
**Explored**: 2026-10-04, cli `v1.0.0-beta.7` (the `.opm-cli-version` pin), cue v0.17.1. `cli/internal/compat/compat.go` reports: field removed, field added without optional or default, field made required (optional to required only), domain narrowed, default changed or removed. Measured:
- The PR's CI "Publish gates dry-run" and a local `opm catalog publish ./src --dry-run` both refuse `#RoleResource` against `opm@4.5.1`: `spec.role.subjects default changed ([{name!: string}] -> [{name!: string}])`. `container@v1beta1`, `security-context@v1beta1` and the blueprint report nothing.
- Cause, by a Go probe on the CUE API: for `[...string] & [_, ...]`, `Default()` returns `[string]` with `hasDefault=true`, under `!` and under `?` alike, and `IsConcrete()` is true because the check is shallow. `checkDefaults` therefore compares two "defaults" no author wrote. Its subsumption fallback passes for `!` to `!` and `?` to `?`, but for `!` to `?` it fails in one direction ("value not an instance"). Making the concreteness check deep would not help: the fallback still fails.
- No respelling of the field in the catalog passes. `subjects?: [#RoleSubjectSchema, ...#RoleSubjectSchema]` and `subjects?: [_, ...] & [...#RoleSubjectSchema]` are refused with the same "default changed". `subjects?: list.MinItems(1) & [...#RoleSubjectSchema]` is refused twice: "default removed" and "domain narrowed". Only the unchanged `subjects!` passes.
**Decision**: no segment move; `role@v1beta1`, `container@v1beta1`, `security-context@v1beta1` and the blueprint stay where they are. The refusal is a false positive in the gate, fixed upstream: `checkDefaults` ignores a default that no `*` marker authored. This change waits for a cli release that carries the fix, then bumps `.opm-cli-version` (proposal Dependencies / gates, task 2.6).
**Rationale**: required to optional and a new optional field are none of the violation kinds 0010:D27 names, and every value the published schema accepted still unifies and renders the same objects. Moving `role` to `v1beta2` to get past a gate bug would leave a duplicate member behind for a contract that did not change. An owner exception cannot ship: there is no override, and the release publish would refuse too.

## Risks / Trade-offs

- The trait accepts `privileged`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation` and `capabilities` at pod level and no transformer renders them; `job` and `cronjob` also drop `fsGroup` at pod level (`job_transformer.cue:164`, `cronjob_transformer.cue:162`). -> Pre-existing, out of scope; D-E stops the description from claiming them. Follow-up.
- `#StatelessWorkloadSchema.securityContext` is accepted and never propagated by the blueprint wrapper (`stateless_workload.cue` lines 82-96 propagate other fields only), so a seccomp profile set there is silently dropped. -> Pre-existing (also flagged in `docs/site/extending/write-a-blueprint.md`); the trait path works and is what the operator module uses. Follow-up: catalog_opm issue #140.
- An author writes `subjects: []` expecting an unbound role. -> Refused at vet, as today; the role's doc comment says to omit the field.
- Version skew: at render the platform's dependencies win every shared path, so a module that pins the `opm` release carrying this change and uses either feature, rendered on a platform still at `opm` 4.5.x, is refused: the old closed `#SecurityContextSchema` rejects `seccompProfile`, and the old `#RoleSchema` requires `subjects`. -> Loud, not silent; the platform upgrades its catalog first. The opm-operator change states the minimum `opm` it needs.
- An author needs `Localhost` or `Unconfined`. -> Refused at `cue vet` today; added as an additive widening when a module needs it (D-A).

## Durable decisions

- "`#SecurityContextSchema` is shared by pod and container scope. A new field that Kubernetes accepts at pod scope is wired into the pod-level block of all five workload transformers, in its presence guard as well as its body; a container-scope field is wired into `#ToK8sContainer`. Each is asserted by a presence-list guard at each scope." -> `docs/transformer-authoring.md`, new section 7.
- "An interpolation pin on an optional output field does not fail `cue vet` when the field is absent; assert presence with a one-element list guard." -> `AGENTS.md`, the fixture bullets, beside the rule that a golden literal asserts presence and never absence (the deployment fixtures' header comment says it; no doc did).
