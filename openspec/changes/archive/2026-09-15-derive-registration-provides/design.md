## Context

See `proposal.md` for motivation. One file in the `opm` module:

- `opm/resources/v1alpha1/transformer_registration.cue` — `#TransformerRegistrationResource`, fqn `.../resources/transformer-registration@v1alpha1`, and its `#TransformerRegistration` component wrapper. Already imports `opmodel.dev/core@v2` and the identity package.

Nothing else moves. No `apiVersion` segment changes, no member's schema changes, no `catalog.cue` entry changes, and the `k8s` module is not reached.

Two facts shape the design:

- **`opm` cannot exercise the fold on itself.** It carries two provider-fulfilled members (`traits/v1alpha1/backup.cue` and `backup_command.cue`, both `fulfilment: "provider"`), and by this repo's rule a provider-fulfilled member ships no transformer here — so no `opm` transformer requires one, and the fold over `opm`'s own `#transformers` yields an empty set. The helper is for a provider catalog to instantiate; `opm` only publishes it.
- **A definition without an `fqn` is not a member.** `.tasks/listing.sh` builds its expected set by grepping `fqn: "\(id.kindPrefix.<kind>)/…"` under each kind directory, so a helper carrying no `fqn` is invisible to `task vet:listing` and needs no `catalog.cue` entry.

## Goals / Non-Goals

**Goals:**

- A provider catalog's module authors no part of the claim except the catalog dependency version in its `cue.mod`.
- The claim's `provides` and what the operator re-derives from the published catalog agree by construction, so drift is unrepresentable rather than merely refused.
- The helper is inert for every existing consumer.

**Non-Goals:**

- Changing `#TransformerRegistrationResource`'s schema. `provides!` stays required.
- A fold over a *module's* components (the `#provides` surface for a future publish gate); different fold, no consumer.
- Anything operator-side. Its half of D11 shipped in alpha.19.

## Decisions

### The helper files beside the contract, not in `schemas/`

`opm/schemas/` is the natural-looking home for a non-member definition, and it is wrong here: no file in that package imports core, deliberately — `common.cue` mirrors `core.#NameType` locally with the comment "for use in the schemas package (which cannot import core)". The fold's identity fields want `c.#ModulePathType` and `c.#VersionType`, so placing it there would mean re-mirroring two more core types to avoid an import the file next door already has.

`opm/resources/v1alpha1/transformer_registration.cue` already imports core, and the helper is *about* the contract declared in that file. Filing them together keeps the contract and its ergonomic constructor in one place, and the listing gate ignores the helper because it carries no `fqn`.

**Alternative considered — a new `opm/registration/` package.** A clean namespace with no listing ambiguity, at the cost of a fourth import alias for consumers and a directory holding one definition. Not worth it while there is exactly one helper.

### Closed definitions intersect, so the helper embeds the component wrapper

The obvious spelling is a helper that sits beside the component wrapper and is unified with it at
the call site: `#TransformerRegistration & #PreBoundRegistration & {…}`. It does not evaluate.
Measured on cue v0.17.1, unifying two closed definitions closes the result to the INTERSECTION of
their allowed fields, so every field only one conjunct declares is refused:

```cue
#A: {a: int}
#B: {b: int}
x: #A & #B & {a: 1, b: 2} // x.a: field not allowed / x.b: field not allowed
```

Against the real values that is `_testPreBoundTraitComponent.metadata.name: field not allowed`
— `metadata` comes from `c.#Component` through `#TransformerRegistration` and the helper never
declares it. Adding a regular field to a closed definition by embedding an open literal
(`#C: #A & {b: int}`) is refused for the same reason.

So the helper **embeds** what it extends: `#PreBoundRegistration: #TransformerRegistration & {…}`.
One closed conjunct, nothing intersected, and everything the helper adds on top is either a
definition field (`#identity`, `#transformers`), a hidden field (`_providerSet`) — neither of which
closedness checks — or a `spec.transformerRegistration` field the resource already allows. The call
site gets shorter too: `res.#PreBoundRegistration & {metadata: name: …, #identity: …, #transformers: …}`.

**Alternative considered — publish the helper as a regular field** (`PreBoundRegistration: {…}`),
which is not closed and unifies beside the wrapper as originally written. Rejected: a non-definition
in a catalog package is an exported value that shows up in `cue export` output and reads as data
rather than as a schema, to buy back a spelling nobody needs.

### `#transformers` is typed openly, and the fold guards both demand maps

```cue
#transformers: [string]: _
```

The helper receives whatever map the provider catalog passes. Typing the values as `c.#ComponentTransformer` would be tighter, but the fold only reads `requiredTraits` and `requiredResources` and must tolerate a transformer declaring neither — hence the `!= _|_` guard on each before comprehending. That guard is load-bearing, not defensive: `transformer_registration_transformer.cue` itself declares `requiredTraits: {}` and a transformer may omit either field entirely.

