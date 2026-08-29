## Context

Files: `opm/resources/v1beta1/role.cue` (`#ResourcePolicyRuleSchema`, `#NonResourcePolicyRuleSchema`, segment `v1beta1`), `opm/transformers/role_transformer.cue` (fixtures only), `docs/struct-disjunctions.md` (new), `CLAUDE.md` (one pointer line). `k8s/` is untouched (its RBAC kinds are raw passthrough with no disjunction).

Constraint: `task docs:check` caps doc comments at 6 lines; rationale goes in a `// WHY` block above.

## Goals / Non-Goals

**Goals:**
- `#PolicyRuleSchema` resolves for every valid rule in both authoring forms.
- The failure class is caught by `task vet` from now on (embedded-form fixture).
- The authoring rule outlives the change (`docs/`).

**Non-Goals:**
- `#Secret` (`secret.cue:45`) has the same structure, but the old secret handling is being removed wholesale, so it gets no fix here.
- `#RoleSubjectSchema` (`{#WorkloadIdentitySchema | #ServiceAccountSchema}`): both arms are structurally identical, so the disjunction collapses; left alone.
- Enforcing "nonResourceURLs only in ClusterRole" in schema (stays a review rule, as today).

## Decisions

**D-A. Negative optional fields as the discriminator.** `field?: _|_` means "if present, this arm is a contradiction". Unlike a missing required field, a contradiction eliminates the arm during resolution, before closedness is consulted, so embedding cannot disable it.

```cue
#ResourcePolicyRuleSchema: {..., nonResourceURLs?: _|_}
#NonResourcePolicyRuleSchema: {..., apiGroups?: _|_, resources?: _|_, resourceNames?: _|_}
```
Closedness: unchanged (both arms stay closed definitions). Defaults: none. Required-field set: unchanged. Behaviour change only for a rule that mixes both forms, which becomes an error.

**D-B. Fixtures in the embedded form.** `res.#Role & {...}` resolves today and hides the bug; the new fixture is `{res.#Role, spec: role: ...}`. Guards are interpolation-pinned (`"\(x.rules[0].apiGroups[0])" & ""`, etc.) and checked with `cue eval -c` because plain `cue vet` accepts an incomplete value (measured in `catalog-names-readonly-workloads`).

## Research & Decisions

### Why the disjunction stays open under embedding
**Context**: `opm module build` on `istio_ambient` failed in `#RoleTransformer` at alpha.6 and alpha.7 while every catalog fixture passed.
**Explored**: Bisection 2026-08-28 in isolated CUE packages: conjunction (`#C & {...}`) resolves; embedding (`{#C, ...}`) leaves both arms, and the printed non-resource arm contains `apiGroups`, i.e. closedness did not reject it. `r.apiGroups != _|_` and `r.nonResourceURLs != _|_` both evaluate `false` on the unresolved element.
**Decision**: fix the schema, not the transformer or the fleet's authoring style.
**Rationale**: the transformer cannot dispatch on an element it cannot resolve, and embedding is the fleet's documented style (`DESIGN_PATTERNS.md` 12).

### Candidate fixes
**Context**: three options were probed.
**Explored**: (i) negative optional fields (D-A): all three rule shapes resolve in the embedded form, a mixed rule is refused. (ii) one flat struct with a hidden exactly-one assertion: the assertion fires on the bare definition. (iii) transformer-side re-unification with the matching arm: the presence guards are `false` on the unresolved element, so the dispatch list is empty.
**Decision**: (i).
**Rationale**: only option that resolves at the schema, keeps the two-shape contract, and needs no transformer change.

## Risks / Trade-offs

- A downstream author who relied on an invalid mixed rule rendering -> refused at vet with a clear error; none exists in the fleet (grep).
- `_|_` optional fields read oddly -> the WHY block and `docs/struct-disjunctions.md` explain the idiom once.

## Durable decisions

- "Arms of a struct disjunction MUST contradict each other on a present field (`other?: _|_`), never only on an absent required field; a disjunction distinguished by absence never resolves for an embedded component" -> `docs/struct-disjunctions.md` (new), pointer from `CLAUDE.md` Working Style beside the closedness-workaround pointer.
- "Every transformer's fixture set MUST include at least one component in the embedded form (`{res.#X, ...}`), because that is the fleet's authoring form and the one closedness does not protect" -> same note.
