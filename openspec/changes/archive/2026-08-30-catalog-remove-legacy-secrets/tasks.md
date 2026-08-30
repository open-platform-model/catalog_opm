Nine groups. Run `task vet` at the end of every group; a red vet means the group is not done. Groups 1 and 2 are safe warm-ups (no member changes). Total: about 3 hours.

## 1. Move the ConfigMap helpers (10 min)

- [x] 1.1 Cut `#ContentHash` and `#ImmutableName` (plus the `crypto/sha256`, `encoding/hex`, `list`, `strings` imports and their "Content Hash Helpers" WHY block) from `secret.cue`; paste verbatim into `configmap.cue`
- [x] 1.2 In `#ContentHash`'s doc comment, delete the "building block for `#SecretContentHash`" clause
- [x] 1.3 `task vet`

## 2. Delete the discovery pyramid (5 min)

- [x] 2.1 In `secret.cue`, delete the "Secret Discovery Pipeline" header, `#GroupSecrets`, `#AutoSecrets`, `#DiscoverSecrets`
- [x] 2.2 `task vet`

## 3. Cut the env path (30 min)

- [x] 3.1 `container.cue`: remove `from?: #Secret` from `#EnvVarSchema`; doc comment becomes "exactly one of value/fieldRef/resourceFieldRef"
- [x] 3.2 `container_helpers.cue`: delete the `if e.from != _|_` block in `#ToK8sContainer`, the `#instancePrefix` parameter of `#ToK8sContainer` and `#ToK8sContainers` (and `_prefix` forwarding), and the header comment lines about `#SecretLiteral` / `#SecretK8sRef` prefixing
- [x] 3.3 Remove the `#instancePrefix:` argument at the `#ToK8sContainer` / `#ToK8sContainers` call sites in `deployment`, `statefulset`, `daemonset`, `job`, `cronjob` transformers (three each). Leave the `#ToK8sVolumes` argument
- [x] 3.4 `task vet`

## 4. Rewire the volume path (15 min)

- [x] 4.1 `container_helpers.cue` `#ToK8sVolumes`, `vol.secret` branch: `res.#SecretImmutableName` becomes `res.#ImmutableName`; rewrite the WHY block above `#ToK8sVolumes` (inline secret volumes name through `#ImmutableName`; drop the `#SecretTransformer` identity claim)
- [x] 4.2 `_testToK8sVolumesSecretImmutable` golden: call `res.#ImmutableName`; both `_testToK8sVolumesSecret*` fixtures still render the same names
- [x] 4.3 `task vet`

## 5. Simplify the transformer (30 min)

- [x] 5.1 `secret_transformer.cue`: replace the `_baseName` block (both `opm-secrets` arms) with `"\(_relName)-\(_compName)-\(secret.name)"`; call `res.#ImmutableName`
- [x] 5.2 Replace the `_literals` comprehension and the `len(_literals) > 0` guard with `stringData: secret.data`
- [x] 5.3 Rewrite the WHY block and the transformer / `output` doc comments: no variant, `#SecretLiteral`, `#SecretK8sRef` or `opm-secrets` wording; doc comments at most 6 lines
- [x] 5.4 Add a `_test` fixture: context with instance name and namespace, one component with two string entries (one `immutable: true`), guards on `metadata.name`, `stringData`, `type`, `immutable`
- [x] 5.5 `configmap_transformer.cue`: rewrite the "Mirrors the secret-transformer convention" comment; then `task vet`

## 6. Delete the contract type (20 min)

- [x] 6.1 `secret.cue`: delete `#SecretImmutableName`, then `#SecretContentHash`
- [x] 6.2 Delete the "Secret Contract Type" header block, `#Secret`, `#SecretType`, `#SecretLiteral`, `#SecretK8sRef`, and the `schemas` import
- [x] 6.3 Narrow `#SecretSchema.data` to `[string]: string`; rewrite its doc comment (string data only, name from the map key, rendered as `{instance}-{component}-{name}[-{hash}]`)
- [x] 6.4 `git grep -n -i 'secretname\|\$opm\|\$dataKey\|SecretLiteral\|SecretK8sRef\|SecretImmutableName\|SecretContentHash\|opm-secrets\|AutoSecrets\|DiscoverSecrets\|GroupSecrets' -- opm docs README.md CLAUDE.md Taskfile.yml .tasks` shows only Kubernetes-native hits (`secretName` on external volume refs, `secretRef`, `imagePullSecrets`)
- [x] 6.5 `task vet`

## 7. Cross the major (15 min)

- [x] 7.1 `opm/cue.mod/module.cue`: `module: "opmodel.dev/catalogs/opm@v3"`; `opm/identity/identity.cue`: `ModulePath: "opmodel.dev/catalogs/opm@v3"`; `opm catalog version set 3.0.0 ./opm` writes `Version: "3.0.0"` (design D-A: core asserts the major of `Version` agrees with `ModulePath`; never hand-edit)
- [x] 7.2 Replace the `@v2` spellings in `CLAUDE.md`, `README.md`, `Taskfile.yml`, `.tasks/generate-index.sh`, `openspec/config.yaml` (`opm/INDEX.md` follows from `task generate:index`)
- [x] 7.3 `task tidy`; `cue.mod/module.cue` deps unchanged
- [x] 7.4 On the branch, `.tasks/branch-tag.sh "$(pwd)/opm" opm-` prints a `v3.0.0-0.dev.*` tag

## 8. Land the durable decisions (20 min)

- [x] 8.1 `CLAUDE.md` § Repository Rules and the commit-conventions table: `feat!:` on `opm` bumps the major and the module path; a major crossing is the sanctioned in-place correction of a beta member (design D-A). `openspec/config.yaml` Principle I: replace the "advances the alpha counter" sentence
- [x] 8.2 `docs/name-constraints.md` carve-out class 2: `#ImmutableName` names ConfigMap and hand-authored Secret objects; remove `#SecretImmutableName`
- [x] 8.3 `README.md`: one sentence that `@v3` ships no env-secret path until the 0013 replacement lands

## 9. Verify (15 min)

- [x] 9.1 `task generate:index`; review the removed and moved rows in `opm/INDEX.md`
- [x] 9.2 `task check`
- [x] 9.3 `opm catalog publish ./opm --dry-run` with the workspace `OPM_REGISTRY` mapping: every gate GO, zero refusals
- [x] 9.4 At archive time: `task enhancements:delivery:log` for 0013 D9 / D12; record the deviation in `enhancements/0013/README.md` § Deviations
