## Why

The owner asked for two new guides: "Write a resource" and "Write a blueprint". The site's "Extending OPM" section covers two of the four member kinds a catalog author adds, traits (`write-a-trait.md`) and transformers (`write-a-transformer.md`). Resources and blueprints have no guide. A catalog author who needs a new abstraction, or a new composition of existing members, has only the catalog source and `AGENTS.md` to go on.

## What Changes

- Two new scaffold pages under `docs/site/extending/`, written in the same shape as their siblings. Each page is a planning brief, not finished prose: front matter, a one-sentence brief, then `## Before you begin`, `## Steps`, `## Check that it worked` and `## Related`, with an HTML planning comment under each heading and each step. Every step brief ends with `Check against:` and real source paths. Each claim that is not yet confirmed is marked `Verify:` inside its brief.
  - `write-a-resource.md`, "Write a resource", `weight: 17`. The running example is the abstraction catalog's `namespaces` resource (`opm/resources/v1alpha1/namespace.cue`) and its transformer.
  - `write-a-blueprint.md`, "Write a blueprint", `weight: 19`. The running example is `stateless-workload` (`opm/blueprints/v1beta1/stateless_workload.cue`).
- `write-a-trait.md`: `weight: 20` becomes `weight: 18`, so the section reads resource, trait, blueprint, transformer, then cli's "Publish a catalog" at 22. Its Related brief also names the two new pages.
- `write-a-transformer.md`: its Before you begin brief names "Write a resource" beside "Write a trait", and its Related brief names "Write a blueprint". Its weight stays 21.
- No other content changes. No catalog member, schema, transformer or rule file changes. Nothing is breaking.

## Before / After

No member changes. The published modules `opm/` and `k8s/` are byte-identical before and after. The review surface is page front matter, which is YAML, so it is shown as YAML.

**Before**

```yaml
# docs/site/extending/write-a-resource.md: none
# docs/site/extending/write-a-blueprint.md: none

# docs/site/extending/write-a-trait.md
---
title: "Write a trait"
description: "Define a new trait that components can attach."
type: how-to
weight: 20
---
```

**After**

```yaml
# docs/site/extending/write-a-resource.md
---
title: "Write a resource"
description: "Define a new resource that components can carry."
type: how-to
weight: 17
---

# docs/site/extending/write-a-blueprint.md
---
title: "Write a blueprint"
description: "Compose resources and traits into a blueprint that module authors start from."
type: how-to
weight: 19
---

# docs/site/extending/write-a-trait.md
---
title: "Write a trait"
description: "Define a new trait that components can attach."
type: how-to
weight: 18
---
```

## Impact

- **Catalog consumers.** None are reached: not the `modules` fleet, not subscribing platforms, not the `cli` fixtures under `testing.opmodel.dev`. `docs/site/` sits outside both CUE module roots and ships in no published artifact.
- **The site.** opmodel.dev assembles the Extending section from this repo and cli. After this merges, and after the supervisor refreshes the `site-src` worktree, the section lists five pages in this order:

  | Page | Owner | weight |
  |---|---|---|
  | `extending/write-a-resource.md` (new) | catalog_opm | 17 |
  | `extending/write-a-trait.md` (renumbered from 20) | catalog_opm | 18 |
  | `extending/write-a-blueprint.md` (new) | catalog_opm | 19 |
  | `extending/write-a-transformer.md` (unchanged) | catalog_opm | 21 |
  | `extending/publish-a-catalog.md` (unchanged) | cli | 22 |

  Both new pages pass the dialect lint from `orchestration.md` section 4.1. Neither page links to another page yet: the briefs name pages by title, as the siblings do.
- **Release class.** One section, committed as `docs(site):`. `docs` is hidden from release-please, and `docs/site/` is outside both package paths, so no release PR opens and no catalog version moves. No member moves to a new `apiVersion` segment. The change does not rely on the v2 alpha line.
- **Outside this change.** Three texts still describe the Extending section as traits, transformers and catalogs only: enhancement 0018's page inventory (`enhancements/0018/02-design.md`), the opmodel.dev section overview ("Add your own traits, transformers and catalogs ..."), and the planning comment in opm's `docs/site/_index.md` ("a missing trait, transformer or catalog"). The two inventory rows go to enhancements in a separate PR. The other two belong to their owning repos.
- **Touches.** `docs/site/extending/write-a-resource.md` (new), `docs/site/extending/write-a-blueprint.md` (new), `docs/site/extending/write-a-trait.md`, `docs/site/extending/write-a-transformer.md`, and this change directory, because the archive commit rides the PR.

## Enhancement

This change carries no delivery claim and no `enhancement.yaml`. The pages follow enhancement 0018's page contract (0018:D7, 0018:D7:R1). They sit here under 0018:D8, which gives catalog_opm the extending guides for catalog authors.
