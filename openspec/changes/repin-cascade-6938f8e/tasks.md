## 1. Pin, copy and CI step

- [x] 1.1 Move all five `open-platform-model/.github` references to `6938f8e0247e019cb0c2db13fff5b7b558a6b67d # .github main` (design D1)
- [x] 1.2 Replace `.tasks/cascade/wiring-check.sh` with the canonical file at the pin and prove it with `cmp` (design D2)
- [x] 1.3 `ci.yml`: move "Verify the cascade wiring" above `Read the pinned opm CLI version` (design D3)
- [x] 1.4 `AGENTS.md` § Cascade pin: copy comparison and step-order rule (Durable decisions)
- [x] 1.5 `bash .tasks/cascade/wiring-check.sh --pin-on-main` prints ok, actionlint exits 0, `CASCADE_TEST_SET=offline task -x deps:cascade:test` and `task check` green, then commit `ci(deps): pin the cascade to .github 6938f8e`

## 2. Verify and archive

- [ ] 2.1 Run `openspec verify` for `repin-cascade-6938f8e` (the `opsx:verify` skill); confirm the Durable decisions landed in `AGENTS.md`
- [ ] 2.2 Archive the change on this branch with `--skip-specs`
- [ ] 2.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive repin-cascade-6938f8e`
