## 1. Pin and caller shapes

- [x] 1.1 Move all five `open-platform-model/.github` references to `7b9ad1bea132f7a3f053a5db61ac3933b59ee226 # .github main` (design D1)
- [x] 1.2 `deps-cascade.yml` `publish`: `&& inputs.gates_only != true` in `if:`, `gates-only: ${{ inputs.gates_only == true }}` on the `Publish` step (design D2)
- [x] 1.3 Replace `.tasks/cascade/wiring-check.sh` with the canonical file at the pin (prove with `cmp`), add `.tasks/cascade/wiring-check.yaml` (design D3)
- [x] 1.4 `ci.yml` "Verify the cascade wiring": `GH_TOKEN` env and `bash .tasks/cascade/wiring-check.sh --pin-on-main` (design D4)
- [x] 1.5 `bash .tasks/cascade/wiring-check.sh --pin-on-main` prints ok, actionlint exits 0, `CASCADE_TEST_SET=offline task -x deps:cascade:test` and `task check` green, then commit `ci(deps): pin the cascade to .github 7b9ad1b`

## 2. AGENTS.md

- [x] 2.1 `AGENTS.md` § Release & publishing and the command table: the canonical copy, its config, the `--pin-on-main` CI step and the gates-only switch (design Durable decisions)
- [x] 2.2 `task check` green, then commit `docs(agents): describe the canonical cascade wiring check`

## 3. Verify and archive

- [ ] 3.1 Run `openspec verify` for `bump-cascade-pin` (the `opsx:verify` skill); confirm the Durable decisions landed in `AGENTS.md`
- [ ] 3.2 Archive the change on this branch with `--skip-specs`
- [ ] 3.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive bump-cascade-pin`
