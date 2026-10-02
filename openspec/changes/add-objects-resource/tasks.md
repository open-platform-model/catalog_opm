## 1. Spike: the kernel carries `#scope`, and a platform build stays green

- [ ] 1.1 In a scratch copy of `opm/` (outside the repo), add the design's `#ObjectsResource`, `#ObjectSchema`, a hand-trimmed `#Table` (Deployment, ClusterRole) and `#ObjectsTransformer`, listed in `catalog.cue`
- [ ] 1.2 Build a scratch module with one `#Objects` component holding a Deployment and a ClusterIssuer with `#scope: "Cluster"`; render it with `opm module build` against a local replacement of the scratch catalog. Assert: the Deployment has the instance namespace, the ClusterIssuer has none, neither output carries `#scope`
- [ ] 1.3 Build a platform carrying the scratch catalog with no objects component (`opm platform check` on a generated platform directory) and assert it is green with the built-in-group refusal in place
- [ ] 1.4 Record both results in design.md (Research & Decisions); if either fails, rewrite D2 or D3 to the fallback named under Risks before section 2
- [ ] 1.5 Commit `docs(openspec): record the objects kernel spike`

## 2. `tools/kindgen/` and `opm/schemas/kinds/`

- [ ] 2.1 `tools/kindgen/`: Go module (`cuelang.org/go` v0.17.1) that loads every package of the `cue.dev/x/k8s.io` version pinned in `opm/cue.mod/module.cue`, keeps definitions with concrete `apiVersion` and `kind` (not ending in `List`), joins scope from the Kubernetes `v1.34.0` `api/openapi-spec/swagger.json`, and writes `opm/schemas/kinds/table.cue` sorted, with a generated-file header naming both inputs
- [ ] 2.2 Unit test for the scope join: a `/namespaces/{namespace}/` path wins over a cluster-wide list path; `/status` and `/scale` subresources are ignored
- [ ] 2.3 `task generate:kinds` in `Taskfile.yml`; run it and commit the table
- [ ] 2.4 `opm/schemas/kinds/check.cue`: assert every entry's schema carries its own keys as `apiVersion` and `kind`
- [ ] 2.5 `task check` green, then commit `feat(schemas): add the generated Kubernetes kind table`

## 3. `opm/resources/v1alpha1/objects.cue` and `opm/transformers/objects_transformer.cue`

- [ ] 3.1 `#ObjectsResource`, `#Objects` and `#ObjectSchema` per design D1 to D4, with the doc comment opening on the description and stating the 1.34 ceiling and the name-collision rule
- [ ] 3.2 Refuse `metadata.namespace` on a `Cluster` object; measure the refusal spellings for the built-in-group case and a missing `#scope`, and keep the clearest that holds under section 1's platform-build check
- [ ] 3.3 `#ObjectsTransformer` per D5
- [ ] 3.4 Fixtures: the three-object golden (Deployment, ClusterRole, ClusterIssuer), an author-set namespace kept, an embedded-form component (`{res.#Objects, ...}`, AGENTS.md Struct disjunctions), and one refusal fixture per case in design Research & Decisions; assert absence of `#scope` and of a namespace with the `] & []` guard
- [ ] 3.5 List the resource and the transformer in `opm/catalog.cue`
- [ ] 3.6 `task generate:index` and `task generate:reference`
- [ ] 3.7 `task check` green, then commit `feat(resources): add the objects resource`

## 4. Docs and durable decisions

- [ ] 4.1 Rewrite `docs/site/authoring/use-a-raw-kubernetes-resource.md` around `#Objects` from `opmodel.dev/catalogs/opm/resources/v1alpha1`: when to reach for it (step 1 forks stay), validation and the 1.34 ceiling, `#scope` for custom resources, names as written, no extra dependency or platform subscription
- [ ] 4.2 `docs/name-constraints.md`: add the `#ObjectsResource` row (names as written, slot top); AGENTS.md Naming bullet: name the carve-out
- [ ] 4.3 `docs/transformer-authoring.md`: new section, a definition field for OPM-only input read across packages
- [ ] 4.4 AGENTS.md Dependencies: regenerating the kind table on an x/k8s.io bump (which Kubernetes tag, and that the PR names the kinds added)
- [ ] 4.5 `task check` green, then commit `docs: document the objects resource`
