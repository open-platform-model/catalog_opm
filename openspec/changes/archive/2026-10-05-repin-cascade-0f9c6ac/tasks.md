## 1. Pin and copy

- [x] 1.1 Move all five `open-platform-model/.github` references to `0f9c6ac2c9b752a79f4874f637ef9955bcf00c13 # .github main` (design D1); `grep -rn -A1 'open-platform-model/.github' .github/workflows` shows only the new SHA
- [x] 1.2 Prove `.tasks/cascade/wiring-check.sh` is the canonical file at the pin with `cmp` (design D2)
- [x] 1.3 Confirm the mirrored `.tasks/cascade/` files on `origin/main` hash to `mirror_sources catalog_opm` at the pin (design D3)
- [x] 1.4 `GH_TOKEN=$(gh auth token) bash .tasks/cascade/wiring-check.sh --pin-on-main` prints ok, actionlint exits 0, `CASCADE_TEST_SET=offline task -x deps:cascade:test` and `task check` green, then commit `ci(deps): pin the cascade to .github 0f9c6ac`

## 2. Verify and archive

- [x] 2.1 Run `openspec verify` for `repin-cascade-0f9c6ac` (the `opsx:verify` skill)
- [x] 2.2 Archive the change on this branch with `--skip-specs`
- [x] 2.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive repin-cascade-0f9c6ac`
