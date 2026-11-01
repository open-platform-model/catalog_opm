# OPM first-party catalog

The CUE module `opmodel.dev/catalogs/opm@v4`, rooted at `src/`. It instantiates the schema of `opmodel.dev/core@v2` into the published set of OPM Kubernetes building blocks that platforms and modules consume.

## Language

### The catalog and its parts

**Catalog**:
The published set of members, listed in one manifest and versioned as one release.
_Avoid_: Library, package, registry

**Catalog module**:
The one CUE module at `src/`. It holds every member and never has a sibling module.
_Avoid_: Repo, package, "the module" (unqualified)

**Member**:
A definition that carries an `fqn` and has an entry in the catalog map: a resource, a trait, a blueprint or a transformer. A definition without an `fqn` is not a member.
_Avoid_: Entry, item

**Catalog map**:
The four maps in the catalog manifest, `#resources`, `#traits`, `#blueprints` and `#transformers`, each keyed by the member's `fqn`. Listing a member here is what makes it visible to a platform.
_Avoid_: Index, registry, manifest list

**Index**:
The generated `INDEX.md` in `src/`, extracted from doc comments. It is output, not the catalog map.
_Avoid_: Catalog map, reference

**Platform**:
A consumer that subscribes to the catalog and renders components with its transformers.
_Avoid_: Cluster, environment

**Module**:
An OPM module, authored by an application team, that pins the catalog and demands contracts from it. Always say "catalog module" for the CUE module of this repo.
_Avoid_: Package, app, chart

### Members

**Resource**:
A `#Resource` member that a component declares it needs, such as a container, a config map or a volume. A resource a platform cannot handle refuses the render.
_Avoid_: Kubernetes resource, object, kind

**Trait**:
A `#Trait` member that modifies how a component behaves, such as scaling or an HTTP route. An unhandled optional trait is a warning, not a refusal.
_Avoid_: Option, feature, annotation, policy

**Blueprint**:
A `#Blueprint` member that composes resources and traits into a named workload shape, and answers the matching key a container needs.
_Avoid_: Template, preset, workload kind

**Transformer**:
A `#ComponentTransformer` member that turns a matched component into Kubernetes objects. It has no `apiVersion`, is evaluated once when a platform is built, and is keyed by the catalog build.
_Avoid_: Renderer, generator, controller

**Contract**:
A resource, trait or blueprint seen from the side of its consumers: the shape a module can demand and a platform must honour. The break unit of a contract is its `apiVersion`.
_Avoid_: Primitive, interface, API, spec

**Wrapper**:
A `#Component` definition such as `#Container` or `#StatelessWorkload` that pre-attaches members, so an author embeds it directly. Name and matching rules live on the wrapper when the member cannot compute them alone.
_Avoid_: Helper, preset

**Embedded form**:
A component written as an embedded struct of wrappers. Every transformer fixture set includes one, because a disjunction told apart by absence fails to resolve there.
_Avoid_: Inline component, flat form

### Identity and versioning

**fqn**:
The fully qualified name of a member, built from its kind prefix, name and version. A contract's `fqn` ends in its own `apiVersion`; a transformer's ends in the catalog `Version`.
_Avoid_: ID, key (a map key is the `fqn`, not a synonym for it), path

**apiVersion segment**:
The version directory a contract member files under, `src/<kind>/<apiVersion>/`, with the package clause equal to the segment. It never enters the `fqn` path.
_Avoid_: Version folder, release

**Identity**:
The package in `src/identity/` that holds the module path, the kind prefixes and the catalog `Version`. Only `opm catalog version set` writes the version.
_Avoid_: Metadata, version file

**Experimental candidate**:
A member filed at `v1alpha1`, where alpha promises nothing.
_Avoid_: Preview, beta feature

### Fulfilment

**Provider-fulfilled**:
A member with `fulfilment: "provider"`. The catalog lists it and ships no transformer for it, not even a stub.
_Avoid_: Unimplemented, stub, placeholder

**Catalog-fulfilled**:
A member with the default `fulfilment: "catalog"`. A transformer in this catalog renders it.
_Avoid_: Built-in, native

**Provider**:
An enabled registry entry of a platform, a catalog path with its major, whose transformers require a provider-fulfilled contract. A platform carries exactly one provider per such contract. The transformers of a provider are its adapters.
_Avoid_: Adapter (for the provider itself), plugin, backend, implementation

**Objects escape hatch**:
The `objects@v1alpha1` resource, which carries a Kubernetes object that no abstraction models, as written. It replaced the retired raw passthrough module.
_Avoid_: Passthrough, raw resource, k8s module

**Kind table**:
The generated table in `src/schemas/kinds/` that `objects@v1alpha1` dispatches on to validate built-in Kubernetes kinds. `tools/kindgen` generates it.
_Avoid_: Schema list, CRD table

### Matching and naming

**Match labels**:
The `matchLabels` of a member or blueprint, which a transformer's required labels select on. `core.opmodel.dev/workload-type` is the key this catalog introduces.
_Avoid_: Labels (the `metadata.labels` of a component are not matched on)

**Name constraint**:
The hidden `#nameConstraint` slot a member declares when its rendered name lands in a DNS label position. The component asserts its resolved name against the conjunction of all slots.
_Avoid_: Name validation, name rule

### Testing and delivery

**Fixture**:
A hidden `_test*` field in a `*_fixtures.cue` file that opens with `@if(fixtures)`. The rendered-output kind, the one `task vet:fixtures` exports, renders a transformer's output so that the golden literals are checked.
_Avoid_: Test, sample, example

**Golden literal**:
An expected value pinned in a fixture. It asserts presence only; absence needs a comprehension guard.
_Avoid_: Snapshot, expected output

**Durable decision**:
A decision a future catalog author needs, declared in a change's design and promoted to `docs/` or `references/` before archive.
_Avoid_: ADR, note

**Docs bundle**:
One of the two bundles that `docs-kit.cue` declares: `catalog-opm`, which docs-kit's `opm-docs` builds from the module as the catalog reference, and `catalog-opm-docs`, which holds the authored pages under `docs/site/`. The reference is built, never committed.
_Avoid_: Reference pages
