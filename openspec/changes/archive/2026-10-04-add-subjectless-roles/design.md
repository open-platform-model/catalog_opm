## Context

Files and segments touched, all `v1beta1`, no segment moves:

- `src/resources/v1beta1/role.cue`: `#RoleSchema.subjects` (line 85), the `#RoleResource` doc comment and `metadata.description`.
- `src/transformers/role_transformer.cue`: `_k8sSubjects` (line 60) and the two binding arms of `output` (lines 91, 121).
- Fixtures: `role_transformer_fixtures.cue`.
- `.opm-cli-version`: the cli pin CI and the release publish install.

Closedness: unchanged. Defaults: none authored, added or changed (the compatibility gate of cli `v1.0.0-beta.7` nevertheless reports one; Compatibility gate below). Required-field set: `#RoleSchema` loses `subjects` (required to optional). No consumer breaks: every value that unified before still unifies and renders the same objects.

This is the role half of the plan `add-seccomp-and-subjectless-roles`; the seccomp half shipped as `add-seccomp-profile`. Decision letters below are renumbered for this change.

## Goals / Non-Goals

**Goals:**

- Proposal R1 and R2: a role with no subjects renders the Role or ClusterRole alone; an empty subject list stays refused.
- Proposal R3: a role with subjects renders exactly as before, proven by goldens at both scopes and an unchanged export.
- Proposal R4: the publish compatibility gate accepts the change, with the cli fix and no segment move.
- Every new fixture fails when the behaviour it covers regresses.

**Non-Goals:**

- Aggregated ClusterRoles and custom binding names (proposal Non-goals).
- Working around the gate in the catalog: no respelling passes it (Compatibility gate).

## Decisions

**D-A. `subjects` becomes optional, still non-empty when present.**

```cue
#RoleSchema: {
	name!: string
	scope: "namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects?: [...#RoleSubjectSchema] & [_, ...]
}
```

Absence is the one spelling of "no binding". `subjects: []` stays refused, as today: an empty list most often means a comprehension that matched nothing, and rendering no binding for it silently would hide that. Alternative considered: `subjects: [...] | *[]` with "empty means unbound"; rejected because it adds a default (a contract change the compat gate tracks) and two spellings of one intent.

**D-B. The binding arms are guarded on presence of `subjects`.**

```cue
_k8sSubjects: [if _role.subjects != _|_ for s in _role.subjects {...}]

output: [
	if _role.scope == "namespace" {/* Role, unchanged */},
	if _role.scope == "namespace" && _role.subjects != _|_ {/* RoleBinding, unchanged */},
	if _role.scope == "cluster" {/* ClusterRole, unchanged */},
	if _role.scope == "cluster" && _role.subjects != _|_ {/* ClusterRoleBinding, unchanged */},
]
```

The object bodies are untouched, so a role with subjects renders the same list (proposal R3). The transformer's `metadata.description` and `requiredResources` do not change; its doc comment names the role-only output.

**D-C. Fixtures assert the object count and pin `subjects` optional.** The role output's object count is asserted with `(len(out) + 0) & 1`, and the kind by interpolation (a concrete one-element list makes the interpolation complete). An optional schema field is pinned optional by exporting the spec that omits it through a `#transform`-form fixture (`.tasks/fixtures.sh` exports those, and a missing required field fails export); an output guarded on `!= _|_` stays concrete either way, so the output fixtures alone would not catch `subjects?` turning back into `subjects!`. Each new component is written in the embedded form (`{res.#X, ...}`), and each new transform output is declared `_test<Name>: (#RoleTransformer.#transform & {...}).output` so `task vet:fixtures` exports it.

**D-D. The cli pin moves with the change.** `.opm-cli-version` is bumped in this branch, in its own section, to the first cli release that carries `fix-compat-unauthored-defaults`. The pin is what CI's "Publish gates dry-run" and the release publish install, so bumping it elsewhere first would only matter if that release ships before this PR; either order is safe, and this section becomes a no-op when `main` already holds the release.

## Research & Decisions

### Measured gap: the operator rendered through catalog `opm` 4.5.2

