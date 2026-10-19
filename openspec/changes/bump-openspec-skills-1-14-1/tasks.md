## 1. Regenerate the skills

- [ ] 1.1 Save the four edited skills, run `openspec update --force .`, then 3-way merge each saved file against pristine 1.12.0 and 1.14.1 output
- [ ] 1.2 Resolve the `openspec-propose` conflict by the owner ruling in design.md
- [ ] 1.3 Delete `.claude/skills/openspec-sync-specs/`
- [ ] 1.4 Check that every skill says `generatedBy: "1.14.1"`, that no `allowed-tools` line changed and that no hidden Unicode is present
- [ ] 1.5 `task openspec:check` and `openspec validate --all --no-interactive` green, then commit `chore(openspec): regenerate the OpenSpec skills with 1.14.1`
