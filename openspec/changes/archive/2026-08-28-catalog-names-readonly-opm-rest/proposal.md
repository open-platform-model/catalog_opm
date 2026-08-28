## Why

After `catalog-names-readonly-workloads`, the seven workload transformers read the primary object's name from `#component.#names.resourceName`. Five more `opm/` transformers still interpolate `"\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)"` for their primary object: `http_route`, `grpc_route`, `tcp_route`, `tls_route` and `network_policy`. Each is a second authority for the same name, and enhancement 0019 D15 makes that a review-enforced rule rather than a habit. This slice finishes `opm/` and lands the authoring rule where future authors read it (Principle II: an archived change is never the only home of a rule).

## What Changes

- `http_route_transformer.cue`, `grpc_route_transformer.cue`, `tcp_route_transformer.cue`, `tls_route_transformer.cue`, `network_policy_transformer.cue`: `_name` (or the inline interpolation) becomes `#component.#names.resourceName`.
- Route `backendRefs[].name` today reads the route's own `_name`, which is only the Service's name while the Service keeps its default. It becomes `#component.spec.expose.name` (the Service's one authoritative name field, D22), and **`#ExposeTrait` moves from absent to `requiredTraits` on all four route transformers**: a route without a Service has nothing to point at, and today such a component silently renders a dangling `backendRef`. This is a matching change (a component with a route trait and no `#Expose` stops matching and is refused at render) and is the one non-neutral edit in this slice.
- Exact-name transformers are audited and left verbatim, with an inline `// exact — <contract>` comment at every authored-name site: `namespace`, `crd`, `validating_webhook`, `mutating_webhook`, `admission_policy`, `role`, `sa_resource` (whose name site is `sa_helpers.cue`). `service` already reads `expose.name` and is compliant. `configmap`, `secret` (content-hashed via `#ImmutableName` / `#SecretImmutableName`) and `pvc` (per-volume, prefixed) emit secondary names and stay derived (D15 carve-out).
- Fixtures: the four route transformers have none today and get one each (context, `#Expose`-attached component with `#instance`, name guard, `backendRefs` guard); `network_policy` gains `#instance` and a name guard (it has only selector guards today).
- Two authoring rules land in `docs/name-constraints.md` and one line in `CLAUDE.md`: transformers read primary identity, never derive it; no transformer copies `resourceName` into a label value (0019 D19: label values cap at 63 runes, the override ceiling is 253).

No member schema changes; no `apiVersion` segment moves.

## Before / After

**Before**

```cue
// http_route_transformer.cue (and grpc/tcp/tls siblings)
_name: "\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)"
output: {
	metadata: name: _name
	spec: rules: [{backendRefs: [{name: _name, ...}]}]
}

// network_policy_transformer.cue
metadata: name: "\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)"
```

**After**

```cue
// http_route_transformer.cue (and grpc/tcp/tls siblings)
_name: #component.#names.resourceName
output: {
	metadata: name: _name
	spec: rules: [{backendRefs: [{name: #component.spec.expose.name, ...}]}]
}

// network_policy_transformer.cue
metadata: name: #component.#names.resourceName
```

## Impact

- **Rendered output:** byte-identical for default-named components with `#Expose` (D16 makes `#names.resourceName` equal the old interpolation; `expose.name` defaults to `#names.dns.short`, the same string). For a component with an explicit `metadata.resourceName`, route and NetworkPolicy names now follow the override where they ignored it before; intended D15 behaviour, no shipped fixture or fleet module sets the override on such a component. `backendRefs.name` is correct rather than silently wrong when a Service is renamed through `expose.name`.
- **BREAKING (matching):** a component carrying a route trait without `#Expose` no longer matches the route transformer. Downstream cost: `grep` the `modules` fleet for route traits attached without `#Expose` before release; none is expected, since such a route never had a Service to reach.
- **Release class:** `feat!:` on the `opm` module for the `requiredTraits` change (advances the alpha counter, no major crossing, no `apiVersion` segment moves), riding the same alpha as the workloads slice; `docs:` for the rule text. Relies on the v2 alpha line: yes.
- **`modules` fleet, platforms, `cli` fixtures:** verify the route-without-Expose case is absent; otherwise no action.

## Enhancement

`enhancements/0019` D15 (second `opm/` slice: the non-workload primary-object reads and the review rule) and D19's label-copy rule as authoring text. `enhancement.yaml` declares D15; D19's code half is `catalog-names-readonly-k8s`.
