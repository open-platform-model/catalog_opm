## 1. AGENTS.md

- [ ] 1.1 In the "Commit conventions and release impact" table (`AGENTS.md:254`), replace the row `` `feat!:` / `BREAKING CHANGE:` `` with `` `feat!:` (a `!` in the PR title) ``, keeping the other three cells as they are. Under the table, add the sentence that the PR title is the squash commit's type and the only text release-please reads under `BLANK` (design.md D1).
- [ ] 1.2 After the "Rule of thumb" line, add the three bullets from design.md D2: the squash message, the forced version, and that a release cascade PR never carries `!`. Cite workspace `RELEASING.md`, "Owner settings" and "Bump rule" by name. Every `@` is glued to a path (`opmodel.dev/catalogs/opm@v5`).
- [ ] 1.3 In the stable-line bullet (`AGENTS.md:126`), change "a `feat!:` on `opm` bumps the major" to "a `feat!:` PR title on `opm` bumps the major" (design.md D3).
- [ ] 1.4 Run `grep -n -E 'BREAKING CHANGE|Release-As|release-as' AGENTS.md`. The only hits should be the new D2 bullets and the `RELEASE` stamp bullet, which is left unchanged on purpose (design.md, Non-Goals).
- [ ] 1.5 `task check` is green. Then commit `docs(agents): describe breaking and forced releases under the blank squash message`.

## 2. openspec/config.yaml

- [ ] 2.1 In Principle I (`openspec/config.yaml:25`), change "a `feat!:` on `opm` bumps the major" to "a `feat!:` PR title on `opm` bumps the major" (design.md D3).
- [ ] 2.2 In the apply guidance (`openspec/config.yaml:208`), replace "because the squash body reaches release-please" with the D4 wording. Keep the entry a single plain string.
- [ ] 2.3 Run `openspec validate align-release-docs-with-blank-squash --strict` and confirm it passes. Run `openspec instructions apply --change align-release-docs-with-blank-squash --json` and confirm the new guidance text comes through; a malformed rules entry is dropped silently (`openspec/config.yaml` design-rules comment).
- [ ] 2.4 `task check` is green. Then commit `docs(openspec): restate the release rules for the blank squash message`.
