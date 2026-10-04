## Why

The opm-operator is about to ship as an OPM module that renders its RBAC through this catalog's role resource, and the catalog cannot yet carry five of its roles. `#RoleSchema` (`src/resources/v1beta1/role.cue:85`) requires at least one subject and `#RoleTransformer` (`src/transformers/role_transformer.cue`) always renders a binding beside the role, so the five ClusterRoles the operator ships unbound, for administrators to bind to users, cannot be expressed. A render of the operator through catalog `opm` 4.5.2 measured the gap (design.md, Research).

This is the role half of the earlier plan `add-seccomp-and-subjectless-roles`. The seccomp half shipped on its own as `add-seccomp-profile` (catalog_opm PR #141), because the publish compatibility gate of cli `v1.0.0-beta.7` refuses this half (Dependencies / gates).

## What Changes

- `src/resources/v1beta1/role.cue`: `subjects!` becomes `subjects?`; when present it is still a non-empty list. The doc comment and `metadata.description` say subjects are optional.
- `src/transformers/role_transformer.cue`: the RoleBinding and ClusterRoleBinding render only when `subjects` is present; a role with subjects renders exactly as before.
- `.opm-cli-version`: bumped to the first cli release whose compatibility gate carries the fix (gate below).
- Fixtures that fail when the behaviour regresses (length guards and an exported spec that pins `subjects` optional), in the embedded form.

Nothing is **BREAKING**: the edit only accepts values the published schema refused, and every value it accepted renders the same objects. No member moves `apiVersion` segment.

## Requirements

Each requirement is satisfied by the CUE in Before / After and the transformer edit above, and each is proven by a fixture that fails when it regresses (tasks.md), except R4, which the publish compatibility gate itself proves.

**R1. A role with no subjects renders the role alone, at both scopes.** `subjects` is optional on the role resource.

- WHEN a namespace-scoped role sets `rules` and no `subjects`, THEN `#RoleTransformer` renders exactly one object, a `Role`.
- WHEN a cluster-scoped role sets `rules` and no `subjects` (including a `nonResourceURLs` rule), THEN it renders exactly one object, a `ClusterRole`.

**R2. An empty subject list is still refused.** Absence is the one spelling of "no binding".

- WHEN a role sets `subjects: []`, THEN it does not unify with `#RoleSchema`.

**R3. A role with subjects renders exactly as before.**

- WHEN a namespace-scoped or cluster-scoped role sets one or more subjects, THEN the transformer renders the same two objects (role and binding, same names, labels and fields) as `opm` 4.5.2, proven by goldens at both scopes and an export byte-identical to `origin/main`.

**R4. The change passes the publish compatibility gate.**

- WHEN `opm catalog publish ./src --dry-run` runs with the cli named in `.opm-cli-version` after the bump, THEN it reports no compatibility violation for `role@v1beta1`.

## Before / After

**Before**

```cue
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

- **Upstream gate (blocks the PR, the archive and the merge): a cli release carrying the cli change `fix-compat-unauthored-defaults`, and this repo's `.opm-cli-version` bumped to it.** With cli `v1.0.0-beta.7`, `opm catalog publish ./src --dry-run` refuses `#RoleResource` against `opm@4.5.1` with `spec.role.subjects default changed ([{name!: string}] -> [{name!: string}])` (design.md, Compatibility gate). The two sides print the same; the "default" is the one CUE derives from `[...#RoleSubjectSchema] & [_, ...]`, which no `*` authored. `opm catalog publish` has no override and the release publish runs the same gate, so an owner exception cannot ship. The cli change compares defaults only where one was authored and does not treat a required-to-optional marker change on a list with no authored default as a default change. Section 1 is implemented ahead of it; section 2 waits for it.
- **Downstream:** the opm-operator change `add-operator-module` renders its five unbound ClusterRoles through `objects@v1alpha1` until an `opm` release carrying this change exists, and carries a follow-up task to switch them to `#Role` then. This change does not wait for it.

## Impact

- **Members touched, staying at `v1beta1`:** `role@v1beta1` and the role transformer. Relaxing a required field to optional is additive under 0010:D27; the gate's refusal is a false positive fixed upstream (Dependencies / gates).
- **`modules` fleet, `opm-modules`:** nothing to do. Their roles all set subjects and render the same objects by construction; this is measured against the catalog's own goldens (task 1.5), not against the fleets.
- **Subscribing platforms:** nothing to do; they pick up the minor through the release cascade.
- **`cli` fixtures under `testing.opmodel.dev`:** nothing to do.
- **opm-operator:** `add-operator-module` switches its five unbound ClusterRoles from `objects@v1alpha1` to `#Role` once this change is released (its follow-up task).
- **Release class:** section 1 `feat(catalog)`, section 2 `chore(deps)` (absent when `main` already pins the cli release). PR title: `feat(catalog): render a role with no subjects without a binding`. A minor release; no major, no path move.

## Principle V

The addition has a named consumer: the operator module ships five unbound ClusterRoles (`metrics-reader`, the ModuleInstance admin, editor and viewer roles, the TransformerRegistration admin role) for administrators to bind. Today a module either leaves the catalog for `objects@v1alpha1` or ships a binding it does not want. Only the presence of `subjects` changes; no new field, no default, no second spelling (`subjects: []` stays refused).

## Non-goals

- Aggregated ClusterRoles (`aggregationRule`) and binding names other than the derived ones: no module needs them.
- Binding an existing role from another component: out of scope; a role without subjects is bound by an administrator outside the module.
- The seccomp profile: shipped by `add-seccomp-profile`.
