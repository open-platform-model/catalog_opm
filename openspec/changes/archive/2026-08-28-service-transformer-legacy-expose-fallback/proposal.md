## Why

`opm-v2.0.0-alpha.6` (`feat(opm)!: declare name constraints and default the expose name`, #51) turned `#ExposeSchema.name` from `name?: string` into `name!: c.#ServiceNameType`, moved the default into the `#Expose` component wrapper, and removed the Service transformer's fallback: `metadata.name` became a bare `_expose.name` read. That is correct for a component built with the alpha.6+ wrapper and wrong for every component built against a published build ≤ alpha.5, whose `expose` carries `name?: string` with no value: the alpha.6/alpha.7 transformer refuses it with `output.metadata.name: cannot reference optional field: name`, and the module loses every Service. Measured 2026-08-28: `cli/tests/integration/module-apply/testdata` and `cli/tests/e2e/testdata/handoff` (catalog alpha.3) render on an alpha.3 platform and fail on alpha.6/alpha.7; the same module re-pinned to alpha.7 renders. This violates 0010 D27 ("inside one API version a contract is additive-only … a supplier at or above the build a module compiled against is unconditionally safe") without moving `apiVersion`, and the publish compat gate compared nothing (`39 prerelease-exempt`).

## What Changes

- `opm/transformers/service_transformer.cue`: `metadata.name` reads `_expose.name` when the component set or defaulted it, else the component's `#names.dns.short`, the same value the alpha.6+ wrapper defaults to. New-build components render byte-identically; ≤ alpha.5 components get the instance-scoped default they would have had after re-pinning.
- A `_testServiceLegacyExpose*` fixture in the same file: a hand-built component whose `expose` is the ≤ alpha.5 shape (`name?: string`, no value), with a resolution guard asserting the rendered name. `cue eval -c ./transformers -e _testServiceLegacyExposeResolves` refuses it on today's transformer (`cannot reference optional field: name`) and resolves after the change; plain `task vet` is vacuous on an unset optional reference (measured 2026-08-28), so the eval gate is the check.
- `docs/name-constraints.md` gains the rule: a transformer that reads a field whose posture changed within an `apiVersion` keeps a fallback for components compiled against earlier builds of that `apiVersion`, and pins it with a legacy-shape fixture.

- The same read, one seam: `opm/transformers/name_helpers.cue` gains `#ServiceName` (the `#WorkloadName` shape: `expose.name` when set, else `#names.dns.short`). Six readers go through it: the Service transformer (`metadata.name`), the StatefulSet transformer (`spec.serviceName`, whose alpha.5 inner `!= _|_` guard alpha.6 removed) and the four route transformers (`backendRefs[].name`, a read alpha.6 introduced; alpha.5 interpolated `<instance>-<component>`). Measured 2026-08-28: each of these refuses a ≤ alpha.5 component with the same `cannot reference optional field: name`, so a legacy stateful or routed component loses its StatefulSet or route as well as its Service. One helper is what guarantees the StatefulSet's `serviceName` and every `backendRef` name the Service that actually renders, for legacy and current shapes alike.
- Legacy fixtures: the Service one above; `_testSTSLegacyExpose*` (stateful legacy component with Expose, guard on `serviceName`); `_testHttpRouteLegacyExpose*` with the cross-reference guard against the Service transformer's output for the same stub. grpc/tcp/tls share `#ServiceName` and the http guard; they get no fixture of their own (the helper's own `_testServiceNameLegacy` guard pins the seam).

Not changed: `#ExposeSchema` (stays `name!`), the `#Expose` wrapper, the network-policy and other workload transformers (they read `#component.#names.*`, which core has carried since core alpha.4). No member moves `apiVersion`.

## Before / After

**Before**

```cue
// opm/transformers/service_transformer.cue
output: k8scorev1.#Service & {
	metadata: {
		name:      _expose.name
		namespace: #context.#moduleInstanceMetadata.namespace
		// ...
	}
}
```

**After**

```cue
// opm/transformers/service_transformer.cue
output: k8scorev1.#Service & {
	metadata: {
		// Service name: expose.name when the component set or defaulted it
		// (every build >= alpha.6 attaches through the #Expose wrapper), else
		// the component's own #names.dns.short, the value that wrapper
		// defaults to. The fallback is what keeps a component compiled
		// against a build <= alpha.5 (expose.name?: string, unset) rendering
		// on this transformer (0010 D27). List-index form: a default arm
		// would silently win over the concrete one.
		name: [
			if _expose.name != _|_ {_expose.name},
			#component.#names.dns.short,
		][0]
		namespace: #context.#moduleInstanceMetadata.namespace
		// ...
	}
}

// Fixture: a component compiled against a build <= alpha.5. expose carries
// name?: string with no value. #names is hand-set as the kernel would.
_testServiceLegacyExposeComponent: {
	#names: dns: short: "shop-web"
	metadata: name: "web"
	spec: {
		container: {name: "web", image: {repository: "nginx", tag: "1.27", digest: ""}, ports: http: {name: "http", targetPort: 8080}}
		expose: {
			type: "ClusterIP"
			ports: http: {targetPort: 8080}
			name?: string
		}
	}
}
_testServiceLegacyExposeResolves: "\(_testServiceLegacyExposeTransformer.metadata.name)" & "shop-web"
```

## Impact

- **Subscribing platforms**: move to the release carrying this fix (alpha.8) to render ≤ alpha.5 modules again (Service, StatefulSet `serviceName`, route `backendRefs`); alpha.6 and alpha.7 stay broken for those modules (tags are immutable).
- **`modules` fleet**: nothing; the fleet is on alpha.7 with the wrapper default and renders identically.
- **`cli` / `opm-operator` fixtures and testdata**: nothing to edit; `module-apply/testdata` and `handoff` (catalog alpha.3) start rendering once the platform they are rendered through subscribes to alpha.8.
- Release class: `fix(opm)` (patch on the v2 alpha line; relies on the module still shipping the alpha line). Not breaking: output for every component that rendered before is unchanged.
- Principle V: no new published surface; one fixture and one docs rule.

## Enhancement

`enhancements/0010` D27 (additive-only within an apiVersion, supplier-at-or-above safety) and `enhancements/0019` D22 (the Service name is the Expose trait's name field). This change restores D27 for D22's field without changing what D22 decided. `enhancement.yaml` declares both.