Deduplication is through struct keys rather than a list-membership check: two transformers requiring the same provider-fulfilled contract must contribute one entry, and `(fqn): true` collapses them for free.

### `provides` stays required on the resource

The helper fills the field; it does not relax it. This matters because of the measured CUE behaviour this whole contract is defensive about — a missing required field is an *incomplete value*, not an error, so a claim can reach a cluster with `catalog` absent while `cue vet` stays green. The operator's CRD therefore carries its own `required`, and the catalog keeps `provides!` so the authored path is still constrained for anyone who does not use the helper.

### The fixture builds a synthetic provider transformer

`opm` has no transformer to fold over, so the golden fixture constructs one: a minimal value whose `requiredTraits` names `traits/backup@v1alpha1` (`fulfilment: "provider"`), asserted against a `provides` of exactly that FQN. The cases worth pinning are the ones a real provider catalog will hit — a transformer with only `requiredResources`, one with neither map, two transformers requiring the same contract, and a non-provider fulfilment that must not appear.

## Research & Decisions

### `opm`'s own transformer map folds to empty, by rule

**Context**: whether the helper can be exercised against this catalog's real data.
**Explored**: every `fulfilment:` occurrence under `opm/` — two hits, both provider-fulfilled traits at `v1alpha1`; `CLAUDE.md`'s rule that a provider-fulfilled member ships no transformer here and never a stub.
**Decision**: test with a synthetic transformer, and state in the helper's doc comment that it is for a provider catalog to instantiate.
**Rationale**: the rule is deliberate — a stub transformer in this catalog *is* a provider, so the first real one becomes the second and the match is ambiguous. That makes an empty fold the correct result for `opm` and means the fixture must supply its own input rather than borrow the catalog's.

### Unifying two closed definitions closes to their intersection

**Context**: whether the helper could sit beside `#TransformerRegistration` and be unified with it
at the call site, as the proposal's first draft had it.
**Explored**: measured on cue v0.17.1 — the reduced case above, then the five fixtures, which
failed with `metadata.name: field not allowed` and `metadata.resourceName: field not allowed`
before the helper embedded the wrapper.
**Decision**: the helper embeds `#TransformerRegistration`; the call site names one definition.
**Rationale**: closedness is not checked for definition and hidden fields, so everything the helper
contributes except the `spec` body is exempt anyway; embedding costs nothing and removes a conjunct
from every call site. Promoted to `docs/cue-guard-closedness-workaround.md` — it is a general CUE
authoring rule, not a fact about this contract.

### The listing gate keys on `fqn`, not on file location

**Context**: whether a non-member definition under `resources/v1alpha1/` would fail `task vet:listing`.
**Explored**: `.tasks/listing.sh` — the expected set comes from `grep -rhoE 'fqn: +"\\\(id\.kindPrefix\.<kind>\)/[^"]+"'` over the kind directory.
**Decision**: file the helper there; no `catalog.cue` entry.
**Rationale**: a definition with no `fqn` field contributes nothing to the expected set, so the diff against the listed keys is unaffected. Verified against the script rather than assumed from the directory convention.

## Risks / Trade-offs

- [A future reader adds an `fqn` to the helper and breaks `vet:listing`] -> the doc comment says why it has none; the gate fails loudly naming the extra key, so the failure is immediate and self-describing rather than silent.
- [The open `[string]: _` typing accepts a map that is not transformers at all] -> the fold then yields an empty `provides`, which the operator refuses against its own re-derivation naming both lists. Wrong input fails at acceptance with a named diagnostic rather than silently registering nothing; tightening the type is additive if a real misuse appears.
- [`provides` is ordered by insertion, not sorted, so reordering a catalog's `#transformers` map is a
  rendered-output change] -> harmless downstream: `opm-operator`'s `providesDrift` sorts both lists
  before comparing and says so. `_testPreBoundMultiOutput` pins the order so a change to it is a
  visible diff rather than a surprise.
- [The helper is published with no consumer] -> deliberate and cheap: an unused additive definition costs a doc-comment line in `INDEX.md`. The consumer is the first provider catalog, which cannot be written without it.

## Durable decisions

- **A non-member definition may live under a kind directory, because `vet:listing` keys on `fqn` rather than on location.** Lands as a line in `CLAUDE.md`'s Listing bullet — it is an authoring rule a future catalog author needs, and the current text reads as though everything under `<kind>/` must be listed.
- **A helper that extends a closed definition embeds it; it is never unified beside it.** Unifying
  two closed definitions closes the result to the intersection of their allowed fields (measured,
  cue v0.17.1). Lands as a second section in `docs/cue-guard-closedness-workaround.md`, beside the
  other closedness rule this repo has to author around.
- **A provider-fulfilled member's catalog folds to an empty provider set by rule.** Stays with the change: it is a consequence of the existing "ships no transformer here" rule already in `CLAUDE.md`, not a new rule.

## Open Questions

None.
