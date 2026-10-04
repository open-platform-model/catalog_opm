## 1. Release backstop wording

- [ ] 1.1 `.github/workflows/release.yml`: in the `publish-cue` backstop comment (`:227-233`), replace "so this cannot fail" with the transient-registry-error sentence and "re-run this job" (design D1); no step changes
- [ ] 1.2 `AGENTS.md` § Release & publishing (the release-path bullet, `:230`): add the transient-error sentence and re-run recovery after the backstop sentence (design D1)
- [ ] 1.3 Same bullet: replace "the next release PR carries the fix" with the recovery rule. After a burned version the fix lands as a `feat`/`fix`/`perf`/`revert` commit touching `src/`, or no release PR opens; the `release-as` key alone does not open one (design D2). After a skipped version the next release PR's notes re-list every user-facing commit since `bootstrap-sha` (design D3)
- [ ] 1.4 `grep -n 'cannot fail' .github/workflows/release.yml AGENTS.md` prints nothing; actionlint exits 0 on `.github/workflows/release.yml`
- [ ] 1.5 `task check` green, then commit `ci(release): say when the fixture backstop can fail and how to recover`

## 2. What cue vet checks in hidden fields

- [ ] 2.1 Re-measure in a scratch copy of `src/` (never the worktree): a golden in `configmap_transformer_fixtures.cue` set to a conflicting value fails `cue vet -t fixtures ./...`; a fixture made incomplete passes both `cue vet -t fixtures ./...` and `cue vet -c -t fixtures ./transformers` while `cue export -t fixtures -e <field> ./transformers` fails. If either result differs from design D4, stop and record it in design.md before editing prose
- [ ] 2.2 `AGENTS.md`: the `task vet:fixtures` row (`:201`) and the Transformer fixtures bullet (`:300`) carry the design D4 claim
- [ ] 2.3 `Taskfile.yml` `vet:fixtures` desc (`:71-73`) and `.tasks/fixtures.sh` "WHY cue export" comment (`:18-20`) carry the design D4 claim
- [ ] 2.4 `src/transformers/role_transformer_fixtures.cue` comment above `_testUnboundClusterRoleSpec` (`:288-289`): "cue vet skips hidden fields" becomes "cue vet passes an incomplete hidden field"
- [ ] 2.5 `grep -rn -i 'does not check hidden\|descend into hidden\|skips hidden\|never looks inside hidden' --exclude-dir=archive --exclude-dir=.claude --exclude-dir=.cue-cache .` prints nothing outside `openspec/changes/`
- [ ] 2.6 `task check` green, then commit `docs: correct what cue vet checks in hidden fields`

## 3. Verify and archive

- [ ] 3.1 Run `openspec verify` for `reword-release-backstop` (the `opsx:verify` skill); confirm the Durable decisions landed in `AGENTS.md`
- [ ] 3.2 Archive the change on this branch with `--skip-specs`
- [ ] 3.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive reword-release-backstop`
