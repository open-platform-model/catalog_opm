## Why

Delete the legacy secret mechanism from `opm/` and release it as `opmodel.dev/catalogs/opm@v3` (3.0.0).

`opm-v2.0.0` shipped it broken: `#Secret` with `$opm` / `$secretName` / `$dataKey`, a 265-line `#DiscoverSecrets` walk nobody calls, and three Secret-name formulas that disagree. Enhancement 0013 replaces it with a `core`-owned `#Secret` resolved by the kernel. This change only removes (0013 D9: delete, do not deprecate). The replacement is a later change, after `core` publishes the new type.

## What Changes

**Removed (all in `opm/`)**

1. **BREAKING** `#EnvVarSchema.from` (typed `#Secret`) from `container@v1beta1`, with the env `secretKeyRef` dispatch in `container_helpers.cue` and the `#instancePrefix` parameter of `#ToK8sContainer` / `#ToK8sContainers` (its only reader). Fifteen forwarding sites in the five workload transformers go too. `#ToK8sVolumes` keeps its own `#instancePrefix`.
2. **BREAKING** `#SecretSchema.data` narrows from `[string]: #Secret | string` to `[string]: string` (0013 D12). `#SecretsResource` and `#Secrets` are otherwise byte-identical.
3. From `secret.cue`: `#Secret`, `#SecretType`, `#SecretLiteral`, `#SecretK8sRef`, `#SecretContentHash`, `#SecretImmutableName`, `#GroupSecrets`, `#AutoSecrets`, `#DiscoverSecrets`.
4. The `opm-secrets` special-case arm and the literal-vs-ref sniffing in `#SecretTransformer`. One formula stays: `{instance}-{component}-{name}[-{hash}]`. The transformer gains a `_test` fixture (it has none).

**Moved or kept**

1. `#ContentHash` and `#ImmutableName` (ConfigMap helpers filed in `secret.cue` by accident) move to `configmap.cue` unchanged.
2. Volume `secret` source (`#SecretVolumeSourceSchema`, `from!: #SecretSchema`) stays; it names through `#ImmutableName`. Rendered names unchanged.
3. **Major crossing**: `opmodel.dev/catalogs/opm@v2` becomes `@v3` (`cue.mod/module.cue`, `identity.ModulePath`, `identity.Version` -> `3.0.0` via `opm catalog version set`, docs). No member moves to a new `apiVersion` segment. Member fqns derive from the major-free `RegistryPath`, so no contract key changes.
4. Docs: `docs/name-constraints.md` names only `#ImmutableName`; `CLAUDE.md` and `openspec/config.yaml` stop calling `feat!:` an alpha-counter bump (stale since 2.0.0).

## Before / After

**Before**

```cue
// resources/v1beta1/container.cue
#EnvVarSchema: {
	name!:             string
	value?:            string
	from?:             #Secret
	fieldRef?:         #FieldRefSchema
	resourceFieldRef?: #ResourceFieldRefSchema
}

// resources/v1beta1/secret.cue
#Secret: #SecretLiteral | #SecretK8sRef
#SecretType: {$opm: "secret", $secretName!: schemas.#NameType, $dataKey!: string, $description?: string}
#SecretLiteral: {#SecretType, value!: string}
#SecretK8sRef: {#SecretType, secretName!: string, remoteKey!: string}
#SecretSchema: {
	name!:     string
	type:      *"Opaque" | ...
	immutable: bool | *false
	data: [string]: #Secret | string
}
#SecretContentHash: {...}   // normalises #Secret entries, then #ContentHash
#SecretImmutableName: {...} // baseName + content hash when immutable
#GroupSecrets: {...}
#AutoSecrets: {...}
#DiscoverSecrets: {...}     // 10-level $opm walk, no caller

// transformers/secret_transformer.cue
let _baseName = {
	if _compName == "opm-secrets" {out: "\(_relName)-\(secret.name)"}
	if _compName != "opm-secrets" {out: "\(_relName)-\(_compName)-\(secret.name)"}
}.out
let _k8sName = (res.#SecretImmutableName & {baseName: _baseName, data: secret.data, immutable: secret.immutable}).out
let _literals = {for _dk, _entry in secret.data { /* string | .value | skip k8sref */ }}
if len(_literals) > 0 { k8scorev1.#Secret & {metadata: name: _k8sName, stringData: _literals, ...} }

// transformers/container_helpers.cue (#ToK8sContainer)
#instancePrefix?: string
if e.from != _|_ { /* secretKeyRef from e.from.secretName/remoteKey or $secretName/$dataKey, prefixed */ }
```

**After**

```cue
// resources/v1beta1/container.cue
#EnvVarSchema: {
	name!:             string
	value?:            string
	fieldRef?:         #FieldRefSchema
	resourceFieldRef?: #ResourceFieldRefSchema
}

// resources/v1beta1/secret.cue
#SecretsResource: c.#Resource & {...}   // unchanged
#Secrets: c.#Component & {...}          // unchanged
#SecretSchema: {
	name!:     string
	type:      *"Opaque" | ...
	immutable: bool | *false
	data: [string]: string
}
// (nothing else in this file)

// resources/v1beta1/configmap.cue
#ContentHash: {...}    // moved verbatim
#ImmutableName: {...}  // moved verbatim

// transformers/secret_transformer.cue
let _k8sName = (res.#ImmutableName & {
	baseName:  "\(_relName)-\(_compName)-\(secret.name)"
	data:      secret.data
	immutable: secret.immutable
}).out
k8scorev1.#Secret & {metadata: name: _k8sName, stringData: secret.data, ...}

// transformers/container_helpers.cue (#ToK8sContainer)
// no #instancePrefix; env entries are value / fieldRef / resourceFieldRef only

// opm/cue.mod/module.cue, opm/identity/identity.cue
module:     "opmodel.dev/catalogs/opm@v3"
ModulePath: "opmodel.dev/catalogs/opm@v3"
Version:    "3.0.0" // opm catalog version set; core asserts VersionMajor == Major
```

## Impact

1. **Release class: `feat!:`**, cutting `opm-v3.0.0` (release-please `prerelease: false` at 2.0.0 bumps the major). Does not rely on the v2 alpha line; it closes it. The compat gate finds no `@v3` predecessor, so every member is "new at its key". A `@v2` release would be refused (`KindFieldRemoved` on `container`, `KindDomainNarrowed` on `secrets`). `branch-publish.yml` derives `v3.0.0-0.dev.*` from the new path.
2. **`modules` fleet (`main`, V2 staging, publish disabled)**: all pin `catalogs/opm@v2` at `v2.0.0-alpha.7`. Seven use the removed vocabulary and stop vetting; `modules-drop-legacy-secrets` handles them, then a re-pin to `@v3` once 3.0.0 is on GHCR. The `v1` branch pins `v1.x`, untouched.
3. **`cli` fixtures**: `tests/fixtures/valid/secrets-module` is removed by `delete-secrets-test-fixtures` (`test(fixtures)`). No `opm-operator` fixture uses the mechanism.
4. **Subscribing platforms**: re-pin to `@v3`; FQN subscriptions see no key change.
5. **Interim state**: `@v3` has no env-secret path until `core` publishes 0013's `#Secret`. Hand-authored Secrets (`#SecretsResource`, inline volume `secret`) keep working with string data.

## Enhancement

`enhancements/0013` D9 and D12. Record at archive: (a) this lands before `core`'s slice, not after; (b) the fleet is removed now and reintroduced under 0013, not migrated. It also closes the `opm-secrets` naming question `catalog-names-readonly-opm-rest` parked on 0019.
