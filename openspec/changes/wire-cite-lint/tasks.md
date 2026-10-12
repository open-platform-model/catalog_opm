## 1. Pin

- [ ] 1.1 Move the five `.github` references to `2b66da51fede4332969c324b069012632d8edea9` and replace `.tasks/cascade/wiring-check.sh` with the copy at that commit; commit `ci(deps)`.

## 2. Wiring

- [ ] 2.1 `Taskfile.yml`: `task cite-lint` at tool commit `e0335b2ec44e659c0191bc3523d79d17f26f8e7d`.
- [ ] 2.2 `ci.yml`: a `cite-lint` job calling `cite-lint.yml`, and a step that runs `task openspec:check`; `wiring-check.yaml` declares the `cite-lint` reference.
- [ ] 2.3 `AGENTS.md` lists the task and the CI job where it lists checks.

## 3. Verify and archive

- [ ] 3.1 `task cite-lint`, `task check`, `openspec validate wire-cite-lint --strict`, actionlint, zizmor.
- [ ] 3.2 Review, fix, archive.
