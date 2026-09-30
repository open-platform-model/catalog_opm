## Context

`docs/site/extending/` holds two pages, `write-a-trait.md` (weight 20) and `write-a-transformer.md` (weight 21). Both are scaffolds. Each is front matter plus HTML planning comments under a fixed set of headings, and each comment ends with `Check against:` and real source paths. cli's `docs/site/extending/publish-a-catalog.md` (weight 22) is the section's third page. opmodel.dev assembles the section by weight, then by title.

The change touches no CUE. No member file, `apiVersion` segment, closedness, default or required field is reached in `opm/` or `k8s/`.

## Goals / Non-Goals

**Goals:**
- Two scaffold pages, "Write a resource" and "Write a blueprint", in exactly the shape of `write-a-trait.md`.
- The section reads in the order a catalog author builds: resource, trait, blueprint, transformer, publish.
- The dialect lint passes on `docs/site/`, and `task check` stays green.

**Non-Goals:**
- Finished prose. The pages stay planning briefs, like their siblings.
- Links between pages. The briefs name pages by title; links come when the prose is written.
- Updating enhancement 0018's page inventory, the opmodel.dev section overview, or opm's `docs/site/_index.md` planning comment. Each belongs to another repo (proposal, Impact).
- Adding the new pages to other catalog_opm briefs (`authoring/choose-a-blueprint.md`, `reference/catalog-members.md`). Only the two sibling Extending pages change.

## Decisions

**Order: resource 17, trait 18, blueprint 19, transformer 21, publish 22.**
- A catalog author writes a resource first. A trait's `appliesTo` lists resources. A blueprint composes resources and traits. A transformer renders what the other three declare. Publish comes last.
- `write-a-trait.md` MUST move from 20 to 18. That is the one renumbering. `write-a-transformer.md` stays at 21, and cli's "Publish a catalog" stays at 22.
- Alternatives considered:
  - Keep every existing weight and put the resource at 19 and the blueprint at 23. Rejected: the blueprint would sort after "Publish a catalog".
  - Blueprint at 20, tied with the trait, relying on the title tiebreak ("Write a blueprint" sorts before "Write a trait"). Rejected: it puts the blueprint before the trait it composes, and an order that rests on a tie breaks silently when a title changes.
