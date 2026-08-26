## 1. opm/resources/v1beta1/container.cue

- [x] 1.1 Add the computed `#nameConstraint` on the `#Container` wrapper's container entry (list-index, plain compare on the re-declared component `matchLabels`), with its doc comment

## 2. opm/blueprints/v1beta1/stateful_workload.cue

- [x] 2.1 Add `#nameConstraint: c.#NameType` to `#StatefulWorkloadBlueprint` with a doc comment saying why it stays beside the container conditional

## 3. opm/traits/v1beta1/expose.cue

- [x] 3.1 Add `#nameConstraint: c.#ServiceNameType` to `#ExposeTrait`
- [x] 3.2 Change `#ExposeSchema.name` to required `c.#ServiceNameType` and rewrite its doc comment (always read, wrapper default, renames the Service only)
- [x] 3.3 Add the wrapper default on `#Expose` (`#names: _` re-declared, `spec: expose: name: *#names.dns.short | c.#ServiceNameType`)
- [x] 3.4 Reword the mirror sentence in `opm/traits/v1beta1/resource_name.cue`

## 4. opm/resources/v1alpha1/namespace.cue

- [x] 4.1 Document on `#NamespaceSchema.name` that the label rule is asserted by the wrapper (the field stays `string`; a type there kills the key default)
- [x] 4.2 Add `#nameConstraint: c.#NameType` to `#NamespacesResource` with a doc comment
- [x] 4.3 Assert the rendered names on the `#Namespaces` wrapper (`spec: _`, interpolated `_namespaceNamesFit`)

## 5. opm/transformers/service_transformer.cue

- [x] 5.1 Replace the list-index name with `_expose.name` and update the comment
- [x] 5.2 Add a concrete `#instance` to the three fixture components and a resolution guard for the default-named case
- [x] 5.3 Add a commented must-fail block recording the observed refusals: leading-digit `resourceName` on an Expose component, dotted `resourceName` on a raw stateful container, 64-rune `resourceName` on a `#StatefulWorkload`, dotted `spec.expose.name`, raw `#ExposeTrait` attachment

## 6. Durable decisions

- [x] 6.1 Write `docs/name-constraints.md` and add the one-bullet link in `CLAUDE.md` § Working Style for Agents

## 7. Verification

- [x] 7.1 `task generate:index`
- [x] 7.2 `task check`
- [x] 7.3 Fleet smoke: vet `modules/web_app` and `modules/istio_ambient` against this branch's catalog (local override, not committed) and diff the rendered Service names against `main`
