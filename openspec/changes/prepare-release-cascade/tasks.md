## 1. Read the opm CLI pin from `.opm-cli-version` (no version change)

- [x] 1.1 Create the repo-root `.opm-cli-version` with the single line `v1.0.0-beta.2` and a trailing newline
- [x] 1.2 `.github/workflows/ci.yml`: delete the workflow-level `OPM_CLI_VERSION` and its comment (`:18-19`). In job `ci`, add the step `Read the pinned opm CLI version` (design D3) between `Clone the code` and `Install opm`
- [x] 1.3 `.github/workflows/branch-publish.yml`: delete `OPM_CLI_VERSION` and its comment (`:23-25`). In job `publish`, add the same step after `Clone the code`
- [x] 1.4 `.github/workflows/release.yml`: delete `OPM_CLI_VERSION` and its comment (`:15-17`). Add the same step in job `release-please`, after `Clone the code` (`:59`), and in job `publish-cue`, after `Clone the released tag` (`:144`)
- [x] 1.5 `grep -rn "OPM_CLI_VERSION:" .github/workflows/` prints nothing. `grep -c 'cat .opm-cli-version' .github/workflows/*.yml` counts 1 in ci.yml, 1 in branch-publish.yml and 2 in release.yml. `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/*.yml` exits 0
- [x] 1.6 `AGENTS.md` § Release & publishing: add a bullet. The opm CLI that CI and release install is pinned in `.opm-cli-version` only; no version literal goes under `.github/workflows/`; a bump is a `ci(deps)` commit, made by root `task deps:pins:opm-cli` (design, Durable decisions)
- [x] 1.7 `task check` green, then commit `ci: read the pinned opm CLI version from .opm-cli-version`

## 2. Bump the opm CLI to `v1.0.0-beta.4`

- [x] 2.1 Set `.opm-cli-version` to `v1.0.0-beta.4`, the only diff in this section
- [x] 2.2 Download the beta.4 `opm-linux-amd64.tar.gz` and `checksums.txt` into a scratch directory and verify the checksum, as `Install opm` does. Then run `opm catalog publish ./opm --dry-run` and `opm catalog publish ./k8s --dry-run` with `OPM_REGISTRY='opmodel.dev=ghcr.io/open-platform-model,registry.cue.works'`. Each may refuse only with "already holds" and "1 refusal" (the tolerance at `ci.yml:94`). Dry-run only, never a publish
- [x] 2.3 `task check` green, then commit `ci(deps): bump opm CLI to v1.0.0-beta.4`

## 3. G1 release-pin gate in `Validate catalog`

- [x] 3.1 `Taskfile.yml`: add `deps:release-check` (design D1). It fails on any `-0.dev.` anywhere in `<m>/cue.mod/module.cue` for each of `MODULES` (`grep -nE -- '-0\.dev\.'`, no `v: "` anchor), and on any tracked `cue.mod/local-module.cue`, naming the file
- [x] 3.2 `.github/workflows/ci.yml`, job `ci`: add the step `Release-pin gate (G1)` after `Install Task`, guarded by `if: startsWith(github.head_ref || github.ref_name, 'release-please--')`, running `task deps:release-check`, with the comment from design D1
- [x] 3.3 Negative check, local and uncommitted: set `opm/cue.mod/module.cue`'s core pin to `v2.0.0-0.dev.1790000000.gabc1234` and confirm `task deps:release-check` exits non-zero naming `opm`; revert. Create and `git add` an empty `k8s/cue.mod/local-module.cue` and confirm it fails naming that path; `git rm --cached` it and delete it. On the clean tree the task exits 0
- [x] 3.4 `AGENTS.md`: add a `task deps:release-check` row to § Build And Dev Commands, and a § Release & publishing bullet: G1 runs inside `Validate catalog` on `release-please--*` refs (pull_request or dispatched), what it refuses, and that it is a step, never its own job (design, Durable decisions)
- [x] 3.5 `task check` green, `task deps:release-check` green and `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/*.yml` exits 0, then commit `ci: add the release-pin gate to Validate catalog`

## 4. Skip branch publish on `deps/**`

- [ ] 4.1 `.github/workflows/branch-publish.yml`: add `'deps/**'` under `on.push.branches-ignore` next to `main` (design D4), with a one-line comment saying cascade bot branches never publish dev catalogs
- [ ] 4.2 `AGENTS.md` § Release & publishing: amend the `branch-publish.yml` bullet from "for non-main branches" to "for non-main branches except `deps/**` (release cascade bot branches)" (design, Durable decisions)
- [ ] 4.3 `go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.7 .github/workflows/*.yml` exits 0 (the check from 1.5). `task check` green, then commit `ci: skip branch publish on deps branches`

## 5. Archive

- [ ] 5.1 Archive the change on this branch (openspec archive), so the archive rides the implementing PR; never push to main (owner decision 2026-10-01, RELEASING.md, Owner settings)
- [ ] 5.2 `openspec validate --all --strict` green, then commit `chore(openspec): archive prepare-release-cascade`
