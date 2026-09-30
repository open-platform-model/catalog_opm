## Context

This repo publishes eight site pages under `docs/site/`: three in `authoring/`, two in `extending/` and three in `reference/`. opmodel.dev assembles them by section. Every page opens with YAML front matter, and lines 5 and 6 are the Starlight order block:

```yaml
sidebar:
  order: N
```

The Hugo dialect (`orchestration.md` section 4) allows only `title`, `description`, `type` and `weight`. The lint in section 4.1 rejects `sidebar:`. Nothing else in this tree breaks the dialect. The proposal's table lists every page and its number.

The change touches no CUE. No member file, `apiVersion` segment, closedness, default or required field is reached in `opm/` or `k8s/`.

## Goals / Non-Goals

**Goals:**
- The lint in `orchestration.md` section 4.1 passes on `docs/site/`.
- Every page keeps its place: the page-order helper prints the same list before and after.
- `task check` stays green.

**Non-Goals:**
- Prose edits, new pages or renumbering.
- A source-repo CI job that lints `docs/site` (a 0018:D13 follow-up, outside this set).
- Repo-local callout style.
- A Hugo render of these pages. Change A does that (O4); S workers only lint.

## Decisions

**Keep every number; only the key changes.** Each `sidebar.order: N` MUST become `weight: N` with the same N.
- The order diff then proves that no page moved.
- The numbers already interleave with the other repos without a tie: authoring 10 (opm), 20, 21 (here), 22 (core), 23 (here), 24 (cli); extending 20, 21 (here), 22 (cli); reference 3, 4, 5 (here), 6 (cli), 7 (opm-operator), 8 (opm).
- Renumbering is a content decision, not a dialect one.
- `weight` is the key 0018's `#Page` already declares. Every N here is at least 3, so the `>= 1` narrowing in section 4 changes nothing.

**One section, one commit: `docs(site): adopt the hugo page dialect`.**
- The gate (lint and order diff) runs on the whole tree.
- Eight two-line edits of one kind have no useful boundary between them.
- The expected diff under `docs/site/` is 8 files changed, 8 insertions and 16 deletions, all at lines 5-6. The section commit also carries this change's `tasks.md` with its boxes ticked.

**No spike.** design.md carries no unverified assumption.
- The lint and the order helper ran on this tree while planning.
- A scratch dry run passed (Research & Decisions).
- Whether the dialect renders is proven by A's section 1 fixture build. That is a merge condition (`orchestration.md` section 2), not a section of this change.

**Links stay as they are.** `reference/catalog-contract.md:78-79` already link root-absolute with a trailing slash.
- `/docs/reference/registry-namespaces/` resolves to `cli/docs/site/reference/registry-namespaces.md`.
- `/docs/reference/cli/` is the site-owned CLI reference section, which no source repo may publish into (check 8 in `orchestration.md` section 6).
- A's link hook resolves both.

**No repo rule or doc file changes, and no pointer line.**
- No file in this repo describes the site page format. `AGENTS.md`, `openspec/config.yaml` and `docs/*.md` never mention `docs/site` or Starlight.
- The rule home is the workspace `STYLE.md` section "Site Pages" (I1a, on workspace `main`).
- S1 adds a pointer line to opm's `docs/STYLE.md` because that file governs opm's site pages. catalog_opm has no such file.
- A pointer in `AGENTS.md` would grow scope past the plan's Touches (`docs/site/**`).

**The lint and the order helper are never committed here.** The worker writes both to its scratch directory from this change's `orchestration.md` copy and checks their SHA-256.
- Only A commits the lint, as `opmodel.dev/site/scripts/lint-sources.sh`.
- Nobody commits the helper (section 4.1).

## Interface (orchestration.md section 6)

This change adds no interface name. It relies on these:
- **The dialect contract and its lint.** Section 4 and the 4.1 lint `opm-dialect-lint.sh` (sha256 `dae9717af0c43fc3bdc29a9e730fd171fe7541dab35a9625a35efb1682973c6b`). A commits the same bytes as `site/scripts/lint-sources.sh`, runs them in `task lint:sources` and before every `task build`, and they are check 2.
- **The page-order helper.** `opm-page-order.sh` (sha256 `edc62591eb019efc23b5c106d3b91e76620bb6e6a7ac47b3bde084c7857b5f65`), for S workers only.
- **Source roots.** `OPM_SRC_CATALOG_OPM`, which defaults to `$OPM_WS/catalog_opm/.claude/worktrees/site-src` when `OPM_SRC_WORKTREE=site-src`, and is mounted read-only at `/src/catalog_opm`. The supervisor creates that worktree after S1-S6 merge (section 5).
- **Ordering.** `_partials/opm/section-children.html` and `_partials/sidebar.html` order by `weight`, then title.
- **Links.** `layouts/_markup/render-link.html` resolves `/docs/...` in the current version and fails the build on a miss.
- **Edit links.** `_partials/opm/source.html` maps each page to its `catalog_opm/docs/site/...` path for the "Edit" link.
- **Checks.**
  - 3: front-matter validation. These pages carry valid types: 5 `how-to`, 3 `reference`.
  - 5: two sources publishing one URL. These paths collide with no other repo.
  - 6: expected pages.
  - 8: reserved prefixes. No page here sits under `docs/reference/cli/` or `docs/reference/definitions/`.

