## Context

Files, in the order they are touched:

1. `opm/resources/v1beta1/secret.cue` (435 lines, about 55 survive) and `configmap.cue` (receives `#ContentHash` / `#ImmutableName`).
2. `opm/resources/v1beta1/container.cue` (`#EnvVarSchema`); `volume.cue` unchanged.
3. `opm/transformers/container_helpers.cue`, `secret_transformer.cue`, `configmap_transformer.cue` (one comment), and the five workload transformers (`#instancePrefix` forwarding only).
4. `opm/cue.mod/module.cue`, `opm/identity/identity.cue`, `opm/INDEX.md` (generated).
5. `docs/name-constraints.md`, `CLAUDE.md`, `README.md`, `Taskfile.yml`, `.tasks/generate-index.sh`, `openspec/config.yaml`.

`k8s/` is untouched: its `#SecretResource` / `#SecretSchema` / `#SecretTransformer` are the native passthrough and share only their names.

Four constraints decide the approach:

1. The compat gate is armed (2.0.0 is the first stable tag). It compares every beta member against its predecessor within the same major and has no override flag. A new major has no predecessor.
2. `#ContentHash` / `#ImmutableName` are ConfigMap helpers called from `configmap_transformer.cue:61` and `container_helpers.cue`; they must outlive the file's secret content.
3. `container_helpers.cue:496` is a `_test` golden that calls `res.#SecretImmutableName`. Real reference, not a comment.
4. `core` on `main` still ships the identical legacy block; no release carries 0013's `#Secret`. Nothing here may reference a `core` secret type.

## Goals / Non-Goals

**Goals**

1. No definition, field, comment, doc line or index row in `opm/` mentions `$opm` / `$secretName` / `$dataKey`, `#Secret`, `#SecretLiteral`, `#SecretK8sRef`, `#SecretType`, `#SecretContentHash`, `#SecretImmutableName`, `#GroupSecrets`, `#AutoSecrets`, `#DiscoverSecrets`, or `opm-secrets`.
2. `#SecretsResource` / `#Secrets` keep fqn, category, `spec` key shape and rendered names for string data.
3. One release, one major crossing, `task check` green after every task group.

**Non-Goals**

1. Adding the replacement (`from: c.#Secret`, a transformer reading `.ref` / `.key`). Follow-up, gated on a `core` release.
2. Changing the hand-authored Secret name to 0013 D6's `{instance}-{group}`. That formula belongs to the kernel-materialised path.
3. `#nameConstraint` / `#names` work: `#SecretsResource` declares no name slot and needs none.
4. Fixing the compat gate's blindness to deleted members (a `cli` issue, see Risks).

## Decisions

**D-A. Cross the major. Do not move members to `v1beta2`.**

Two beta members change shape: `container` loses a field, `secrets` narrows a domain. 0010 D4 says a broken shape moves to a new `apiVersion` segment. Here that means `container@v1beta2` plus five blueprints and two traits that embed `#ContainerSchema`, while `container@v1beta1` stays published with a `from` field typed against nothing. Chosen instead: `opmodel.dev/catalogs/opm@v3`, members corrected in place, `@v2` frozen on GHCR. The gate accepts it, only the module path changes (fqns derive from `RegistryPath`), and no broken shape is carried forward. Consumers re-pin a path either way.

```cue
// opm/cue.mod/module.cue
module: "opmodel.dev/catalogs/opm@v3"

// opm/identity/identity.cue
ModulePath: "opmodel.dev/catalogs/opm@v3"
Version:    "3.0.0"   // written by `opm catalog version set`, not by hand
```

