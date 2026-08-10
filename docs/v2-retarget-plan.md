# Core v2 retarget plan — `catalogs-identity-authoring` (enhancement 0010)

This is the implementation plan for 0010's `catalogs-identity-authoring` slice as applied to this repo, plus the branch/release split that protects the v1 line. It exists because the ordering in 0010's plan (catalogs behind the library slices) forced the library to grow a fixture catalog; that was judged a regression, and the order is inverted: **this catalog moves to core v2 first, and the library re-points at it.** The deviation is recorded in 0010's history.

## Decisions applied

- **D5** — committed identity: `identity/identity.cue` carries the real `ModulePath` (major suffix included) and `Version`. The `0.0.0-dev` sentinel dies. The version stays a CUE *default* (`#VersionType | *"<real>"`) so the existing publish-time override still serves `-dev.*` branch tags; release-please owns the committed value via an `x-release-please-version` extra-files updater, so a checkout and a published release compute identical FQNs.
- **D1** — `metadata.modulePath` on the catalog is the full module path with major (`opmodel.dev/catalogs/opm@v2`); members declare major-free package paths via `identity.kindPrefix`.
- **D4/D21/D25** — every primitive is re-keyed: `apiVersion: "v1beta1"` (the contract level; alpha/beta levels are ungated per D34), `catalogVersion: id.Version` (provenance), authored `fqn` interpolated from the identity package. Transformers author `fqn` at the build version (`#ImplFQNType`) and carry **no** apiVersion (D44); their `modulePath`/`catalogVersion` are stamped by core's `#Catalog` pattern.
- **D42** — blueprints flatten: `src/blueprints/workload/*` → `src/blueprints/*`, package `workload` → `blueprints`, `modulePath` `…/blueprints`.
- **D36** — matching moves to `matchLabels`: the container resource declares the required `core.opmodel.dev/workload-type` key; the five workload blueprints answer it concretely. **Transitional duplication:** the `#Component` wrappers keep writing the same key into `metadata.labels`, because the library's matcher reads `metadata.labels` until 0010's `library-matching` slice flips the read. That slice deletes the duplication.
- **D46** — every trait states its optionality posture as a default. All current traits are advisory (`optional: bool | *true`): each modifies or augments a workload that renders without it, and none is a data-safety contract like `backup` (which this catalog does not declare). Revisit per-trait when a load-bearing one lands.

## Module and release lines

- **`main` = the v2 line.** `src/cue.mod/module.cue` flips to `opmodel.dev/catalogs/opm@v2` with `opmodel.dev/core@v2` (`v2.0.0-alpha.4`). First release: `2.0.0-alpha.1`. release-please keeps `versioning: prerelease` / `prerelease-type: alpha`; the breaking commit computes the major bump, and the module major agrees with the tag major at publish.
- **`v1` = the maintenance line** (branched from the last v1-line commit on main). Existing clusters pinning `opmodel.dev/catalogs/opm@v1` keep a release train. On that branch: `release.yml` triggers on `v1` with `target-branch: v1`; `branch-publish.yml` ignores `v1` (release-please owns it); `release-please-config.json` sets `versioning: always-bump-patch`, which **mechanically pins the line** — no commit type can cross a major. Maintenance fixes only.
- Publish flows are otherwise unchanged: release publish via `task publish` in the release workflow run; `-dev.*` prerelease tags from non-main branches via `task publish:branch` (branch-tag.sh derives the major from `cue.mod`, falling back to `2.0.0` until the first v2 release exists).

## Mechanical sweep (58 members, 61 files)

1. `identity/identity.cue`: real ModulePath with major, versioned default, `RegistryPath`, `kindPrefix` map (one prefix per kind, D42).
2. All imports: `opmodel.dev/core@v1` → `opmodel.dev/core@v2`; blueprint imports `…/blueprints/workload` → `…/blueprints`.
3. Every member metadata block: `modulePath: "\(id.ModulePath)/<kind>"` → `id.kindPrefix.<kind>`; `version: id.Version` → primitives get `apiVersion`/`catalogVersion`/`fqn`, transformers get `fqn` (v2 metadata is closed — a leftover `version:` is `field not allowed`).
4. Traits: add the `optional` posture; blueprints/resources: `matchLabels` per D36.
5. `task check` (fmt, vet against GHCR-resolved core v2, INDEX regeneration).

## Explicitly out of scope

- `opm catalog publish` and the publish gates (`#CatalogMemberFQNGate`, `#TraitOptionalGate`, `#IdentityPackage` unification) — 0011's `catalogs-publish-cutover`. Until then the gates are unenforced; the authoring here is written to satisfy them.
- `catalog_kubernetes` and `catalog_opm_experimental` — same slice, separate repos, not part of this change.
- `fulfilment: "provider"` declarations (D32) — no current member deliberately ships without a transformer.
- Removing the version-stamping machinery — still needed for `-dev.*` branch tags; retired by 0011.

## Downstream (the library re-point)

Once `2.0.0-alpha.1` is on GHCR, the library replaces its fixture catalog (`library/modules/opm_catalog`) with this catalog: `web_app` re-pins `opmodel.dev/catalogs/opm@v2`, `opm_platform` re-keys its subscription, flow tests drop the in-process disk registry for GHCR resolution, and `modules/opm_catalog` is deleted. Tracked in 0010's history.