## Research & Decisions

### Lint findings on origin/main

**Context**: The plan counts 8 findings for catalog_opm. The task list must turn each finding into an edit.
**Explored**: The 4.1 lint was extracted byte for byte from `orchestration.md` (sha256 matched) and run over `docs/site/` of a planning worktree at `origin/main` (570bbac, 2026-09-30). It reported 8 violations, `opm-dialect-lint: 8 violation(s)`, each `<page>:5: sidebar: is Starlight front matter; write weight: N`, one per page. The page-order helper printed `authoring/attach-a-trait.md 21`, `choose-a-blueprint.md 20`, `use-a-raw-kubernetes-resource.md 23`, `extending/write-a-trait.md 20`, `write-a-transformer.md 21`, `reference/catalog-contract.md 5`, `catalog-members.md 3` and `kubernetes-resources.md 4`.
**Decision**: The only edit is the key rewrite.
**Rationale**: The lint found nothing else. A grep found no `:::`, `import`, `.mdx`, `index.md`, `{{`, code fence or relative link either.

### Dry run of the rewrite

**Context**: The edit must pass the lint and keep the order.
**Explored**: `git archive origin/main docs/site` was extracted twice into scratch. The rewrite ran on one copy with an awk one-liner (`sidebar:` plus `  order: N` becomes `weight: N`, inside the front matter only).
**Decision**: Apply exactly that rewrite.
**Rationale**: On the copy, the lint printed `opm-dialect-lint: OK`, the order diff was empty, and `diff -r` showed 24 changed lines: 8 pages, each with 2 lines removed and 1 added.

### Stale comment paths

**Context**: O4 asks every S change to fix "Check against: opmodel.dev/site/content/docs/..." paths.
**Explored**: Every path named in a "Check against:" comment under `docs/site/` was checked against `origin/main` of its repo.
**Decision**: No path edit.
**Rationale**: None names `opmodel.dev`, and every real path resolves. The misses were fragments, not files: a `*.cue` glob and parenthetical words.

### Rule and doc files

**Context**: O4 asks each S change to update its repo's rule and doc files that describe the Starlight/Astro format (R3 list).
**Explored**: R3 section 4.2 says "Nothing about site format. No change required" for catalog_opm. It was confirmed with `git grep -i -E 'starlight|astro|mdx|sidebar|docs/site|opmodel\.dev/site|hextra|hugo|admonition'` over tracked files outside `docs/site` and `openspec/changes/archive`, which found nothing.
**Decision**: No rule or doc file edit.
**Rationale**: There is nothing stale to fix.

### Gates on the untouched tree

**Context**: The section must be able to end green.
**Explored**: `task check` ran on the planning worktree with the workspace registry vars exported. It passed in about 13 s: format, vet, layering, listing, 53 + 9 fixtures, INDEX freshness and doc comments. It left the tree clean.
**Decision**: The gates are the lint, the order diff, `task check` and `openspec validate adopt-hugo-page-dialect --strict --no-interactive` (`orchestration.md` section 10, catalog_opm row).
**Rationale**: `task check` reads only `.cue` files and `INDEX.md`. It stays in the gate list because it is the repo's gate for every commit.

## Risks / Trade-offs

- [A new page in the old dialect breaks the site build once this merges (trap 27)] -> The lint names the file and line. Fix the page, never the lint. The rules are in the workspace `STYLE.md`, "Site Pages". No catalog_opm change is in flight.
- [No existing catalog_opm tag can be built (trap 36), and this `docs` commit cuts no release] -> The owner decides on a releasable commit or a `Release-As:` footer. B takes this change's merge SHA as catalog_opm's dialect floor. Until then, `v1.0` builds from `main`.
- [The old Astro build on opmodel.dev `main` degrades or fails after the merge] -> Accepted. The site is not live, and the owner is told (section 9).
- [`/docs/reference/cli/` resolves only if A keeps a site-owned page at that address (the reserved section behind check 8)] -> If A drops it, A's link hook fails the build and names `reference/catalog-contract.md`. The fix belongs in A, not here.
- [The history-rewrite hook refuses rebase and lease-push (trap 34)] -> Update the branch only by merging `origin/main`.
- [`.claude/worktrees/` is not in catalog_opm's `.gitignore` (trap 24)] -> Stage the eight pages and this change's `tasks.md` by explicit path, never `git add -A` or `git add .`.
- [The main checkout is stale (traps 25, 33)] -> Take the "before" tree for the order diff from `git archive origin/main`, and read skills from the worktree.
- [`task fmt:check` diffs the git index (AGENTS.md)] -> It diffs only `.cue` paths, and this change touches none, so staging after `task check` is safe here.

## Durable decisions

None. The authoring rule this change applies (front-matter keys, `weight`, `_index.md`, alerts, figures, links) already lives in the workspace `STYLE.md` section "Site Pages" and in `orchestration.md` section 4. This change promotes nothing new.

## Open Questions

None. The one owner item this change touches, how catalog_opm gets a post-S3 tag, is already on the owner list in `orchestration.md` section 9, and it changes neither the approach nor the tasks.