**Context**: the opm-operator's planned module renders its RBAC through this catalog's role resource; before planning, the operator was rendered that way to see what the catalog could not carry.
**Explored**: 2026-10-04, operator v1.0.0-beta.5, core v2.0.0-beta.2, catalog `opm` 4.5.2, CLI 1.0.0-beta.7. A scratch module rendered all 19 objects of the operator's install manifest and a script compared them field by field with the manifest. Findings that concern this change:
- The five unbound ClusterRoles (`metrics-reader`, the ModuleInstance admin, editor and viewer roles, the TransformerRegistration admin role, none with an aggregation rule) could not go through `#Role`, because `#RoleSchema.subjects` requires at least one subject and the transformer always adds a binding. They were rendered through `objects@v1alpha1` instead.
- The bound roles (one namespaced Role, two ClusterRoles) rendered equal to the manifest through `#Role`, apart from the binding names the catalog derives from the role name. That naming is not changed here.
**Decision**: make `subjects` optional; nothing else from that render is in this change.
**Rationale**: the only RBAC gap the operator module cannot write around without leaving the catalog's abstractions.

### Spike: the guarded comprehension renders, and the assertions bite

**Context**: the design assumes the guarded comprehension renders one object and the planned fixtures fail on regression.
**Explored**: 2026-10-04, cue v0.17.1, a scratch copy of `src/` at `origin/main` f59af69 with D-A and D-B applied. `cue vet ./...` and `cue vet -t fixtures ./...` passed; `cue export -t fixtures` of the subject-less ClusterRole and Role outputs succeeded and rendered one-element lists. A role with `subjects: []` was refused. `cue export -t fixtures -e _testExtendedRulesTransformer` was byte-identical before and after. Mutation check: dropping `&& _role.subjects != _|_` from the ClusterRoleBinding arm failed `cue vet -t fixtures` with `conflicting values 2 and 1`.
**Decision**: D-A to D-C as written. No spike section is needed in tasks.md.
**Rationale**: every assumption was measured.

### Compatibility gate

**Context**: `opm catalog publish` runs the 0010:D27 additive-only walk on beta members; the release publish from main runs the same gate, and the command has no override.
**Explored**: 2026-10-04, cli `v1.0.0-beta.7` (the `.opm-cli-version` pin), cue v0.17.1. `cli/internal/compat/compat.go` reports: field removed, field added without optional or default, field made required (optional to required only), domain narrowed, default changed or removed. Measured:
- A local `opm catalog publish ./src --dry-run` and the CI "Publish gates dry-run" of catalog_opm PR #141 (before the split) both refuse `#RoleResource` against `opm@4.5.1`: `spec.role.subjects default changed ([{name!: string}] -> [{name!: string}])`.
- Cause, by a Go probe on the CUE API: for `[...string] & [_, ...]`, `Default()` returns `[string]` with `hasDefault=true`, under `!` and under `?` alike, and `IsConcrete()` is true because the check is shallow. `checkDefaults` therefore compares two "defaults" no author wrote. Its subsumption fallback passes for `!` to `!` and `?` to `?`, but for `!` to `?` it fails in one direction ("value not an instance").
- No respelling of the field in the catalog passes. `subjects?: [#RoleSubjectSchema, ...#RoleSubjectSchema]` and `subjects?: [_, ...] & [...#RoleSubjectSchema]` are refused with the same "default changed". `subjects?: list.MinItems(1) & [...#RoleSubjectSchema]` is refused twice: "default removed" and "domain narrowed". Only the unchanged `subjects!` passes.
**Decision** (supervisor, 2026-10-04): no segment move; the gate is fixed in the cli change `fix-compat-unauthored-defaults`, and this change waits for a cli release that carries it, then bumps `.opm-cli-version` (section 2).
**Rationale**: required to optional is none of the violation kinds 0010:D27 names, and every value the published schema accepted still unifies and renders the same objects. Moving `role` to `v1beta2` to get past a gate bug would leave a duplicate member behind for a contract that did not change. An owner exception cannot ship: there is no override, and the release publish would refuse too.

## Risks / Trade-offs

- An author writes `subjects: []` expecting an unbound role. -> Refused at vet, as today; the field's doc comment says to omit it.
- Version skew: at render the platform's dependencies win every shared path, so a module that pins the `opm` release carrying this change and omits `subjects`, rendered on a platform still at an older `opm`, is refused: the old `#RoleSchema` requires `subjects`. -> Loud, not silent; the platform upgrades its catalog first. The opm-operator change states the minimum `opm` it needs.
- The cli release slips. -> Sections 1 and 2 wait on the branch; the operator module keeps its `objects@v1alpha1` roles meanwhile.

## Durable decisions

None. The presence-list fixture rule this work relies on landed with `add-seccomp-profile` (`AGENTS.md`, the fixture bullets).
