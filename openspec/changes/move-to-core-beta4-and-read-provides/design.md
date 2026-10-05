## Context

Files touched. No contract member changes, and no `apiVersion` segment moves:

- `src/cue.mod/module.cue`: the `opmodel.dev/core@v2` pin, `v2.0.0-beta.3` to `v2.0.0-beta.4`. `language.version`, `cue.dev/x/k8s.io@v0` (`v0.12.0`) and `.opm-cli-version` (`v1.0.0-beta.8`) stay.
- `src/resources/v1alpha1/transformer_registration.cue`: `#PreBoundRegistration`, a constructor with no `fqn`, so not a catalog member (AGENTS.md, Listing). The doc comment of `#TransformerRegistrationResource.spec.transformerRegistration.provides` names the helper's fold and changes with it.
- `src/transformers/transformer_registration_transformer_fixtures.cue`: the six `_testPreBound*` fixtures.
- `docs/cue-guard-closedness-workaround.md` (Rule 2 example) and `src/INDEX.md` (regenerated if the helper's first doc-comment sentence changes).

Core beta.4 changes, relevant here: the `#Catalog` member maps bind `metadata.fqn: K` to the key, and the component maps do the same through `#ResourceMap`, `#TraitMap` and `#BlueprintMap`. `#Catalog.provides` is unchanged from beta.3:

```cue
// core src/catalog.cue at v2.0.0-beta.4, inside #Catalog
let providerSet = {
	for _, tf in #transformers {
		if tf.requiredResources != _|_ {
			for fqn, req in tf.requiredResources if req.fulfilment == "provider" {(fqn): true}
		}
		if tf.requiredTraits != _|_ {
			for fqn, req in tf.requiredTraits if req.fulfilment == "provider" {(fqn): true}
		}
	}
}
provides: [...#ContractFQNType] & list.Sort([for fqn, _ in providerSet {fqn}], list.Ascending)
```

That is the same rule as `_providerSet`, plus a sort.

Closedness, defaults and required fields: `#TransformerRegistration` and its resource do not change. `#PreBoundRegistration` keeps its two definition inputs and swaps the hidden `_providerSet` for a hidden `_catalog`. Closedness does not check definition or hidden fields, so the embedding rule (docs Rule 2) holds as before.

## Goals / Non-Goals

**Goals:**

- The next `opm` release is built on core beta.4 (owner decision j3, consumer pin), and every package and rendered-output fixture vets on it.
- One derivation of a catalog's provider set: core's `#Catalog.provides`. No fold of it stays in this repository (catalog_opm#155, library ADR-012).
- The set of contracts each existing `_testPreBound*` fixture registers stays the same.
- The helper's call shape (`#identity`, `#transformers`) stays as it is. Neither owner decision h2 nor j3, nor #155, asks for a different input, and AGENTS.md classes removing a definition as `feat!`.

**Non-Goals:**

- Changing the helper's inputs (rejected below, "Reading `provides` from a new `#catalog` input").
- Anything in core, the library or the operator.

## Decisions

**D-A. Bump by hand, with exactly the cascade's edit.** In `src/`: `cue mod get opmodel.dev/core@v2.0.0-beta.4`, then one `cue mod tidy`, as `.tasks/cascade/cascade.sh` does. The diff MUST touch only the core line. The cascade itself stays in dry run, and it would also move `.opm-cli-version`. If a `deps/cascade` branch or another open PR that moves the core pin appears before this merges, the implementer MUST stop and report it instead of racing it.

**D-B. `#PreBoundRegistration` builds a `c.#Catalog` from its inputs and reads its `provides`.**

```cue
// #TransformerRegistration pre-bound for a provider catalog: pass the
// catalog's own identity package and its own #transformers map and the module
// authors no spec field. catalog and version come from the identity; provides
// is core's #Catalog.provides over those transformers, so the claim cannot
// disagree with the catalog it names (0015:D11).
#PreBoundRegistration: #TransformerRegistration & {
	#identity: {
		modulePath: c.#ModulePathType
		version:    c.#VersionType
	}
	#transformers: [string]: _

	let T = #transformers
	_catalog: c.#Catalog & {
		metadata: {modulePath: #identity.modulePath, version: #identity.version}
		#transformers: T
	}

	spec: transformerRegistration: {
		catalog:  #identity.modulePath
		version:  #identity.version
		provides: _catalog.provides
	}
}
```

Two measured details (cue v0.17.1, core beta.4):

- `metadata` spells out the two fields. `metadata: #identity` fails with `metadata.fqn: field not allowed`, because `#identity` is closed and `#Catalog.metadata` adds `fqn`.
- The `let T` alias is needed because inside `_catalog` the name `#transformers` resolves to `_catalog`'s own field.

`_catalog` re-applies `#Catalog`'s `#transformers` constraint to the map passed in. For the documented call site, a provider catalog's own `#transformers`, that is idempotent: the map already sits under the same constraint in its catalog. It also stamps each transformer's `metadata.catalogVersion` from `#identity.version` and `metadata.modulePath` from `#identity.modulePath`, so `#transformers` taken from a catalog other than `#identity` is a conflict (`metadata.catalogVersion: conflicting values ...`, task 2.5(b)). That keeps the 0015:D11 "cannot disagree" guarantee the helper's doc comment states.

The existing WHY blocks (no `fqn`, why opm cannot exercise this on itself, why it embeds) stay. The comment over the fold is replaced by one that states the durable rule: core derives the provider set, and this repository reads it and never folds it again. The `#transformers` input comment says it is typed openly because `_catalog` applies core's constraint.

The `provides` doc comment on `#TransformerRegistrationResource` changes "folding the list out of the provider catalog's transformers" to "reading core's derived #Catalog.provides over the provider catalog's transformers".

**D-C. The call shape does not change.** A caller that passes a catalog's identity and its `#transformers`, the documented shape, renders the same `catalog`, `version` and set of `provides` as before. Two things do change, and both are rendered-output or input changes inside `v1alpha1`, which the alpha level allows (0010:D34):

- `provides` is sorted ascending (core's `list.Sort`), where the fold emitted insertion order. opm-operator sorts both lists before comparing (`internal/controller/transformerregistration_contracts.go`), so acceptance does not change.
- A hand-built `#transformers` map that is not shaped like a catalog's (string keys that are not `#ImplFQNType`, or values that are not `#ComponentTransformer`s) is now refused with `field not allowed`. Only the fixtures in this repository built such maps.

**D-D. Fixtures keep their call shape and pin the set.** Each of the six fixtures (trait, resource, neither, dedup, non-provider, multi) keeps its case, its `#identity` and its golden set. Its `#transformers` map becomes catalog-shaped: each key is an `#ImplFQNType` and each value embeds `c.#ComponentTransformer`, through one fixture-local helper.

```cue
// src/transformers/transformer_registration_transformer_fixtures.cue (fixtures only)
_testPreBoundTransformer: c.#ComponentTransformer & {
	#name: c.#NameType
	metadata: {
		name:        #name
		fqn:         "opmodel.dev/catalogs/k8up/transformers/\(#name)@1.0.0"
		description: "Synthetic provider transformer"
	}
}

_testPreBoundMultiComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: {
		"opmodel.dev/catalogs/k8up/transformers/backup@1.0.0": _testPreBoundTransformer & {
			#name: "backup"
			requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
		}
		"opmodel.dev/catalogs/k8up/transformers/command@1.0.0": _testPreBoundTransformer & {
			#name: "command"
			requiredTraits: (tra.#BackupCommandTrait.metadata.fqn): tra.#BackupCommandTrait
		}
	}
}

// The same set as before; core sorts it ('-' sorts before '@').
_testPreBoundMultiOutput: spec: provides: [
	"opmodel.dev/catalogs/opm/traits/backup-command@v1alpha1",
	"opmodel.dev/catalogs/opm/traits/backup@v1alpha1",
]
```

The resource fixture's synthetic `{fulfilment: "provider"}` becomes a `c.#Resource & {fulfilment: "provider"}`, because `requiredResources` values MUST be `#Resource`s. The fixture names MUST stay the `_test<Name>: (#<Transformer>.#transform & {` form that `task vet:fixtures` collects. The multi fixture's WHY block (order is insertion order) is replaced: the order is now core's ascending sort, and an unsorted local fold coming back fails this golden. No separate "agrees with the catalog" fixture is added: it would compare `provides` with the value the helper assigns it from, which is a tautology.

## Research & Decisions

### Spike: the bump and the helper

**Context**: D-A assumes beta.4 vets `opm` clean. D-B assumes a `c.#Catalog` built inside the helper accepts the call shapes in use and derives the same set.
**Explored**: 2026-10-05, cue v0.17.1, a scratch copy of `src/` at `origin/main` 0560990:
- `cue mod get opmodel.dev/core@v2.0.0-beta.4` and `cue mod tidy` changed only the core line. `cue vet ./...` and `cue vet -t fixtures ./...` passed.
- With D-B applied and the fixtures as in D-D, `cue vet ./...` and `cue vet -t fixtures ./...` passed. The six goldens export the same sets as before, and the multi case exports `provides: [".../backup-command@v1alpha1", ".../backup@v1alpha1"]`.
- With D-B applied and the fixtures unchanged, vet fails with `_testPreBound*Component._catalog.#transformers.backup: field not allowed` (bare string keys, values not `#ComponentTransformer`). The fixtures must be rewritten (D-D).
**Decision**: D-A to D-D as written. Section 1 is not a spike.

### Reading `provides` from a new `#catalog` input

**Context**: a first draft of this change replaced `#identity` and `#transformers` with one input, `#catalog: c.#Catalog`, the provider catalog's own root value.
**Explored**: that form works, and refuses a hand-written `provides` that disagrees with its `#transformers`. It removes two definition fields of a published helper. A stale call (`#identity` and `#transformers`, no `#catalog`) passes `cue vet -t fixtures` and `cue vet -c` silently, because closedness does not check definition fields; only `cue export` of the render fails, with `spec.transformerRegistration.catalog: required field missing: modulePath`. A provider author's plain vet would never catch it. The D-B form keeps the inputs and gives the same "cannot disagree" guarantee (D-B, catalogVersion conflict).
**Decision**: keep the inputs (D-B).
**Rationale**: neither owner decision h2 nor j3 nor #155 asks for a new input; AGENTS.md classes removing a definition as `feat!`; and the break would surface only at render time.

### Reading `provides` versus keeping the fold beside it

**Context**: catalog_opm#155 offered an interim option: keep the fold and pin it equal to `#Catalog.provides` with a fixture.
**Explored**: the archived change `2026-10-05-republish-on-core-provider-set` deferred #155 because `#PreBoundRegistration` took a bare map with no `provides` to read. Building a `c.#Catalog` over that map inside the helper removes that obstacle without changing the input.
**Decision**: read `_catalog.provides` and delete the fold.
**Rationale**: a fold pinned equal to core's still has to be maintained. The issue's end state is "delete the local fold", and the pin is past beta.3.

## Risks / Trade-offs

- `provides` order changes in rendered `TransformerRegistration` objects. -> opm-operator sorts both lists before comparing (`internal/controller/transformerregistration_contracts.go`). A provider re-render is therefore an in-place spec reorder, and acceptance does not change.
- A provider that builds `#transformers` by hand rather than passing its catalog's map is refused. -> Only this repository's fixtures did; the documented call site passes the catalog's own map. `v1alpha1` allows it (0010:D34).
- The publish compatibility gate could treat the helper change as a violation. -> `#PreBoundRegistration` has no `fqn`, so the member gate does not see it, and `v1alpha1` is alpha-exempt. Task 2.6 runs `opm catalog publish ./src --dry-run`; anything other than the known `already holds` refusal stops the change and is reported.
- `_catalog` re-unifies the whole transformer map with `#Catalog`'s constraint. -> For a real catalog's map that is idempotent, and task 2.5(a) measures it on `opm`'s own map.

## Durable decisions

- "A catalog's provider set is core's `#Catalog.provides`. This repository reads it and never folds `requiredResources` / `requiredTraits` itself." It lands in `#PreBoundRegistration`'s comment, next to the code a future author would change (Principle II: the definition is the spec). The Rule 2 example in `docs/cue-guard-closedness-workaround.md` shows `_catalog` in place of `_providerSet`.
