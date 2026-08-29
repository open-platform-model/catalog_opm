## Why

`#Secret` (`opm/resources/v1beta1/secret.cue:45`) is `#SecretLiteral | #SecretK8sRef`, the same shape as the `#PolicyRuleSchema` defect fixed in `role-rule-disjunction`: two arms distinguished only by which required field is absent (`value!` vs `secretName!`/`remoteKey!`). Measured 2026-08-29 (cue v0.17.1): a literal secret placed on a `#config` field typed `res.#Secret` and copied into an embedded component stays an unresolved disjunction, and the presence guards the secret transformer and `#ToK8sContainer` dispatch on (`_entry.value != _|_`, `e.from.secretName != _|_`) evaluate to `false`. The failure is silent: no Secret rendered and no `secretKeyRef` wired. Every module with a secret in `#config` (`apprise`, `fileflows`, and any module following `DESIGN_PATTERNS.md` 1 `schemas.#Secret`) is exposed once it renders through the kernel.

## What Changes

- `opm/resources/v1beta1/secret.cue`: `#SecretLiteral` refuses `secretName`/`remoteKey`, `#SecretK8sRef` refuses `value`, via `field?: _|_`. `#SecretType` and the `$opm` discriminator are unchanged.
- `opm/transformers/secret_transformer.cue` and `container_helpers.cue` fixtures: one embedded-form component with a literal secret and one with a k8s-ref secret, pinned by interpolation; a negative fixture for a secret that supplies both.
- `docs/struct-disjunctions.md` gains `#Secret` as its second worked case (note created by `role-rule-disjunction`; create it if this lands first).

## Before / After

**Before**

```cue
#Secret: #SecretLiteral | #SecretK8sRef

#SecretLiteral: {
	#SecretType
	value!: string
}

#SecretK8sRef: {
	#SecretType
	secretName!: string
	remoteKey!:  string
}
```

**After**

```cue
#Secret: #SecretLiteral | #SecretK8sRef

#SecretLiteral: {
	#SecretType
	value!:      string
	secretName?: _|_ // present -> not this form
	remoteKey?:  _|_
}

#SecretK8sRef: {
	#SecretType
	secretName!: string
	remoteKey!:  string
	value?:      _|_ // present -> not this form
}
```

## Impact

- **Rendered output:** unchanged for every valid secret. A secret supplying both `value` and `secretName` (contradictory: the transformer would both create and reference) is now refused at `cue vet`.
- **Release class:** `fix(opm)`, no `apiVersion` segment move.
- **`modules` fleet:** no authoring change; secret env wiring starts resolving for embedded components. **Platforms, `cli` fixtures:** nothing to do.

## Enhancement

None.
