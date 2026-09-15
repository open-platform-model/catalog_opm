## Why

`opm` 4.3.0 renders `TransformerRegistration` claims with `apiVersion: opm.opmodel.dev/v1alpha1`. That group does not exist and never will: `opm-operator` owns the CRD, and its API group is the flat `opmodel.dev` that enhancement 0002 D5 chose, rejecting kind-specific and prefixed groups at the cost of a full cluster migration. The operator shipped the CRD as `opmodel.dev/v1alpha1` (`opm-operator` PR 133), so the renderer currently emits an object no cluster can accept.

The prefixed spelling was never a decision. It entered through the pre-drafted shape at `enhancements/0015/contracts/contracts.cue:145` and was implemented from there; D3, D9 and D12 name the kind, its scope, its RBAC gate and its name shape, and none of them names a group.

## What Changes

- `opm/transformers/transformer_registration_transformer.cue`: the rendered `output.apiVersion` literal, `opm.opmodel.dev/v1alpha1` → `opmodel.dev/v1alpha1`.
- The same file's golden fixture `_testTransformerRegistrationOutput`, which asserts the rendered object byte for byte and fails `cue vet` on any drift. Both move together or neither moves.
- The `WHY` comment block above the transformer gains the reason the group is the operator's and not this catalog's, so the next author does not re-derive a prefixed one.

Not breaking. `#TransformerRegistrationResource`'s schema is untouched: no field moves, narrows or disappears, and no member changes `apiVersion` segment.

## Before / After

**Before**

```cue
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	#transform: {
		output: {
			apiVersion: "opm.opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			// metadata and spec unchanged
		}
	}
}

// Golden fixture
_testTransformerRegistrationOutput: {
	apiVersion: "opm.opmodel.dev/v1alpha1"
	kind:       "TransformerRegistration"
}
```

**After**

```cue
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	#transform: {
		output: {
			apiVersion: "opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			// metadata and spec unchanged
		}
	}
}

// Golden fixture
_testTransformerRegistrationOutput: {
	apiVersion: "opmodel.dev/v1alpha1"
	kind:       "TransformerRegistration"
}
```

## Impact

**Release class: `fix:`** — `opm` 4.3.0 → 4.3.1. A changed transformer output is normally not additive (Principle I), but this member is `v1alpha1`, and enhancement 0010 D34 keys the promise to the level: alpha carries **no compatibility promise**, and a build may change a value without bumping. This is the case D34 exists for, and it is the same reasoning the contract's own change recorded when it shipped ("both sides are `v1alpha1`, which promises nothing, so they can still move together").

Downstream consumers, and what each does:

- **Subscribing platforms**: nothing. No platform subscribes to a provider catalog carrying this contract yet, because no provider catalog exists.
- **The `modules` fleet**: nothing. No module attaches `#TransformerRegistration` to a component; the contract shipped one day ago and has no author.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing. No fixture renders a registration.
- **`opm-operator`**: nothing to do — it already ships the CRD this change targets. Once 4.3.1 publishes, the two sides of the contract agree for the first time.

Nobody is reached because the rendered object has never been applicable anywhere: there is no cluster in which a `opm.opmodel.dev/v1alpha1 TransformerRegistration` could be created, so nothing can depend on the old literal. The migration cost is zero, which is the honest reason this is a `fix:` and not a major crossing.

Relies on the v2 alpha line: no. `opm` is on the v4 line and this change does not touch the module path.

## Enhancement

`enhancements/0015` D9 (the authoring surface: the contract and the transformer that renders the CR). This change corrects the group that slice emitted; it implements no new decision. Declared in `enhancement.yaml`.
