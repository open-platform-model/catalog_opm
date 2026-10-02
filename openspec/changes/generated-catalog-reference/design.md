## Context

The two catalog modules, `opm/` (`opmodel.dev/catalogs/opm@v4`, 4.4.4) and `k8s/` (`opmodel.dev/catalogs/k8s@v1`, 1.0.0-beta.1), list their members in the four maps of `catalog.cue`: `opm` has 12 resources, 28 traits, 5 blueprints and 24 transformers, `k8s` 29 resources and 29 transformers. The maps are authoritative for what a platform sees (0015:D1), so the generator reads them, never the directory tree.

Section 1 touches every member file under `opm/resources/v1beta1/`, `opm/resources/v1alpha1/`, `opm/traits/v1beta1/`, `opm/traits/v1alpha1/`, `opm/blueprints/v1beta1/`, `k8s/resources/v1/` and `k8s/resources/v2/`, and only their `metadata.description` value and the doc comment directly above the definition. No field, default, closedness or required-field set changes, and no `apiVersion` segment moves.

## Goals / Non-Goals

**Goals:**
- Every member has a description that is its doc comment's first sentence, and a gate keeps it present.
- Every fact on the generated pages is computed from the catalog source; nothing is transcribed.
- The pages are deterministic, pass the site's dialect lint and build, and fail a check when stale.

**Non-Goals:**
- Pages for transformers (they have no page; Served by lists them by name and description, under the catalog path and version that make up their FQN).
- Examples pulled from transformer fixtures (see Decisions).
- A column mapping a raw `k8s` resource to the abstraction that covers it (see Decisions).
- Editing `opmodel.dev` or `opm`; their pointers to the old `catalog-members.md` path are theirs to update.

## Decisions

### Summary and notes come from one doc comment

A member's summary is its evaluated `metadata.description`. Its notes are the rest of its doc comment: the generator MUST find the description, plus a period, at the start of the doc comment (whitespace normalised), and refuses the member otherwise. That keeps the two agreeing after this change, not only on the day of the backfill. The doc comment is the comment group the CUE parser attaches to the definition (the `//` block directly above it); a `// WHY` block above it, separated by a blank line, is not part of it and never reaches a page.

### The spec is the authored source, not the evaluated value

`Value.Syntax` on an evaluated spec emits `_#def` wrappers, `let` aliases for every referenced definition and normalised types (`int & >=0` becomes `uint`), which is a dump, not a schema a reader can follow. The generator prints the member's own `spec:` field from the source AST with `cue/format`, then every definition it references, transitively, in first-reference order, with their doc comments:

```cue
spec: scaling: #ScalingSchema

#ScalingSchema: {
	count: int & >=0 & <=1000
	auto?: #AutoscalingSpec
}
```

- A reference into another package of the same catalog module (`res.#SecurityContextSchema`, `sch.#CronSchema`) is followed like a local one.
- A reference to another member's own spec root (a blueprint's `res.#ContainerSchema`) is not expanded: the page names it under the block and links that member's page, so the container schema appears once, on the container page.
- A reference outside the module (`c.#NameType` in core, the vendored Kubernetes types under `opm/schemas/kubernetes/`) is named under the block by import path and not expanded.
- Comment groups starting `WHY` and `////` banners are dropped: they are rationale for maintainers, not contract.

### Marks and enforcement rows are derived, never authored

A member is **served** when a transformer in the same catalog lists its FQN in `requiredResources`, `optionalResources`, `requiredTraits` or `optionalTraits`. A blueprint is served by the transformers whose `requiredLabels` its `matchLabels` answer and whose required resources and traits it composes, because no transformer can demand a blueprint (0010:D37).

| Condition | Page shows |
| --- | --- |
| Unserved, `fulfilment: "catalog"` | **Not implemented**, a `WARNING` alert in At a glance |
| Unserved, `fulfilment: "provider"` | **Provided by your platform**, an `IMPORTANT` alert in At a glance |

The alert's consequence sentence follows the trait's `optional` default: load-bearing (`*false`) says rendering a component that attaches it fails; advisory (`*true`) says the render warns and ignores its values (library `renderstage`, `unhandledWarnings` versus `unresolvedTraits`). With two providers the kernel refuses every render on the platform, not only the component's (library `kernel.RenderResult.OverSubscribed`, "Any row refuses the render").

Enforcement rows, each tagged with the place that refuses:

