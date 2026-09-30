## 1. Rewrite the eight site pages to the Hugo page dialect (docs/site)

This change is one section. design.md carries no unverified assumption, so there is no spike.
- `<wt>` is your own worktree, `/var/home/emil/dev/open-platform-model/catalog_opm/.claude/worktrees/adopt-hugo-page-dialect`, on branch `docs/adopt-hugo-page-dialect`. Worktree setup follows `orchestration.md` section 7, step 2, not this file.
- `<scratch>` is your scratch directory, outside any repo.
- Run `openspec` as `cd <wt> && openspec ...`.

Every edit below changes only lines 5 and 6 of a page. The two front-matter lines `sidebar:` and `  order: N` become one line, `weight: N`, with the same N. Nothing else in a page changes.

- [ ] 1.1 Set up and take the baseline.
  - Write the two script blocks from `orchestration.md` section 4.1 (the copy in this change directory) byte for byte to `<scratch>/opm-dialect-lint.sh` and `<scratch>/opm-page-order.sh`. Verify that `sha256sum` prints `dae9717af0c43fc3bdc29a9e730fd171fe7541dab35a9625a35efb1682973c6b` and `edc62591eb019efc23b5c106d3b91e76620bb6e6a7ac47b3bde084c7857b5f65`.
  - If your shell does not already carry them, export `CUE_REGISTRY` and `OPM_REGISTRY` as the workspace root `AGENTS.md` shows.
  - Verify that `sh <scratch>/opm-dialect-lint.sh <wt>/docs/site` reports exactly `8 violation(s)`: one `<page>:5: sidebar: is Starlight front matter; write weight: N` for each page in 1.2-1.4.
  - Verify that `task -d <wt> check` is green on the untouched tree.
  - If the lint reports any other finding, or a page that is not listed here, `origin/main` has moved since planning. Stop and report it under `deviations`.
- [ ] 1.2 `docs/site/authoring/`: `choose-a-blueprint.md` gets `weight: 20`, `attach-a-trait.md` gets `weight: 21`, and `use-a-raw-kubernetes-resource.md` gets `weight: 23`. Verify that `grep -n '^weight:' <wt>/docs/site/authoring/*.md` prints line 5 of each file, with those numbers.
- [ ] 1.3 `docs/site/extending/`: `write-a-trait.md` gets `weight: 20`, and `write-a-transformer.md` gets `weight: 21`. Verify with `grep -n '^weight:' <wt>/docs/site/extending/*.md`.
- [ ] 1.4 `docs/site/reference/`: `catalog-members.md` gets `weight: 3`, `kubernetes-resources.md` gets `weight: 4`, and `catalog-contract.md` gets `weight: 5`. Leave the two links near the end of `catalog-contract.md` (`/docs/reference/registry-namespaces/` and `/docs/reference/cli/`) as they are: they already have the required form. Verify with `grep -n '^weight:' <wt>/docs/site/reference/*.md`.
- [ ] 1.5 Verify that `sh <scratch>/opm-dialect-lint.sh <wt>/docs/site` prints `opm-dialect-lint: OK (...)`, and that `grep -rn 'sidebar' <wt>/docs/site` prints nothing.
- [ ] 1.6 Run the order diff exactly as `orchestration.md` section 4.1 shows ("How an S worker runs them"):
  - extract `origin/main`'s `docs/site` into `<scratch>/before` with `mkdir -p <scratch>/before`, then `git -C <wt> archive origin/main docs/site | tar -x -C <scratch>/before`;
  - run `opm-page-order.sh` on the before tree and on `<wt>/docs/site`;
  - `diff` the two outputs.

  Verify that it prints `order unchanged`.
- [ ] 1.7 Verify the diff scope. By now boxes 1.1-1.6 are ticked, so this file is modified too.
  - `git -C <wt> diff --stat -- docs/site` shows 8 files changed, 8 insertions(+), 16 deletions(-).
  - `git -C <wt> diff --check` prints nothing.
  - `git -C <wt> status --short` lists only the eight pages and `openspec/changes/adopt-hugo-page-dialect/tasks.md`.
- [ ] 1.8 Close the section.
  - The lint (1.5) and the order diff (1.6) are green.
  - `task -d <wt> check` is green.
  - `cd <wt> && openspec validate adopt-hugo-page-dialect --strict --no-interactive` is green.
  - Tick 1.1-1.8 in this file.
  - Stage the eight pages and this file by explicit path, never with `-A` or `.`: `git -C <wt> add docs/site/authoring/choose-a-blueprint.md docs/site/authoring/attach-a-trait.md docs/site/authoring/use-a-raw-kubernetes-resource.md docs/site/extending/write-a-trait.md docs/site/extending/write-a-transformer.md docs/site/reference/catalog-members.md docs/site/reference/kubernetes-resources.md docs/site/reference/catalog-contract.md openspec/changes/adopt-hugo-page-dialect/tasks.md`.
  - Then commit `docs(site): adopt the hugo page dialect`.

## After the last section (orchestration.md section 7, step 6)

This part has no checkboxes. The verify skill counts every box, and these steps come after the last commit.

- **Verify.** Read `<wt>/.claude/skills/openspec-verify-change/SKILL.md` and follow it for `adopt-hugo-page-dialect`, running each `openspec` command as `cd <wt> && openspec ...`. Never use the root `/opsx:verify` router.
- **Report.** Use the report block in `orchestration.md` section 7, step 6: `change: S3 catalog_opm adopt-hugo-page-dialect` and `sections: 1/1`. The gates are the lint, the order diff, `task check` and `openspec validate`. The `surface` line lists the section 6 names that design.md's "Interface" section relies on. Then stop and wait for the supervisor.

Everything after the report follows `orchestration.md` section 7, steps 7-8, not this file.
