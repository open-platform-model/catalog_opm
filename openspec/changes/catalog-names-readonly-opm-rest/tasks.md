## 1. opm/transformers route transformers

- [ ] 1.1 `http_route_transformer.cue`: add `#ExposeTrait` to `requiredTraits` (D-A); `_name` reads `#component.#names.resourceName`; `backendRefs[].name` reads `#component.spec.expose.name`; add fixtures (none exist): a stub context, a component with `#Expose` and the route trait and `#instance`, an interpolation name guard, and a guard that `backendRefs[0].name` equals the Service transformer's `metadata.name` for the same stub.
- [ ] 1.2 `grpc_route_transformer.cue`: same as 1.1.
- [ ] 1.3 `tcp_route_transformer.cue`: same as 1.1.
- [ ] 1.4 `tls_route_transformer.cue`: same as 1.1.

## 2. opm/transformers/network_policy_transformer.cue

- [ ] 2.1 `metadata.name` reads `#component.#names.resourceName`; the fixture component (line 81) gains `#instance`; add `_testNetPolName` pinned to `"istio-istiod"` (only selector guards exist today).

## 3. Exact-name audit

- [ ] 3.1 `namespace`, `validating_webhook`, `mutating_webhook` (comments present), `crd`, `admission_policy`, `role` and `sa_helpers.cue:27` (comments missing): confirm every rendered `metadata.name` is authored; add the inline `// exact — <external contract>` comment where missing (D-B). No output change.

## 4. Durable decisions

- [ ] 4.1 `docs/name-constraints.md`: complete "Transformers read names, never derive them" (create it if the workloads slice has not landed) with the three carve-out classes, the cross-reference rule, and the label-copy rule (D-C).
- [ ] 4.2 `CLAUDE.md` Working Style, Naming bullet: one sentence pointing at the read rule and the label-copy rule.

## 5. Verification

- [ ] 5.1 `task check`.
- [ ] 5.2 `cue eval -c` over every name guard added (an incomplete guard is a fixture missing `#instance`).
- [ ] 5.3 Byte-identity: `cue export` one route fixture and the network policy fixture before and after and `diff`.
- [ ] 5.4 Sweep `modules/` for a route trait attached without `#Expose`; record the result in design.md Risks.
