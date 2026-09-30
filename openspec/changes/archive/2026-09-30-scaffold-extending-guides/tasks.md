## 1. Scaffold the two guides and renumber the trait page (docs/site/extending)

This change is one section. design.md carries no unverified assumption, so there is no spike.
- `<wt>` is the worktree `/var/home/emil/dev/open-platform-model/catalog_opm/.claude/worktrees/scaffold-extending-guides`, on branch `docs/scaffold-extending-guides`.
- `<scratch>` is a scratch directory outside any repo.
- Run `openspec` as `cd <wt> && openspec ...`.

Each new page copies `write-a-trait.md`'s shape exactly (design.md, Decisions): front matter, a one-sentence brief, `## Before you begin`, `## Steps`, `## Check that it worked`, `## Related`. Every step brief ends with `Check against:` and real paths. Every unconfirmed claim is a `Verify:` marker.

- [x] 1.1 Set up and take the baseline.
  - Write the lint block from `openspec/changes/archive/2026-09-30-adopt-hugo-page-dialect/orchestration.md` section 4.1 byte for byte to `<scratch>/opm-dialect-lint.sh`. Verify that `sha256sum` prints `dae9717af0c43fc3bdc29a9e730fd171fe7541dab35a9625a35efb1682973c6b`.
  - Verify that `sh <scratch>/opm-dialect-lint.sh <wt>/docs/site` prints `opm-dialect-lint: OK (...)` on the untouched tree.
- [x] 1.2 Write `docs/site/extending/write-a-resource.md`: title "Write a resource", `type: how-to`, `weight: 17`. The running example is `opm/resources/v1alpha1/namespace.cue` and `opm/transformers/namespace_transformer.cue`.
- [x] 1.3 Write `docs/site/extending/write-a-blueprint.md`: title "Write a blueprint", `type: how-to`, `weight: 19`. The running example is `opm/blueprints/v1beta1/stateless_workload.cue`.
- [x] 1.4 In `docs/site/extending/write-a-trait.md`, change `weight: 20` to `weight: 18`, and name "Write a resource" and "Write a blueprint" in the Related brief. Change nothing else. (Section 2 edits this page again, 2.2.)
- [x] 1.5 In `docs/site/extending/write-a-transformer.md`, name "Write a resource" in the Before you begin brief and "Write a blueprint" in the Related brief. Change nothing else. Its weight stays 21.
- [x] 1.6 Verify that `sh <scratch>/opm-dialect-lint.sh <wt>/docs/site` prints `opm-dialect-lint: OK (...)`, and that `grep -n '^weight:' <wt>/docs/site/extending/*.md` prints 19, 18, 17 and 21 for `write-a-blueprint.md`, `write-a-trait.md`, `write-a-resource.md` and `write-a-transformer.md`.
- [x] 1.7 Verify the diff scope.
  - `git -C <wt> diff --check` prints nothing.
  - `git -C <wt> status --short` lists only the two new pages, the two edited pages and `openspec/changes/scaffold-extending-guides/`.
- [x] 1.8 Close the section.
  - The lint (1.6) is green.
  - `task -d <wt> check` is green.
  - `cd <wt> && openspec validate scaffold-extending-guides --strict --no-interactive` is green.
  - Tick 1.1-1.8 in this file.
  - Stage by explicit path, never with `-A` or `.`: `git -C <wt> add docs/site/extending/write-a-resource.md docs/site/extending/write-a-blueprint.md docs/site/extending/write-a-trait.md docs/site/extending/write-a-transformer.md openspec/changes/scaffold-extending-guides/.openspec.yaml openspec/changes/scaffold-extending-guides/proposal.md openspec/changes/scaffold-extending-guides/design.md openspec/changes/scaffold-extending-guides/tasks.md`.
  - Then commit `docs(site): scaffold the write a resource and write a blueprint guides`.

## 2. Tighten the scaffolds after review (docs/site/extending)

The review of section 1 listed findings against both new pages, the trait page and this change's artifacts. Each one is re-checked first-hand before it changes a page; design.md, "What the review of section 1 measured", records the probes.

- [x] 2.1 Re-check each finding against source and, where it makes a claim about evaluation, with a cue v0.17.1 probe on a scratch copy of `opm/` (never in the worktree). Fix it or reject it with a one-line reason.
- [x] 2.2 Apply the fixes.
  - `write-a-blueprint.md`: the success check becomes `cue eval -c -e <guard>` per propagation guard; steps 5, 6 and the label in 7 become conditional; step 1's filing claim, step 3's composed lists, step 4's schema wording and step 7's label reason are corrected; the foreign-trait claim becomes `Verify:`; registry access joins Before you begin; Related is trimmed.
  - `write-a-resource.md`: "the page" replaces "the next page"; step 1's level becomes conditional; step 3's `cue eval -c` question is settled; step 4 gains the optionalResources fork and step 10 is retitled to match; step 5 names `c.#ServiceNameType` for a Service; step 10 requires an embedded-form fixture; step 2 says what `vet:listing` reports; the raw-catalog path and the core anchor are corrected; registry access joins Before you begin and the check names the INCOMPLETE outcome; Related is trimmed.
  - `write-a-trait.md`: "the page" replaces "the next page"; step 1's alpha-reshape rule becomes `Verify:`; step 5 names "Write a resource" and step 11 names "Write a blueprint" and the compatibility gate; Related returns to its `origin/main` text.
  - proposal.md, design.md and this file: the orchestration references point at the archived copy, the Outside list gains the missed briefs and the follow-ups, and the research notes are recorded as not kept.
- [x] 2.3 Close the section.
  - The lint (1.6) is green and `grep -c 'next page' <wt>/docs/site/extending/*.md` prints 0 for every page.
  - `task -d <wt> check` is green.
  - `cd <wt> && openspec validate scaffold-extending-guides --strict --no-interactive` is green.
  - Stage by explicit path, never with `-A` or `.`: the three edited pages and the three edited artifacts.
  - Then commit `docs(site): tighten the resource and blueprint scaffolds`.

## After the last section

This part has no checkboxes. The verify skill counts every box, and these steps come after the last commit.

- **Verify.** Read `<wt>/.claude/skills/openspec-verify-change/SKILL.md` and follow it for `scaffold-extending-guides`, running each `openspec` command as `cd <wt> && openspec ...`. Never use the root `/opsx:verify` router.
- **Hand off.** Report the branch, the commits, the gate results and every `Verify:` marker the two new pages carry, then stop. Archiving, pushing and opening the PR wait for the supervisor's go, not this file. The two 0018 inventory rows go to enhancements in a separate PR, which merges after this one or with it.
