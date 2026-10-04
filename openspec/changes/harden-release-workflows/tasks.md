## 1. Read-only CI workflows

- [x] 1.1 `ci.yml`: top-level `permissions: {}`, job `ci` gets `contents: read` and `packages: read`, checkout `persist-credentials: false` (design D2)
- [x] 1.2 `cascade-task.yml`: repo checkout `persist-credentials: false` (design D4)
- [x] 1.3 actionlint exits 0, `task check` green, then commit `ci: run the CI workflows with explicit read-only tokens`

## 2. Publishing workflows

- [x] 2.1 `release.yml`: top-level `permissions: {}`; `release-please` gets `environment: release` and `contents: read`, `packages: read`, `actions: write`; `publish-cue` gets `contents: read`, `packages: write`; `publish-cue` and `verify-published` checkouts `persist-credentials: false` (design D1)
- [x] 2.2 `branch-publish.yml`: top-level `permissions: {}`, job grants `contents: read`, `packages: write`; `release-please--**` in `branches-ignore`; setup-go `cache: false`; checkout `persist-credentials: false` (design D3)
- [x] 2.3 Re-grep `.github/workflows/` for `RELEASE_APP_PRIVATE_KEY` (only `release-please`, with `environment: release`), for workflows without `permissions:`, and for `cache` in publishing jobs
- [x] 2.4 actionlint exits 0, `task check` green, then commit `ci(release): grant each publishing job only what it uses`

## 3. Code owners, Dependabot and AGENTS.md

- [ ] 3.1 Add `.github/CODEOWNERS` (design D5)
- [ ] 3.2 Add `.github/dependabot.yml` for github-actions (design D6)
- [ ] 3.3 `AGENTS.md` § Release & publishing: the durable decisions of design.md, and drop "This repo has no Dependabot config"
- [ ] 3.4 `task check` green, then commit `ci: add code owners and Dependabot for actions`

## 4. Verify and archive

- [ ] 4.1 Run `openspec verify` for `harden-release-workflows` (the `opsx:verify` skill); confirm the Durable decisions landed in `AGENTS.md`
- [ ] 4.2 Archive the change on this branch with `--skip-specs`
- [ ] 4.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive harden-release-workflows`