**Corrected during implementation (2026-08-30).** This design first said `Version` could stay at `2.0.0` until the release PR, on the reading that core's `#IdentityPackage` does not relate `Version`'s major to `ModulePath`'s. **It does.** `core@v2.0.0-alpha.6/identity_package.cue:91` declares `VersionMajor: "v" + strings.SplitN(Version, ".", 2)[0]` and unifies it with `Major` on the next line, above a WHY block that defends the assertion explicitly. With `2.0.0` under a `@v3` path that unification is `"v2" & "v3"` = bottom, which propagates into `#CatalogMemberFQNGate.identity` and refuses **all 66 members** ("off its catalog's key space"). `task vet` stays green because it never instantiates the gate; `opm catalog publish ./opm --dry-run` refuses, and so would `ci.yml`'s per-PR dry-run, whose only tolerated refusal is already-published.

So the change carries `Version: "3.0.0"`, written with `opm catalog version set 3.0.0 ./opm` — 0011 D15's sanctioned writer, so the "never hand-edit" rule holds. `release.yml` re-runs the same writer on the release PR with the version release-please decides; `feat!:` at 2.0.0 with `prerelease: false` gives 3.0.0, and the command is a documented no-op when the value already matches. With `3.0.0` committed, the dry-run reports 66 members checked / 0 refused, 27 traits / 0 refused, compat 0 refused, GO.

`.tasks/branch-tag.sh` reads the major from `cue.mod/module.cue`, finds no `opm-v3.*` tag, and bases dev builds on `3.0.0`; `gateTagMajor` passes.

**D-B. One change, deletions in dependency order.**

The removed definitions form one reference chain: `#EnvVarSchema.from` and `#SecretSchema.data` reference `#Secret`; `#SecretImmutableName` references `#SecretContentHash`, which references the two arms; the transformer and the volume path reference `#SecretImmutableName`. Splitting across changes would publish an intermediate state that still carries part of the mechanism, and every intermediate state is breaking at `@v2` anyway. Task order: relocate helpers, drop the caller-free pyramid, cut the env path, rewire volume and transformer to `#ImmutableName`, delete the contract type and hash helpers, narrow `data`.

**D-C. `#SecretSchema.data` narrows to `string`; the resource keeps its formula.**

```cue
#SecretSchema: {
	name!:     string
	type:      *"Opaque" | "kubernetes.io/service-account-token" | ... | "bootstrap.kubernetes.io/token"
	immutable: bool | *false
	data: [string]: string
}
```

With string-only data, `#SecretImmutableName` and `#ContentHash` take the same input, so `#ImmutableName` renders the same names as today. The `opm-secrets` arm (`{instance}-{name}`) existed so the removed env path could find a cross-component object; with no reader it goes, and `{instance}-{component}-{name}` is the one formula. Closedness, defaults and required fields of `#SecretSchema` are unchanged; only the value domain of `data` narrows, which is what the major crossing pays for.

**D-D. `#instancePrefix` leaves the container helpers, stays on `#ToK8sVolumes`.**

Verified by read: inside `#ToK8sContainer` it is read only by the env `from` dispatch (`container_helpers.cue:76,82`). `#ToK8sVolumes` reads its own copy for configMap and PVC naming. The five workload transformers pass it at fifteen sites (three each); those arguments go, the `#ToK8sVolumes` ones stay. A parameter nothing reads is surface without a consumer (Principle V).

**D-E. `#ContentHash` / `#ImmutableName` move to `configmap.cue` verbatim.**

They are ConfigMap machinery filed in `secret.cue` by history. Moving them first keeps `secret.cue` deletable down to its resource and schema without a dangling import. `crypto/sha256`, `encoding/hex`, `list`, `strings` travel with them; `schemas` (used only by `$secretName!: schemas.#NameType`) is dropped.

## Research & Decisions

### Can a `@v2` release carry the removal?
**Context**: 2.1.0 was the first target.
**Explored**: `cli/internal/publish/compat.go` (`compatScan`, `eligibleByPackage`) and `library/opm/compat` `Check`, 2026-08-29. The walk iterates the new tree's beta/GA members, finds each by `(name, apiVersion)` in same-major predecessors (release prereleases included, dev tags excluded), refuses `KindFieldRemoved` / `KindDomainNarrowed`, exempts nothing on a stable line, and has no waiver flag. release-please with `prerelease: false` at 2.0.0 turns `feat!:` into 3.0.0.
**Decision**: major crossing (D-A).
**Rationale**: the same-major routes are a `v1beta2` cascade that keeps the broken shapes published, or deleting members outright, which the gate does not see and which is a larger break than the one it refuses.