| Row | When | Tag |
| --- | --- | --- |
| A value under `spec.<key>` satisfies the schema | every member | `cue` |
| A required match label is answered | the member's `matchLabels` has a required field | `cue` |
| Exactly one catalog on the platform provides it | `fulfilment: "provider"` | `kernel` (0010:D32) |
| If nothing handles it, the render is refused | trait whose `optional` defaults to `false` | `kernel` (0010:D28) |

Nothing else is tagged or stated as a rule. `appliesTo` is listed as declared, because nothing reads it today.

### No examples

No member file carries an example, and 53 of the 56 transformer golden fixtures did not evaluate until they were repaired on 2026-09-15; a fixture is a test input shaped for a transform, not an authored component. The Example part is omitted on every page rather than filled from material nobody vouched for.

### No covering-abstraction column

The raw table would name the abstraction that covers the same ground only if the source said so. Nothing does: `producesKinds` is set on 6 of the 53 transformers, and no field links a `k8s` member to an `opm` one. The column is left out, and the table's intro says so.

### Page layout and stamps

- `docs/site/reference/catalog-members/_index.md` keeps the stub's title, description and `weight: 3`; its subsections are `blueprints/` (weight 1), `resources/` (2) and `traits/` (3). Member pages declare no weight, so they sort by title. The section page and `kubernetes-resources.md` are authored around a generated block; every other page under `catalog-members/` is wholly generated.
- A member page's file name is its `metadata.name` (`host-ipc.md`), and its title is its definition name without the kind suffix (`HostIPC`), which is the wrapper a module author embeds (`tr.#HostIPC`). Two members of one name at different `apiVersion`s get `<name>-<apiVersion>.md`.
- Generated text sits between `<!-- BEGIN GENERATED by tools/refgen ... -->` and `<!-- END GENERATED -->`. Every page states the module path and the `identity.Version` it was generated from.
- Prose taken from doc comments is escaped for Markdown outside code spans (the site renders raw HTML, so `<sts>` would vanish), and a `docs/<note>.md` pointer becomes a link to the file on GitHub.

### The version stamp forces regeneration on release PRs

The stamp, every `catalogVersion` and every transformer FQN carry `identity.Version`, which `opm catalog version set` advances on the release PR. The identity-advance step in `release.yml` therefore runs `task generate:reference` and commits the pages with the identity file; without it a release PR fails its own staleness check. `branch-publish.yml` stamps its `-dev` version after `task check`, into a working tree it never commits, so it needs nothing.

## Research & Decisions

### How to load the catalogs
**Context**: The generator needs core (`opmodel.dev/core@v2`) and, for `opm`, `cue.dev/x/k8s.io@v0`.
**Explored**: `cue/load` with a nil `Registry` reads `CUE_REGISTRY` and the module cache exactly as `cue vet` does.
**Decision**: Load with `load.Instances` from each module root; the tasks inherit the registry variables the other tasks use.
**Rationale**: One resolution path for `task vet` and the generator.

### Where the description gate lives
**Context**: A CUE constraint on the catalog maps would ship in the published artifact, and a member is a definition, where an absent optional field is not an error.
**Explored**: A `cue export` of the member keys whose `metadata.description & =~"[^[:space:]]"` is bottom; on a scratch copy it lists both a deleted and a blank description.
**Decision**: `.tasks/description-check.sh`, one evaluation per module, beside `listing.sh`.
**Rationale**: The published modules stay byte-identical to what a member author wrote.

## Risks / Trade-offs

- [`task check` now needs Go] -> CI installs it from `tools/refgen/go.mod`; a contributor without Go can still run every CUE gate individually.
- [A release PR's identity commit grows from one file to the identity file plus the regenerated pages] -> the commit is still made by the same step on the same branch, and the staleness check proves it complete.
- [The doc-comment rule is stricter than before: a member's doc comment must open with its description] -> the generator names the member and the expected sentence; `AGENTS.md` states the rule.

## Durable decisions

- A member's description is the first sentence of its doc comment, and `task vet:descriptions` refuses a missing one: `AGENTS.md`, Working Style, "Descriptions" (lands in section 1).
- The site reference is generated by `tools/refgen`; regenerate it after any member change, the release workflow regenerates it on release PRs, and the repository is no longer CUE-only: `AGENTS.md` (Repository Layout, commands table, Working Style, Release & publishing) and `openspec/config.yaml` (lands in section 3).
- What the generator derives and what it refuses (marks, enforcement rows, no examples, no covering column): stays with the change and in `tools/refgen`'s package documentation.
