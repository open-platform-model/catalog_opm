## Why

`#PolicyRuleSchema` (`opm/resources/v1beta1/role.cue:37`) is `#ResourcePolicyRuleSchema | #NonResourcePolicyRuleSchema`, two closed shapes told apart only by which required field is absent (`apiGroups!`/`resources!` vs `nonResourceURLs!`). CUE discards a disjunct only on a contradiction; a missing required field is "incomplete", never a contradiction, so the only thing that can eliminate the wrong arm is closedness rejecting the other arm's field. When a module embeds the resource (`{res.#Role, spec: ...}`, the form at all 28 `#Role` sites in the fleet), closedness is not applied to the embedder's own fields, and the disjunction never resolves. Measured 2026-08-28/29 on cue v0.17.1 against alpha.6 and alpha.7: `#RoleTransformer` fails with `unresolved disjunction` on `rules[0].verbs` for a plain `get pods` rule, and the transformer's `r.apiGroups != _|_` guard evaluates to `false` on the unresolved element (fields silently dropped on any path that survives). Every catalog fixture uses the conjunction form (`res.#Role & {...}`), which is why `task vet` never saw it. It blocks rendering `istio_ambient`, `cert_manager`, `metallb` and `k8up`.

## What Changes

- `opm/resources/v1beta1/role.cue`: each arm refuses the other arm's discriminating fields outright with `field?: _|_`, so a rule contradicts the wrong arm on a **present** field and resolves regardless of authoring form. The transformer body is unchanged.
- `opm/transformers/role_transformer.cue`: one new fixture authored in the embedded form with a plain rule, a `resourceNames` rule and a `nonResourceURLs` rule, pinned by interpolation guards, plus a negative fixture proving a rule mixing both forms is refused.
- `docs/`: a new authoring note on struct disjunctions (arms MUST conflict on a present field; every transformer fixture set MUST include an embedded-form component), referenced from `CLAUDE.md`.

## Before / After

**Before**

```cue
#PolicyRuleSchema: #ResourcePolicyRuleSchema | #NonResourcePolicyRuleSchema

#ResourcePolicyRuleSchema: {
	apiGroups!: [...string]
	resources!: [...string]
	verbs!: [...string]
	resourceNames?: [...string]
}

#NonResourcePolicyRuleSchema: {
	nonResourceURLs!: [_, ...] & [...string]
	verbs!: [...string]
}
```

**After**

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

## Impact

- **Rendered output:** unchanged for every valid rule. A rule carrying both `apiGroups` and `nonResourceURLs` (already invalid in Kubernetes RBAC) is now refused at `cue vet` with `empty disjunction` instead of rendering non-concrete output.
- **Release class:** `fix(opm)`, no `apiVersion` segment move; relies on the v2 alpha line only in that it ships in the next alpha.
- **`modules` fleet:** no authoring change; `istio_ambient`, `cert_manager`, `metallb`, `k8up` start rendering through the kernel. **Subscribing platforms, `cli` fixtures:** nothing to do.

## Enhancement

None.