### Blast radius of the removed helpers
**Context**: confirm nothing outside the secret chain depends on the deleted definitions.
**Explored**: two independent inventory passes over `git ls-files` (grep-driven; file-by-file read), 2026-08-29. `#GroupSecrets` / `#AutoSecrets` / `#DiscoverSecrets` / `#SecretContentHash` / `#SecretType`: no reference outside `secret.cue`. `#SecretImmutableName`: three callers (`secret_transformer.cue:68`, `container_helpers.cue:391`, golden `:496`). `#Secret`: `container.cue:142` and `#SecretSchema.data`. `opm-secrets`: `secret_transformer.cue` only. CHANGELOGs, `README.md`, `Taskfile.yml`, `.tasks/`, `.claude/skills/`, `openspec/config.yaml`: nothing. `.github/workflows`: only `secrets.GITHUB_TOKEN`.
**Decision**: the Context file list is complete; `k8s/` and `image_pull_secrets.cue` stay untouched.
**Rationale**: both passes agreed on every hit.

### `-dev` tag under a new major
**Context**: `branch-publish.yml` must not emit a `v2` dev tag on a `@v3` path.
**Explored**: `.tasks/branch-tag.sh` parses the major from `cue.mod/module.cue`, lists `opm-v<major>.*` tags, falls back to `<major>.0.0`.
**Decision**: no workflow change.
**Rationale**: a `@v3` path with no `opm-v3.*` tag yields `v3.0.0-0.dev.<ts>.g<sha>`.

## Risks / Trade-offs

1. Interim release with no env-secret path -> accepted by the user; `README.md` and the 3.0.0 release note say so; the replacement change is the next item on 0013's catalog slice.
2. Seven `modules` on `main` and the `cli` `secrets-module` fixture stop vetting -> each has its own change; the fleet re-pin waits for `opm-v3.0.0` on GHCR.
3. ~~`identity.Version` reads `2.0.0` under a `@v3` path until the release PR~~ -> **materialised, then closed.** Core asserts major agreement, so the split state refuses every member at the publish gate (see D-A). Resolved by committing `Version: "3.0.0"` through `opm catalog version set`; the rehearsal (`opm catalog publish ./opm --dry-run`) is green.
4. The compat gate never compares a member absent from the new tree -> not exercised here; recorded as a `cli` follow-up so the gap does not become a route later.
5. `CLAUDE.md` and `openspec/config.yaml` call `feat!:` an alpha-counter bump -> stale since the alpha line closed; corrected below. (`catalog.cue`'s `#transformers` map does not reflow: no key changes.)

## Durable decisions

1. "After `opm-v2.0.0` the alpha line is closed: `feat!:` on `opm` bumps the major and the module path (`@vN`); a major crossing is the sanctioned way to correct a beta member in place when a `v1beta(N+1)` cascade would keep a broken shape published" -> `CLAUDE.md` § Repository Rules and the commit-conventions table (replace "minor (pre-1.0)"), `openspec/config.yaml` Principle I (replace "advances the alpha counter").
2. "`#ContentHash` / `#ImmutableName` are ConfigMap helpers in `configmap.cue`; the content-hashed secondary-name class is `#ImmutableName` for ConfigMap and hand-authored Secret objects alike" -> `docs/name-constraints.md` carve-out class 2.
3. "Hand-authored Secret objects carry string data only and name as `{instance}-{component}-{name}[-{hash}]`; there is no special component name" -> doc comments on `#SecretSchema` and `#SecretTransformer` (the definition is the spec).
4. The env-secret gap and its follow-up -> stays with the change (release note, 0013 delivery log).
