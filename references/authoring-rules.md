# Authoring rules for catalog members

Covers how to file, list, name and write a catalog member: version-segment filing, the listing rule, identity and version, name constraints, struct disjunctions, the `if` guard evidence, provider-fulfilled members, and the Kubernetes kind table behind `objects@v1alpha1`.

## Version-segment filing

- Contract members (resources, traits, blueprints; enhancement 0010) file under `src/<kind>/<apiVersion>/`.
- The package clause equals the version segment (`package v1beta1`). `metadata.modulePath` carries it: `"\(id.kindPrefix.resources)/v1beta1"`.
- The segment is derived from the member's own `apiVersion` and never enters the fqn. The key space stays flat: `.../resources/configmap@v1beta1`.
- Transformers file flat under `src/transformers/`, because they have no `apiVersion`.
- Consumers import a version package explicitly: `res "opmodel.dev/catalogs/opm/resources/v1beta1"`.
- Publish's member gate refuses a member whose `modulePath` is flat or names another segment. Nothing checks that the directory matches.
- Filing is half of a member's registration. The other half is its entry in the catalog map in `src/`, which the listing rule enforces.
- A contract's `apiVersion` moves only when that primitive's own shape breaks. The break unit is the member, so a broken shape moves to a new segment directory and is not changed in place. Experimental candidates go to `v1alpha1`: alpha promises nothing.

## Listing

- Every contract member is listed in the catalog's `#resources`, `#traits` or `#blueprints` map and every transformer in `#transformers`. Each key is `(pkg.#X.metadata.fqn)`, never a string literal.
- Use one import alias per version segment directory and group `v1alpha1` members last, in alphabetical order.
- Listing is what makes a contract visible to a subscribing platform (enhancement 0015, `#Catalog` publishes its contracts as members). A provider-fulfilled trait is therefore listed here and implemented nowhere here.
- `task vet:listing` diffs all four maps against the members filed under `src/<kind>/`, and fails naming the missing or extra key. Transformer keys are build-scoped, so they are compared with `id.Version` resolved. A new member's checklist gains the entry.

## Identity and version

- The identity package in `src/identity/` is the single source of the catalog's identity (enhancement 0010, identity lives in a committed file, located by schema path).
- `ModulePath` carries the full module path with major (`opmodel.dev/catalogs/opm@v4`). `kindPrefix` derives the per-kind package paths that every member's `metadata.modulePath` and authored `fqn` use.
- `Version` is committed as the real release version, as a CUE default. That is the shape `opm catalog version set` preserves byte for byte around the value. release-please decides the next version, and `release.yml` writes it onto the release PR through `opm catalog version set`.
- Transformers interpolate `Version` into their build-keyed fqn (`.../transformers/<name>@<version>`). Primitives key their fqn by their own `apiVersion` (`.../resources/<name>@v1beta1`), which a release does not move.
- Publishing goes through `opm catalog publish ./src` (enhancement 0011). It validates the identity package against core's `#IdentityPackage` and runs every publish gate: member FQN, trait posture, already-published, level-aware compatibility. It pushes the committed tree exactly, with no build directory and no version override.
- On a release the workflow passes `--version` as an assertion. Branch builds first stamp the `-dev.*` version into CI's working tree with `opm catalog version set`, a checkout write and never a commit.

## Name constraints and struct disjunctions

- A primitive whose rendered name lands in a DNS label position declares a `#nameConstraint`. A component wrapper that references `#names` (or a literal that references `matchLabels`) must re-declare the slot.
- A transformer reads the primary object's name from `#component.#names.resourceName` and never copies `resourceName` into a label value. The carve-outs are exact-name kinds, secondary names and cross-object references. `objects@v1alpha1` is an exact-name kind for every entry, its names as written. Rules and measured evaluator behaviour are in the name-constraints note in `docs/`.
- Struct disjunction arms must contradict each other on a present field (`other?: _|_`), never only on an absent required field. A disjunction told apart by absence never resolves for an embedded component. Every transformer's fixture set includes one embedded-form component (`{res.#X, ...}`). Idiom and measured behaviour are in the struct-disjunctions note in `docs/`.
- Transformer and adapter authoring is in the transformer-authoring note in `docs/`: the per-volume selection key, validation by unification rather than the `error` builtin, presence guards on every component-derived field, the closed-`componentLabels` idiom and the shared-security-context wiring rule.

## The `if` guard pitfall

- The hoisted form is `if ... { spec: <field>: ... }` at component level (the rule is in AGENTS.md).
- The in-spec form trips a CUE evaluator closedness regression ("field not allowed") present from `v0.17.0-alpha.2` onward and unfixed in `v0.17.1`, the version this repo's CI uses. See the closedness workaround note in `docs/`.

## Provider-fulfilled members

- A member declaring `fulfilment: "provider"` (enhancement 0010, a provider-fulfilled contract admits exactly one provider) is listed here and implemented elsewhere (the no-stub rule is in AGENTS.md).
- A platform carries exactly one provider of such a contract. A provider is an enabled registry entry (catalog path with its major, `opmodel.dev/catalogs/opm@v4`) whose transformers require it (core's specification, `#contracts.providedBy`). Two transformers of one entry are one provider; two majors of one catalog are two.
- Until a platform carries an adapter, attaching the contract refuses the render naming it (enhancement 0010, an unresolved primitive demand is an error). That refusal is the designed behaviour, not a gap to paper over.

## The escape hatch and the kind table

- A Kubernetes object that no abstraction models goes into a component as written through `objects@v1alpha1` (in `src/resources/v1alpha1/`). It validates a built-in kind against its closed `cue.dev/x/k8s.io` definition and passes any other kind open.
- It replaces the raw passthrough module `k8s@v1`, which this repo published from `k8s/` until 2026-10-02 (owner decision). That module is retired. Its last build is `1.0.0-beta.2`, and its published builds and `k8s-v*` tags stay resolvable. Do not reintroduce a second module or a passthrough member family.
- The kind table in `src/schemas/kinds/`, which `objects@v1alpha1` dispatches on, is generated by `tools/kindgen` from the pinned x/k8s.io and the OpenAPI spec of the Kubernetes release that x/k8s.io version is generated from (`v0.12.0` maps to `v1.36.0`). `tools/kindgen` is its own Go module and never ships.
- A bump of the x/k8s.io pin moves `KUBERNETES_VERSION` in `Taskfile.yml` and runs `task generate:kinds` (it downloads the spec) in the same PR.
- Pick the tag whose one-sided sets in kindgen's summary are empty or name only non-object kinds (Scale, APIGroup, APIVersions, Status). A long list means the wrong tag.
- The PR body names the kinds and group-versions the table gains or loses. A gained kind tightens validation of objects that passed open before. `v1alpha1` permits that, but a reviewer must see it.
- CI never runs the generator, only its offline unit tests (`task test:kindgen`). `cue vet` checks the committed table's keys against its schemas (a check file beside it).

## Pitfalls

- A string-literal key in a catalog map: use `(pkg.#X.metadata.fqn)`.
- Bumping the x/k8s.io pin without `KUBERNETES_VERSION` and `task generate:kinds`.
- Deriving the file location from the fqn: the segment never enters the fqn.

## Check before you finish

- [ ] `task vet:listing` passes and the new member is filed under its `apiVersion` directory.
- [ ] `metadata.modulePath` carries the version segment and the package clause equals it.
- [ ] A name in a DNS label position has a `#nameConstraint`.
- [ ] `task check` passes.
