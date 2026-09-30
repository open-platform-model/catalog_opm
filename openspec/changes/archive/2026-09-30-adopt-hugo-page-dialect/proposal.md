## Why

opmodel.dev is moving from Astro + Starlight to Hugo + Hextra v0.13.0. The owner ruled that the source pages move to the Hugo dialect now, with no compatibility layer and no transition period (O4 in `orchestration.md`). The new site runs a source lint before every build, and that lint fails on any `sidebar:` front-matter key.

All eight pages under this repo's `docs/site/` carry a Starlight `sidebar:` block. On `origin/main` (2026-09-30), the lint from `orchestration.md` section 4.1 reports exactly eight violations here, one per page and all of them `sidebar:`. The source changes (S1-S6) merge first, so that opmodel.dev change A (`port-site-to-hugo-hextra`) can build the real sources from its section 2. This is S3, the catalog_opm row.

## What Changes

- In each of the eight pages, the two front-matter lines `sidebar:` and `  order: N` (lines 5 and 6) become the single line `weight: N`, with the same number:

  | Page | N |
  |---|---|
  | `docs/site/authoring/choose-a-blueprint.md` | 20 |
  | `docs/site/authoring/attach-a-trait.md` | 21 |
  | `docs/site/authoring/use-a-raw-kubernetes-resource.md` | 23 |
  | `docs/site/extending/write-a-trait.md` | 20 |
  | `docs/site/extending/write-a-transformer.md` | 21 |
  | `docs/site/reference/catalog-members.md` | 3 |
  | `docs/site/reference/kubernetes-resources.md` | 4 |
  | `docs/site/reference/catalog-contract.md` | 5 |

- Nothing else in `docs/site/` changes. This tree has no Starlight aside, no MDX file, no `import` line, no `index.md`, no figure, no code fence and no stale "Check against: opmodel.dev/site/content/docs/..." path. Its two internal links (`reference/catalog-contract.md:78-79`) are already root-absolute with a trailing slash. The lint and a grep confirm all of this (design.md, Research & Decisions).
- No rule or doc file changes. `AGENTS.md`, `openspec/config.yaml` and `docs/*.md` say nothing about the site page format (research R3, confirmed by a grep of `origin/main`). The page rules live in the workspace `STYLE.md` section "Site Pages", which I1a has already landed.
- Nothing is breaking. No catalog member, schema or transformer changes.

## Before / After

No member changes. The published modules `opm/` and `k8s/` are byte-identical before and after. The review surface is page front matter, which is YAML, so it is shown as YAML. `docs/site/reference/catalog-contract.md`, lines 1-7:

**Before**

```yaml
---
title: The Catalog Contract
description: "What a catalog author promises, at which contract levels the promise binds, and where OPM enforces it."
type: reference
sidebar:
  order: 5
---
```

**After**

```yaml
---
title: The Catalog Contract
description: "What a catalog author promises, at which contract levels the promise binds, and where OPM enforces it."
type: reference
weight: 5
---
```

The other seven pages change the same way, each keeping its own number (table above).

## Impact

- **Catalog consumers.** None are reached: not the `modules` fleet, not subscribing platforms, not the `cli` fixtures under `testing.opmodel.dev`. `docs/site/` sits outside both CUE module roots, so it ships in no published artifact.
- **The site.** opmodel.dev reads these pages. After this merges, change A's lint passes on this tree. The old Astro build on opmodel.dev `main` may render these pages degraded or fail until A merges. This is accepted, because the site is not live (`orchestration.md` section 2, "Known consequences").
- **Release class.** Section 1 commits as `docs(site):`. `release-please-config.json` hides `docs`, and `docs/site/` is outside both package paths (`opm`, `k8s`). So no release PR opens and no catalog version moves. No member moves to a new `apiVersion` segment. The change does not rely on the v2 alpha line.
- **Tags.** Every existing catalog_opm tag (`opm-v4.4.2`, `k8s-v1.0.0-alpha.5` and older) still carries `sidebar:`, so the site cannot build any of them. A post-S3 tag needs another releasable commit or a `Release-As:` footer. That is the owner's call, and it is already on the owner list (`orchestration.md` section 9). Until then, the site builds `v1.0` from `main`.
- **Future pages.** Once this merges, a new `docs/site` page in the old dialect fails the site build. No catalog_opm change is in flight today (`openspec/changes/` on `origin/main` holds only `archive/`).
- **Depends on.** Starts when: planned on main. Merges when: verify is green, after A's section 1 is green (its fixture build proves the dialect renders), and before A's section 2. The supervisor merges it (`orchestration.md` section 2, row S3).
- **Touches.** `docs/site/**` (the eight pages above), plus this change directory, because the archive commit rides the PR.

## Enhancement

This change carries no delivery claim and no `enhancement.yaml` (supervisor ruling O7). It brings the pages in line with enhancement 0018's page contract:
- 0018:D7 and 0018:D7:R1: a title, a one-line description and one of four types, and nothing else is required;
- 0018:D7:R3: the address comes from where a page sits, so no page declares it;
- the `weight` key of `#Page` in `enhancements/0018/contracts/contracts.cue`, which the Starlight `sidebar.order` never matched.

Under 0018:D8, catalog_opm owns these pages. The source-repo pull-request check that 0018:D13 describes is not part of this change.
