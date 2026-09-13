## 1. cue.mod pins

- [x] 1.1 Bump `opmodel.dev/core@v2` to `v2.0.0-alpha.9` in `opm/cue.mod/module.cue` and `k8s/cue.mod/module.cue` via `task deps:update` from the workspace root (or `cue mod get opmodel.dev/core@v2.0.0-alpha.9` in each module root); `task tidy` leaves no further diff.
- [x] 1.2 Align the `opm` transformer fixtures with the projected `#context` core ships since `alpha.7` (design.md § Research & Decisions, "Crossing alpha.7"): `_testDeployRollingDefaultsComponent` takes the shared context's name, and the three selector / pod-label counts in `deployment_transformer.cue` and `pdb_transformer.cue` count the container wrapper's required `core.opmodel.dev/workload-type` label the projection now folds in. No member, transformer body or rendered output changes; `k8s` needs nothing.
- [x] 1.3 `task check` green, then commit `fix(deps): bump core to v2.0.0-alpha.9 in both catalogs`

## 2. opm/catalog.cue

- [x] 2.1 Add the imports per D-A and the `#resources`, `#traits`, `#blueprints` maps listing every member under `opm/resources/`, `opm/traits/` and `opm/blueprints/` per D-B (include `tra.#BackupTrait` and `tra.#BackupCommandTrait` if `backup-traits-alpha` has landed; it had not, so no `tra` alias yet); rewrite the header comment's "not enumerated here" paragraph.
- [x] 2.2 `cd opm && cue eval -e '[len(#resources), len(#traits), len(#blueprints)]' ./` matches the member counts from `grep -rhoE "^#[A-Za-z0-9]+: c\.#(Resource|Trait|Blueprint)" resources traits blueprints | wc -l` per kind (11 / 26 / 5), and `cue eval -e '#traits["opmodel.dev/catalogs/opm/traits/scaling@v1beta1"].metadata' ./` shows the stamped `modulePath` and `catalogVersion`.
- [x] 2.3 `opm catalog publish ./opm --dry-run` passes every gate (65 members, 26 postures, 38 compat comparisons, 0 refused); its only refusal is "already holds v4.0.1", the one CI tolerates outside a release (CLAUDE.md § Release & publishing), so the exit is 2, not 0.
- [x] 2.4 `task check` green, then commit `feat(opm): list every resource, trait and blueprint in the catalog maps`

## 3. k8s/catalog.cue

- [x] 3.1 Add the `resources/v1` and `resources/v2` imports and the `#resources` map listing every member under `k8s/resources/` per D-B; leave `#traits` and `#blueprints` absent (D-D); rewrite the header comment.
- [x] 3.2 `cd k8s && cue eval -e 'len(#resources)' ./` matches the member count (29), and `opm catalog publish ./k8s --dry-run` passes every gate (58 members, 0 refused); as in 2.3 its only refusal is the tolerated "already holds v1.0.0-alpha.2", exit 2.
- [x] 3.3 `task check` green, then commit `feat(k8s): list every resource in the catalog map`

## 4. Listing gate and durable decisions

- [ ] 4.1 `.tasks/listing.sh` per D-C, run for `opm` and `k8s` by a new `task vet:listing`; wire it into `task check` after `vet:layering`. Verify it passes on the tree, and fails naming the key when one map entry is commented out.
- [ ] 4.2 `CLAUDE.md` Working Style: the listing rule beside the filing rule (design.md § Durable decisions), and the `vet:listing` row in the commands table.
- [ ] 4.3 `task check` green, then commit `chore(tasks): gate that every member is listed in its catalog maps`
