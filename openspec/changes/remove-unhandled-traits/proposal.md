## Why

`sizing@v1beta1` and `encryption@v1beta1` are listed in the catalog, but no transformer under `src/transformers/` requires or lists either. Both default to `optional: true`, so a module that attaches one renders nothing for it and gets only an advisory warning. `sizing` is the likeliest trap for a first user: a plausible name, an accepted schema, no effect (container resources already live on `container@v1beta1`). The catalog removes both before it is used with a GA toolchain.

## What Changes

- **BREAKING** Remove the trait `sizing@v1beta1`: `#SizingTrait`, the wrapper `#Sizing`, `#SizingSchema` and `#VerticalScalingSchema` (`src/traits/v1beta1/sizing.cue`, deleted).
- **BREAKING** Remove the trait `encryption@v1beta1`: `#EncryptionConfigTrait`, the wrapper `#EncryptionConfig` and `#EncryptionConfigSchema` (`src/traits/v1beta1/encryption.cue`, deleted).
- Remove both keys from `#traits` in `src/catalog.cue`.
- Add a fixture to `src/catalog_fixtures.cue` that fails when either key is in `#traits`.
- Regenerate `src/INDEX.md`; drop the two names from the author note in `docs/site/authoring/attach-a-trait.md`.
- No member moves to a new `apiVersion` segment. The traits are not replaced: there is no `v1beta2` of either.

Nothing else changes: no other trait, resource, blueprint or transformer, no pin, no rendered output.

## Before / After

**Before**

```cue
// src/catalog.cue
#traits: {
	(tr.#EncryptionConfigTrait.metadata.fqn): tr.#EncryptionConfigTrait
	(tr.#SizingTrait.metadata.fqn):           tr.#SizingTrait
	// ... 24 more v1beta1 traits, 2 v1alpha1 traits
}

// src/traits/v1beta1/sizing.cue
#SizingTrait: c.#Trait & {
	metadata: fqn: "\(id.kindPrefix.traits)/sizing@v1beta1"
	optional: bool | *true
	appliesTo: [res.#ContainerResource]
	spec: sizing: #SizingSchema
}
#Sizing: c.#Component & {#traits: (#SizingTrait.metadata.fqn): #SizingTrait}
#SizingSchema: {
	resources?:   res.#ResourceRequirementsSchema
	autoScaling?: #VerticalScalingSchema
}
#VerticalScalingSchema: {}

// src/traits/v1beta1/encryption.cue
#EncryptionConfigTrait: c.#Trait & {
	metadata: fqn: "\(id.kindPrefix.traits)/encryption@v1beta1"
	optional: bool | *true
	appliesTo: [res.#ContainerResource]
	spec: encryption: #EncryptionConfigSchema
}
#EncryptionConfig: c.#Component & {#traits: (#EncryptionConfigTrait.metadata.fqn): #EncryptionConfigTrait}
#EncryptionConfigSchema: {
	atRest:    bool
	inTransit: bool
}
```

**After**

```cue
// src/catalog.cue
#traits: {
	// ... the same 24 v1beta1 traits and 2 v1alpha1 traits; no sizing, no encryption
}

// src/traits/v1beta1/sizing.cue, src/traits/v1beta1/encryption.cue: deleted.

// src/catalog_fixtures.cue (@if(fixtures))
_testRemovedTraitsStayRemoved: [for k, _ in #traits if k == "\(id.kindPrefix.traits)/sizing@v1beta1" || k == "\(id.kindPrefix.traits)/encryption@v1beta1" {k}] & []
```

## Impact

**Migration.** There is nothing to move to: neither trait had an effect. A module that attached one deletes the embedding (`tr.#Sizing`, `tr.#EncryptionConfig`) and the `spec: sizing` or `spec: encryption` block. Container requests and limits are set where they already render, on the container (`spec: container: resources`). Nothing in OPM renders an encryption requirement; a module that needs one states it through the platform it runs on.

**What an author sees after the bump.** A module that still names a removed definition fails to evaluate with CUE's own error, before any render. The exact text is measured in design.md.

**Consumers.**

- The `modules` fleet, `opm-modules`, the `cli` fixtures under `testing.opmodel.dev`, `library` and `opm-operator`: none names either trait (workspace search, 2026-10-08). Nothing to do.
- Third-party modules and platforms pinned to `opmodel.dev/catalogs/opm@v4`: a module that attached either trait breaks at its next `cue mod tidy` or pin bump past this release, and is fixed as under Migration. A module that stays on its current pin is not affected.
- A platform that subscribes to the catalog: two fewer contract keys in `#traits`. No platform carried a transformer for either.

**Release class.** Removing a `v1beta1` member is a break by the catalog's own additive-only rule, and `AGENTS.md` types a removal `feat!:`. The owner decided otherwise for this change: it ships as a minor of `opm@v4` under an owner-signed exception to enhancement 0021:D7:R4 (swarm `simplifying-opm-v1`, `DECISIONS.md` 2026-10-08 20:00, "T9.12 a"), because the removed members never rendered anything and a `!` would make release-please propose 5.0.0 while the module path stays `@v4`. So:

- Section 1 commit: `feat(traits): ...`, no `!`, no `BREAKING CHANGE` footer.
- PR title: the same `feat(traits): ...` subject. It is the release note: release-please copies it into `CHANGELOG.md` under the next 4.x minor.

**Publish gate.** `opm catalog publish` compares each member of the new build against its predecessor; a member the new build no longer carries is not judged (cli `internal/publish/compat.go`, the scan iterates the next build's members). The removal therefore passes the compatibility gate without an override.

## Enhancement

None. The change implements no enhancement decision. It uses an owner exception to 0021:D7:R4 (above) and logs no delivery.
