## Context

Files touched. No contract member changes, and no `apiVersion` segment moves:

- `src/cue.mod/module.cue`: the `opmodel.dev/core@v2` pin, `v2.0.0-beta.3` to `v2.0.0-beta.4`. `language.version`, `cue.dev/x/k8s.io@v0` (`v0.12.0`) and `.opm-cli-version` (`v1.0.0-beta.8`) stay.
- `src/resources/v1alpha1/transformer_registration.cue`: `#PreBoundRegistration`, a constructor with no `fqn`, so not a catalog member (AGENTS.md, Listing). The doc comment of `#TransformerRegistrationResource.spec.transformerRegistration.provides` names the helper's fold and changes with it.
- `src/transformers/transformer_registration_transformer_fixtures.cue`: the six `_testPreBound*` fixtures.
- `docs/cue-guard-closedness-workaround.md` (Rule 2 example) and `src/INDEX.md` (regenerated).

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

Closedness, defaults and required fields: `#TransformerRegistration` and its resource do not change. `#PreBoundRegistration` swaps two definition fields for one. Closedness does not check definition fields, so the embedding rule (docs Rule 2) holds as before.

## Goals / Non-Goals

**Goals:**

- The next `opm` release is built on core beta.4 (owner decision j3, consumer pin), and every package and rendered-output fixture vets on it.
- One derivation of a catalog's provider set: core's `#Catalog.provides`. No fold of it stays in this repository (catalog_opm#155, library ADR-012).
- The set of contracts each existing `_testPreBound*` fixture registers stays the same.

**Non-Goals:**

- Keeping the old `#identity` / `#transformers` inputs as deprecated aliases (D-C).
- Anything in core, the library or the operator.

## Decisions

**D-A. Bump by hand, with exactly the cascade's edit.** In `src/`: `cue mod get opmodel.dev/core@v2.0.0-beta.4`, then one `cue mod tidy`, as `.tasks/cascade/cascade.sh` does. The diff MUST touch only the core line. The cascade itself stays in dry run, and it would also move `.opm-cli-version`. If a `deps/cascade` branch or another open PR that moves the core pin appears before this merges, the implementer MUST stop and report it instead of racing it.

**D-B. `#PreBoundRegistration` takes the provider catalog itself.**

```cue
// #TransformerRegistration pre-bound for a provider catalog: pass the
// catalog's own root value and the module authors no spec field. catalog and
// version come from its metadata, and provides is core's derived
// #Catalog.provides, so the claim cannot disagree with the catalog it names
// (0015 D11).
#PreBoundRegistration: #TransformerRegistration & {
	// The provider catalog's root package, e.g. k8up "opmodel.dev/catalogs/k8up@v1".
	#catalog: c.#Catalog

	spec: transformerRegistration: {
		catalog:  #catalog.metadata.modulePath
		version:  #catalog.metadata.version
		provides: #catalog.provides
	}
}
```

`#catalog` MUST be typed `c.#Catalog`, not an open struct. The type is what makes `provides` core's derivation: unification re-applies `#Catalog`'s `provides` constraint to the value passed in, so a hand-written `provides` that disagrees with the catalog's `#transformers` is a conflict (measured, below). An open struct would accept any list. The existing WHY blocks (no `fqn`, why opm cannot exercise this on itself, why it embeds) stay. The one about the fold is reworded to say that core derives the set, and that this repository must not fold it again.

The `provides` doc comment on `#TransformerRegistrationResource` changes "folding the list out of the provider catalog's transformers" to "reading the provider catalog's derived provides".

**D-C. Replace the inputs; do not keep deprecated aliases.** The helper is `v1alpha1` (0010:D34: alpha promises nothing) and has no caller in the workspace. Keeping `#identity` and `#transformers` beside `#catalog` would keep two sources for `catalog`/`version`, and would keep a bare transformer map that has no `provides` to read. That is the exact duplication #155 removes. A stale call fails loudly: `#catalog.metadata.modulePath` and `.version` stay unset, so `spec.transformerRegistration.catalog!` and `version!` are incomplete, and `cue export` of the render fails. Task 2.5 measures the exact message. The proposal's migration block is the note a provider author needs.

**D-D. Fixtures pin the set, built from synthetic catalogs.** Each of the six fixtures (trait, resource, neither, dedup, non-provider, multi) keeps its case and its golden set, but builds a `c.#Catalog` value instead of a bare map. Under `#Catalog`, `#transformers` keys MUST be `#ImplFQNType`, and each value MUST be a `#ComponentTransformer`. `requiredResources` values MUST be `#Resource`s, so the resource fixture's synthetic `{fulfilment: "provider"}` becomes a minimal `c.#Resource` with `fulfilment: "provider"`. One fixture-local helper supplies the boilerplate:

```cue
// src/transformers/transformer_registration_transformer_fixtures.cue (fixtures only)
_testPreBoundCatalog: c.#Catalog & {
	metadata: {modulePath: "opmodel.dev/catalogs/k8up@v1", version: "1.0.0"}
}

_testPreBoundTransformer: {
	#name: string
	metadata: {
		name:        #name
		fqn:         "opmodel.dev/catalogs/k8up/transformers/\(#name)@1.0.0"
		description: "Synthetic provider transformer"
	}
	#transform: output: {}
}

_testPreBoundMultiComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#catalog: _testPreBoundCatalog & {#transformers: {
		"opmodel.dev/catalogs/k8up/transformers/backup@1.0.0": _testPreBoundTransformer & {
			#name: "backup"
			requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
		}
		"opmodel.dev/catalogs/k8up/transformers/command@1.0.0": _testPreBoundTransformer & {
			#name: "command"
			requiredTraits: (tra.#BackupCommandTrait.metadata.fqn): tra.#BackupCommandTrait
		}
	}}
}

// The same set as before; core sorts it ('-' sorts before '@').
_testPreBoundMultiOutput: spec: provides: [
	"opmodel.dev/catalogs/opm/traits/backup-command@v1alpha1",
	"opmodel.dev/catalogs/opm/traits/backup@v1alpha1",
]
```

The fixture names MUST stay the `_test<Name>: (#<Transformer>.#transform & {` form that `task vet:fixtures` collects. The multi fixture's WHY block (order is insertion order) is replaced: the order is now core's ascending sort, and declaration order no longer matters. One more fixture, `_testPreBoundAgreesWithCatalog`, pins that the registration's `provides` equals its `#catalog.provides` for the multi case. If someone reintroduces a local fold that drops the sort, this fixture fails.

## Research & Decisions

### Spike: the bump and the new helper

**Context**: D-A assumes beta.4 vets `opm` clean. D-B assumes that a `c.#Catalog`-typed input accepts both an imported catalog root and a synthetic one, and refuses a disagreeing `provides`.
**Explored**: 2026-10-05, cue v0.17.1, a scratch copy of `src/` at `origin/main` 0560990:
- `cue mod get opmodel.dev/core@v2.0.0-beta.4` and `cue mod tidy` changed only the core line. `cue vet ./...` and `cue vet -t fixtures ./...` passed.
- With D-B applied and a synthetic two-transformer `c.#Catalog`, the registration transformer's output `spec` exported `provides: [".../backup-command@v1alpha1", ".../backup@v1alpha1"]`, `catalog: "opmodel.dev/catalogs/k8up@v1"` and `version: "1.0.0"`.
- `#catalog: c.#Catalog & {metadata: {...}, provides: [".../traits/backup@v1alpha1"]}` (no transformers) failed with `provides: incompatible list lengths (0 and 1)`.
- A scratch package importing `opm "opmodel.dev/catalogs/opm@v4"` and passing `#catalog: opm` exported `catalog: "opmodel.dev/catalogs/opm@v4"`, `version: "4.6.0"`, `provides: []`.
- The current fixtures, run against D-B unchanged, fail (`incompatible list lengths (0 and 1)` on their goldens). They must be rewritten (D-D).
**Decision**: D-A to D-D as written. No assumption is left unmeasured, so section 1 is not a spike.
**Rationale**: the stale-call failure message (D-C) is the only thing not measured, and it does not decide anything. Task 2.5 records it.

### Reading `provides` versus keeping the fold beside it

**Context**: catalog_opm#155 offered an interim option: keep the fold and pin it equal to `#Catalog.provides` with a fixture.
**Explored**: the archived change `2026-10-05-republish-on-core-provider-set` deferred #155 because `#PreBoundRegistration` took a bare map with no `provides` to read. Changing the input removes that obstacle.
**Decision**: read `#catalog.provides` and delete the fold. The equality fixture in D-D guards against a fold coming back.
**Rationale**: a fold pinned equal to core's still has to be maintained. The issue's end state is "delete the local fold", and the pin is past beta.3.

## Risks / Trade-offs

- A provider module outside the workspace calls the old inputs. -> Its render fails on incomplete `catalog`/`version` (D-C), not with a silent empty claim. The proposal carries the migration. `v1alpha1` permits the break (0010:D34).
- `provides` order changes in rendered `TransformerRegistration` objects. -> opm-operator sorts both lists before comparing (`internal/controller/transformerregistration_contracts.go`). A provider re-render is therefore an in-place spec reorder, and acceptance does not change.
- The publish compatibility gate could treat the helper change as a violation. -> `#PreBoundRegistration` has no `fqn`, so the member gate does not see it, and `v1alpha1` is alpha-exempt. Task 2.6 runs `opm catalog publish ./src --dry-run`; anything other than the known `already holds` refusal stops the change and is reported.
- Typing `#catalog: c.#Catalog` re-unifies the whole provider catalog with `#Catalog`. -> The value already embeds `#Catalog`, so the unification is idempotent, and the spike export of the full `opm` catalog was immediate.

## Durable decisions

- "A catalog's provider set is core's `#Catalog.provides`. This repository reads it and never folds `requiredResources` / `requiredTraits` itself." It lands in `#PreBoundRegistration`'s WHY block, next to the code a future author would change (Principle II: the definition is the spec). The Rule 2 example in `docs/cue-guard-closedness-workaround.md` shows the `#catalog` form.
