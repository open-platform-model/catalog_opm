## 1. Core pin to v2.0.0-beta.3: src/cue.mod/

- [ ] 1.1 Gate check. Confirm core `v2.0.0-beta.3` is published (`cue mod get` resolves it with the workspace `CUE_REGISTRY`). Confirm no open catalog_opm PR moves the core pin: no `deps/cascade` branch on origin (`git ls-remote origin 'refs/heads/deps/*'`), and nothing in `gh pr list --state open` touches `src/cue.mod/module.cue`. If one does, stop and report it. Do not touch catalog_opm#145. Confirm `task check` is green on the base before the first edit; if it is red there, stop and report instead of fixing unrelated failures.
- [ ] 1.2 In `src/`: `cue mod get opmodel.dev/core@v2.0.0-beta.3`, then one `cue mod tidy` (design D-A). The diff must touch only the `opmodel.dev/core@v2` line. If tidy moves `cue.dev/x/k8s.io@v0`, revert that line and report it (the move would also need `KUBERNETES_VERSION` and `task generate:kinds`, AGENTS.md § Dependencies). Leave `.opm-cli-version` alone.
- [ ] 1.3 Re-vet on the new core: `task vet` (both views), `task vet:fixtures` (every rendered-output fixture exports) and `task vet:listing`. Confirm `cue eval -e provides ./src` prints `[]`, and that `cue export ./src` differs from `origin/main` only by `"provides": []`.
- [ ] 1.4 With the cli pinned in `.opm-cli-version` installed as CI installs it, run `opm catalog publish ./src --dry-run`. "Already published" is the only refusal CI accepts. Any compatibility violation stops the change and gets reported (design Risks).
- [ ] 1.5 `task generate:index:check` (`src/INDEX.md` should not change: no definition is added, removed or renamed), then `task check` green, then commit `fix(deps): move the opm catalog onto core v2.0.0-beta.3`

## 2. Pin the opm catalog's derived provides: src/

- [ ] 2.1 Re-run the 1.1 check for a core-moving PR. If one appeared, stop and report it.
- [ ] 2.2 Add `src/catalog_fixtures.cue` with `@if(fixtures)` above `package opm` and a package-level `provides: []`, plus the comment in design D-B (at most 6 lines). The file is not a top-level `_test*` field, so it needs no entry anywhere else.
- [ ] 2.3 Mutation check, reverted afterwards: add a stub transformer to `#transformers` in a scratch edit that requires `backup@v1alpha1` with `fulfilment: "provider"`, and confirm `task vet` fails on `provides`. Confirm that a plain `cue vet ./...` and `cue export ./src` do not include the assertion, i.e. the fixture file never ships.
- [ ] 2.4 `task check` green, then commit `test(catalog): pin the opm catalog's derived provides to empty`
