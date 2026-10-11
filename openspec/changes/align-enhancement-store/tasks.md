## 1. Rules

- [x] 1.1 `openspec/config.yaml`: add `references:` for `opm-enhancements`; replace the `NNNN:Dn` bullets and the `enhancement.yaml` and delivery-log rules with the comment rule, the `Delivers` proposal rule, the read-an-entry context line and the archive guidance.
- [x] 1.2 `AGENTS.md` and the `catalog-change` schema (`schema.yaml`, `templates/proposal.md`): the same rule text; remove the `enhancement.yaml` and `delivery:log` text.
- [x] 1.3 Add `.tasks/openspec-check.sh` and `task openspec:check`, and add the task to `task check` and to the `AGENTS.md` list of what `task check` runs.
- [x] 1.4 `task check` green and `openspec validate align-enhancement-store --strict` passes, then commit `docs(openspec): move the enhancement rules into config.yaml`

## 2. Mechanical rewrite

- [x] 2.1 Run `enh cite-rewrite --root <worktree> --write --worklist <file>` once.
- [x] 2.2 Read at least 40 of the tool's edits; fix a wrong edit by hand and record it in the report.
- [x] 2.3 Commit by place, then `task check` green: `docs` for code comments (7f1d1bb) and for docs and rules (57eda23), `chore` for workflow and task comments (0f8b8ce), `docs(openspec)` for archived changes with the 13 `enhancement.yaml` files deleted (8a38b0a).

## 3. The worklist

- [x] 3.1 Rewrite the worklist rows by hand by the comment rule; run `task generate:index`.
- [x] 3.2 `enh cite-lint` reports 0 findings, `enh cite-rewrite --dry-run` reports 0 edits, `task check` green. The hand edits went into the place commits above; the record commit is ef36eb8.

## 4. Verify and archive

- [x] 4.1 `openspec validate align-enhancement-store --strict`; review (two supervisor reviewers); fix findings (0a040c1, 0f6207b, 7edca36).
- [ ] 4.2 Archive the change on this branch and commit `docs(openspec): archive align-enhancement-store`.