- Weight 20 stays unused. No other repo publishes into the Extending section (cli's page is at 22), so nothing collides.

**The pages live in catalog_opm.** Under 0018:D8, a page lives in the repo whose change would make it wrong, and catalog_opm owns the extending guides for catalog authors. Both pages describe how members of this repo are filed, listed and checked.

**Scaffolds only.** Each page MUST follow `write-a-trait.md`'s shape:
- front matter with exactly `title`, `description`, `type: how-to` and `weight`;
- one opening planning comment, a one-sentence brief;
- `## Before you begin`, `## Steps` (a numbered list of imperative step titles, each followed by an indented planning comment), `## Check that it worked` and `## Related`.

Every step comment states what the step says and ends with `Check against: <real paths>`. Paths are workspace-rooted (`core/src/resource.cue`, `catalog_opm/opm/catalog.cue`). Every claim comes from the research behind this change, or from a source file read while writing it. A claim that is not confirmed is written as `Verify: ...` inside its brief.

**Running examples come from this repo.**
- Resource: `namespaces` (`opm/resources/v1alpha1/namespace.cue`) and `opm/transformers/namespace_transformer.cue`. It is an abstraction-family resource filed at `v1alpha1`, where a new abstraction starts. It keys a map, declares a name constraint, and has one transformer with golden fixtures. `configmap.cue` is the second example for schema defaults.
- Blueprint: `stateless-workload` (`opm/blueprints/v1beta1/stateless_workload.cue`). It composes one resource and five traits, answers the container's required `workload-type` key, and shows the hoisted propagation guards.

**One section, one commit: `docs(site): scaffold the write a resource and write a blueprint guides`.** Two new files and two small edits have no useful boundary between them. The section commit also carries this change's proposal, design and tasks.

**No spike.** This design rests on no unverified assumption. The facts the pages still need to confirm are `Verify:` markers inside the pages, and each one is work for the page's later author.

## Research & Decisions

### What a resource and a blueprint need

**Context**: The briefs must state real rules with real paths, not rules from memory.
**Explored**: Three research notes, written before this change and read-only in the `site-src` worktrees of core, catalog_opm, cli and library:
- resource: `core/src/resource.cue`, `core/src/component.cue`, `core/SPEC.md` section 2.1, catalog_opm's resources, `catalog.cue`, `.tasks/listing.sh`, `AGENTS.md`, and cli's `internal/publish` gates. The research also ran cue v0.17.1 probes against a scratch copy of `core/src`.
- blueprint: `core/src/blueprint.cue`, `core/SPEC.md` section 3.3, the five blueprints, `network_policy_attachment.cue`, `container.cue` and `docs/cue-guard-closedness-workaround.md`.
- page shape: `write-a-trait.md`, `write-a-transformer.md` and cli's `publish-a-catalog.md`.

This change's worktree (`origin/main` 7d2e1dd) re-read the catalog files the briefs cite. core's `src/` and `SPEC.md` are unchanged between the `site-src` worktree and `origin/main`.
**Decision**: The briefs cite those files. Five findings from the research went into the pages as rules:
- A resource that no transformer handles refuses every render that attaches it (0010:D28), unless it is provider-fulfilled.
- `fqn` must be written with the `\(id.kindPrefix.<kind>)` interpolation on one line, because `task vet:listing` greps for that form.
- A disagreeing `fqn` passes `cue vet` and is caught only by the publish member gate.
- A blueprint's wrapper must propagate every composed field to the flat `spec` field the transformers read, with guards hoisted to component level.
- A new `workload-type` value needs the container's enum widened and a new transformer.
**Rationale**: These are the mistakes that pass a local `cue vet` and fail later, which is what a how-to must warn about.

### Unconfirmed claims

**Context**: Some facts in the research are inferred, disputed, or have no shipped precedent.
**Explored**: The research marks each one `[unverified]`, `UNVERIFIED`, or as an inference.
**Decision**: Each one becomes a `Verify:` marker in the brief that uses it. None is stated as fact.
**Rationale**: This is the siblings' own convention. The page's later author confirms each marker before writing the prose.

### Gates on the untouched tree

**Context**: The section must be able to end green.
**Explored**: The dialect lint from `orchestration.md` section 4.1 (sha256 `dae9717af0c43fc3bdc29a9e730fd171fe7541dab35a9625a35efb1682973c6b`) printed `opm-dialect-lint: OK` on `docs/site/` of this worktree before any edit.
**Decision**: The gates are the lint, `task check` and `openspec validate scaffold-extending-guides --strict --no-interactive` (`orchestration.md` section 10, catalog_opm row). There is no order diff: this change moves pages on purpose, and the proposal's table is the intended order.
**Rationale**: `task check` reads only `.cue` files and `INDEX.md`. It stays in the gate list because it is the repo's gate for every commit.

## Risks / Trade-offs

- [A brief cites a path that moves before the prose is written] -> Every brief ends with `Check against:`, and the page's later author re-reads those files before writing. That is what the convention is for.
- [The renumbering changes the trait page's position for anyone who bookmarked the order] -> Nothing is published yet, and the site orders by weight, so the edit is one front-matter line.
- [Other texts still name only traits, transformers and catalogs] -> Named in the proposal's Impact as follow-ups for their owning repos and the enhancements PR.
- [`.claude/worktrees/` is not in catalog_opm's `.gitignore`] -> Stage explicit paths, never `git add -A` or `git add .`.

## Durable decisions

None. The page shape and the dialect rules already live in the workspace `STYLE.md` section "Site Pages" and in `orchestration.md` section 4. The authoring rules the briefs cite already live in `AGENTS.md` and `docs/`. This change promotes nothing new.
