# Authoring rule: struct disjunction arms must conflict on a present field

**Status:** Permanent authoring rule (measured 2026-08-28/29 against CUE `v0.17.1`,
core `v2.0.0-alpha.6` and `alpha.7`). This is evaluator semantics, not a bug;
there is nothing upstream to wait for.

## The rules

1. **Arms of a struct disjunction MUST contradict each other on a *present*
   field, never only on an absent required field.** Each arm refuses the other
   arm's discriminating fields outright with `other?: _|_`. A disjunction whose
   arms differ only by which required field is missing never resolves for an
   embedded component.
2. **Every transformer's fixture set MUST include at least one component in the
   embedded form (`{res.#X, ...}`).** That is the fleet's authoring form
   (`modules/DESIGN_PATTERNS.md` § 12) and the one closedness does not protect;
   a fixture set that only uses the conjunction form (`res.#X & {...}`) cannot
   see this failure class.

## The idiom

```cue
#PolicyRuleSchema: #ResourcePolicyRuleSchema | #NonResourcePolicyRuleSchema

#ResourcePolicyRuleSchema: {
    apiGroups!: [...string]
    resources!: [...string]
    verbs!: [...string]
    resourceNames?: [...string]
    nonResourceURLs?: _|_ // present -> not this form
}

#NonResourcePolicyRuleSchema: {
    nonResourceURLs!: [_, ...] & [...string]
    verbs!: [...string]
    apiGroups?:     _|_ // present -> not this form
    resources?:     _|_
    resourceNames?: _|_
}
```

`field?: _|_` means "if this field is present, this arm is a contradiction".
A contradiction eliminates the arm during disjunction resolution, before
closedness is consulted, so embedding cannot disable it. The arms stay closed
definitions; the required-field sets are unchanged; there are no defaults. The
only behaviour change is that a value mixing both forms is refused at `cue vet`
with `empty disjunction` instead of leaving the disjunction unresolved.

## Why absence cannot discriminate

CUE discards a disjunct only on a contradiction. A missing required field makes
a disjunct *incomplete*, never contradictory, so absence alone can never
eliminate the wrong arm. The only remaining eliminator is closedness: a value
carrying `apiGroups` contradicts a closed arm that does not declare it. That
works in the conjunction form (`res.#Role & {...}`), where closedness applies
to the unified value.

It does not work in the embedded form. When a component embeds the resource
(`{res.#Role, spec: ...}`), closedness is not applied to the embedder's own
fields, so neither arm is ever rejected and the disjunction stays unresolved
for every element.

Measured downstream effect (bisected 2026-08-28 in isolated CUE packages, then
on the fleet): `#RoleTransformer` fails with `unresolved disjunction` on a
plain `get pods` rule, and on paths that survive, the transformer's presence
guards (`r.apiGroups != _|_`) evaluate to `false` on the unresolved element, so
fields are **silently dropped** from the rendered output. Both `r.apiGroups !=
_|_` and `r.nonResourceURLs != _|_` are `false` on the same element: the
transformer cannot dispatch on a value the evaluator has not resolved, so no
transformer-side fix exists. This blocked rendering `istio_ambient`,
`cert_manager`, `metallb` and `k8up` while every catalog fixture passed, which
is exactly why rule 2 exists.

## Fixture recipe

The embedded-form fixture pins each rendered field by interpolation and is
checked with `cue eval -c`, because plain `cue vet` accepts an incomplete
value:

```bash
cd opm && cue eval -c -e '_testEmbeddedRoleTransformer' ./transformers
```

See `_testEmbeddedRoleComponent` / `_testEmbeddedRoleTransformer` and the
negative fixture `_testMixedRuleRefused` in
`opm/transformers/role_transformer.cue` for the reference shapes.

## References

- OpenSpec change `role-rule-disjunction` (proposal carries the measured
  before/after; design carries the candidate fixes that were rejected).
- Related but distinct: `docs/cue-guard-closedness-workaround.md` (an evaluator
  *regression* around closedness; this note is about closedness working as
  designed and being unavailable under embedding).
