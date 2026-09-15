# Tasks: repair-transformer-fixtures

Four sections. Section 1 is the spike: it builds the gate and turns design.md's counts into a committed baseline before any fixture moves. The gate is wired into `task check` only in section 4, because wiring it earlier leaves `task check` red at every intermediate section boundary.

## 1. The gate, unwired

- [ ] 1.1 Add `.tasks/fixtures.sh <module-dir>`: enumerate fields declared `_test<Name>: (#<Transformer>.#transform & {` under `<module>/transformers/*.cue`, run `cue export -e <field> ./transformers` on each from the module root, and report every failure as `<file>: <field>` plus CUE's own first error line. Exit non-zero if any failed. Verify: run by hand over `opm` and it names 44 failing fixtures out of 47; `k8s` has no `transformers/` directory and exits 0.
- [ ] 1.2 Add `task vet:fixtures` fanning the script over `MODULES`, NOT yet in `task check`. Verify: `task vet:fixtures` fails today with the 44; `task check` is still green.
- [ ] 1.3 Record the baseline in design.md § Research & Decisions: the exact failing-fixture list as the script prints it, so section 2 and 3 can be checked off against a fixed target. Verify: the list has 44 entries across 22 files.
- [ ] 1.4 `task check` green, then commit `chore(tasks): add the rendered-output fixture gate, unwired`.

## 2. Repair the workload transformers

- [ ] 2.1 Repair `deployment_transformer.cue`, `statefulset_transformer.cue`, `daemonset_transformer.cue`, `job_transformer.cue` and `cronjob_transformer.cue` per design.md § The repair is mechanical: replace the `#context` fill with `#moduleInstance` plus `#context: #runtimeName`, then re-pin each golden literal against the actual `cue export`. Verify: `bash .tasks/fixtures.sh opm` reports no failure from these five files, and `cue vet ./...` still passes with the literals in place.
- [ ] 2.2 Triage every literal that had to change: a change explained by the projection (a label whose source moved) is the fixture being stale; anything else is a rendering defect. Record each defect in design.md § Findings with transformer, expected and actual bytes. Verify: design.md either carries a Findings section or states "None." for this batch.
- [ ] 2.3 `task check` green, then commit `test(transformers): repair the workload transformer fixtures`.

## 3. Repair the remaining transformers

- [ ] 3.1 Repair the other 17 files the baseline names, `role_transformer.cue` included (it supplies neither `#moduleInstance` nor `#runtimeName` and gains both). Same rule per file: export must succeed and vet must still pass. Verify: `bash .tasks/fixtures.sh opm` exits 0 — all 47 rendered-output fixtures evaluate.
- [ ] 3.2 Triage as in 2.2 and extend design.md § Findings. Verify: every literal that changed is either explained by the projection or recorded as a defect.
- [ ] 3.3 `task check` green, then commit `test(transformers): repair the remaining transformer fixtures`.

## 4. Wire the gate and land the durable decisions

- [ ] 4.1 Add `vet:fixtures` to `task check` after `vet:listing`, and add its row to the commands table in `CLAUDE.md`. Verify: `task check` runs it and stays green; reverting one repaired fixture to the old spelling makes `task check` fail naming that field.
- [ ] 4.2 `CLAUDE.md` § Working Style: replace the "Known breakage, not yet repaired" sub-bullet with the standing gate (`task vet:fixtures`, in `task check`), and state beside it that `cue vet`, including `-c`, does not check hidden fixtures while `cue export` does. Verify: no sentence in `CLAUDE.md` still claims fixtures are unrepaired.
- [ ] 4.3 `task check` green, then commit `chore(tasks): wire the fixture gate into check`.
