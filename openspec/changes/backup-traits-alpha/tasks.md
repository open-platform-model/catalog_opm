## 1. opm/transformers/pvc_transformer.cue

- [x] 1.1 Add `"volume.opmodel.dev/name": volumeName` to each PVC's `metadata.labels` by unification with `#context.labels` (D-A), with a `// WHY` block naming the selection rule and a doc comment within the 6-line cap.
- [x] 1.2 Add `_testVolumeLabel`: one component with two `persistentClaim` volumes rendered through `#PVCTransformer.#transform` with a minimal `#context` (the `_testEmbeddedRoleComponent` idiom in `role_transformer.cue`), pinning each PVC's `metadata.labels["volume.opmodel.dev/name"]` by interpolation; verify with `cue eval -c -e _testVolumeLabel ./transformers` from `opm/`.
- [x] 1.3 `task check` green, then commit `feat(transformers): label every PVC with its volume key`

## 2. opm/traits/v1alpha1

- [x] 2.1 `opm/schemas/common.cue`: add `#CronSchema` (five-field, D-D) with a doc comment.
- [x] 2.2 `opm/traits/v1alpha1/backup.cue` (new directory, `package v1alpha1`): `#BackupTrait`, `#Backup`, `#BackupSchema`, `#BackupRetentionSchema` per the proposal's After block and D-B; doc comments carry the keep-more rule for `method`, `excludes`, `maintenance` and the P1 dependency of `volumes`.
- [x] 2.3 `opm/traits/v1alpha1/backup_command.cue`: `#BackupCommandTrait`, `#BackupCommand`, `#BackupCommandSchema` per D-C (`optional: bool | *false`, no quote ban, `compensate` a shell line, `fileExtension?` without default); doc comments say which engine class reads `landing` and which reads stdout.
- [x] 2.4 `task generate:index`; review the two new trait rows and the schema row in `opm/INDEX.md`.
- [x] 2.5 `opm catalog publish ./opm --dry-run` exits 0 (both traits pass the member-FQN and trait-optional gates; the compatibility gate is off at alpha).
- [x] 2.6 `task check` green, then commit `feat(traits): add backup and backup-command at v1alpha1`

## 3. Durable decisions

- [x] 3.1 `docs/transformer-authoring.md`: the label-key rule, validation by unification with the measured `error()` behaviour, presence guards on component-derived fields, and the closed `componentLabels` idiom (design.md § Durable decisions).
- [x] 3.2 `CLAUDE.md` Working Style: the no-stub rule for provider-fulfilled members and one pointer line to the note, beside the closedness-workaround pointer.
- [x] 3.3 `task check` green, then commit `docs(opm): record adapter-authoring rules from the backup experiments`
