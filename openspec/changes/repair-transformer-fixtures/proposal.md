## Why

Every transformer in `opm/transformers/` carries a golden fixture in its own file, and that fixture set is this repo's only check on rendered output. Measured 2026-09-15 (cue v0.17.1, core `v2.0.0-alpha.9`): of the 47 rendered-output fixtures in the package, **44 fail `cue export`**, spread over **22 of the 23 transformer files**; only `pvc_transformer.cue` and the D9 registration transformer are clean. Core alpha.7 (enhancement 0019 D12) turned `#TransformerContext.#moduleInstanceMetadata` into a projection computed at the `#transform` site from `#moduleInstance`; 21 files still fill the projection directly, which leaves `#moduleInstance` at `_` so the output never becomes concrete, and `role_transformer.cue` supplies neither `#moduleInstance` nor `#runtimeName`. `cue vet` exits 0 on all of it, because an incomplete value is not an error, so `task check` and CI have been green over fixtures that compare nothing since 2026-09-01.

The rule is already written down (`CLAUDE.md` § Working Style, landed with the D9 registration contract) and the one working example exists. What is missing is the repair and a gate, so the class cannot come back silently.

## What Changes

- `.tasks/fixtures.sh` and `task vet:fixtures` (new): enumerate the RENDERED-OUTPUT fixtures under `<module>/transformers/` (fields declared `_testX: (#Y.#transform & {`, 47 of them today) and run `cue export -e <field>` on each, failing with the field name and CUE's own error. Component fixtures are deliberately out of scope: a component's attached primitives carry schemas, so many are legitimately non-concrete (measured: 92 of the 231 hidden `_test*` fields fail export, most of them for that reason). Wired into `task check` **last**, after the repair lands.
- The 21 files using the retired spelling: replace the `#context: {#moduleInstanceMetadata: …, #componentMetadata: …}` fill with `#moduleInstance: {metadata: {name, namespace, fqn, uuid}, #moduleMetadata: version}` plus `#context: #runtimeName`, and **re-pin each golden literal to what the transformer actually renders**. The component-derived labels move: `#context.componentLabels` now reads `#component.metadata.name`, so a fixture whose component carried no `metadata.name` renders a different `app.kubernetes.io/name` than its literal claims.
- `opm/transformers/role_transformer.cue`: supply both missing inputs, same re-pinning.
- **A golden literal that disagrees with the rendered output is a finding, not something to overwrite.** These fixtures have never been compared against reality, so a disagreement may be a real rendering defect. Triage each: a fixture wrong about a correct render is repaired here; a transformer wrong about a correct fixture is written up and fixed in its own change, named in this change's design.

Nothing published changes shape: every touched field is a hidden `_test*` fixture. `k8s/` has no transformers and is untouched.

## Before / After

**Before** (the retired spelling, `namespace_transformer.cue` and 20 siblings)

```cue
_testNamespacesTransformer: (#NamespaceTransformer.#transform & {
	#component: _testNamespacesComponent
	#context: {
		// Filled directly — but since core alpha.7 this is a PROJECTION of
		// #moduleInstance, which stays `_` here, so the output never becomes
		// concrete and the golden literal below compares nothing.
		#moduleInstanceMetadata: {
			name:      "test-instance"
			namespace: "metallb-system"
			fqn:       "opmodel.dev/catalogs/opm/test-instance@0.1.0"
			version:   "0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#componentMetadata: name: "namespace"
		#runtimeName: "opm-test"
	}
}).output
```

**After**

```cue
_testNamespacesTransformer: (#NamespaceTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "test-instance"
			namespace: "metallb-system"
			fqn:       "opmodel.dev/modules/test-instance@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	// The component supplies metadata.name, which is what the context's
	// componentLabels fold reads; the golden literal below is re-pinned to
	// the labels that actually render.
	#component: _testNamespacesComponent & {metadata: name: "namespace"}
	#context: #runtimeName: "opm-test"
}).output
```

## Impact

- **The `modules` fleet, `opm-modules`, and platforms subscribing to the catalog**: nothing. No member's shape, default or rendered output changes; only hidden fixture fields move. The exception is a transformer found genuinely wrong during triage, which does not land here.
- **`cli` fixtures under `testing.opmodel.dev`**: nothing. They pin their own catalog builds and carry their own fixtures.
- **CI**: gains `task vet:fixtures` inside `task check`. From then on a fixture that stops evaluating fails the build instead of passing quietly.
- **Release class**: `test:` for the fixture repairs and `chore:` for the gate, neither of which releases. If triage turns up a rendering defect, its fix is a separate `fix:` change with its own release.
- The change does not rely on the module still shipping the v2 alpha line.

## Enhancement

None. This is repo hygiene: the defect was found while implementing `enhancements/0015` D9 but implements no decision of it.
