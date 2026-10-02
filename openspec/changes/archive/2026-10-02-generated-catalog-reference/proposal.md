## Why

The site's catalog reference is two stubs. `docs/site/reference/catalog-members.md` and `kubernetes-resources.md` carry planning comments and no entries, so a module author has no page that lists the blueprints, resources and traits they can use, what each one's spec accepts, or which transformer renders it.

The owner settled how that reference is made on 2026-10-02, recorded in the workspace `STYLE.md` section "Site Pages":

- Every fact derivable from CUE is generated in the repository that owns the CUE, committed under `docs/site/reference/` between marker comments, and guarded by a check that fails when it is stale.
- A member's one-line summary is its evaluated `metadata.description`, so every member needs one that agrees with its doc comment, and a check refuses a member without one.
- An entry tags a rule with what enforces it only where the source shows it, and marks a member that no transformer in its own catalog serves: **Not implemented** for `fulfilment: "catalog"`, **Provided by your platform** for `fulfilment: "provider"`.
- The abstraction family gets a page per member, blueprints first; the raw `k8s` family is one generated table, marked as the last resort.

Today 35 of the 74 contract members have no doc comment, several descriptions are vague ("Enforces encryption requirements") or wrong (`graceful-shutdown` claims pre-stop hooks its schema does not carry), and nothing refuses a member without a description.

## What Changes

- **Descriptions (both modules).** Every resource, trait and blueprint gets a `metadata.description` that is the first sentence of its doc comment. Members without a doc comment get one; vague or inaccurate descriptions are rewritten to say what the member is. No FQN, `apiVersion`, schema field, default or transformer output changes.
- **A description gate.** `task vet:descriptions` (`.tasks/description-check.sh`) refuses any member of the four catalog maps, transformers included, whose description is absent or blank. It runs in `task check` and in CI.
- **A generator.** `tools/refgen/`, a Go program with its own `go.mod` on `cuelang.org/go` v0.17.1 (the version `cli` and `library` use). It loads both catalog modules, evaluates `#resources`, `#traits`, `#blueprints` and `#transformers`, reads doc comments and spec schemas from the source, and writes:
  - `docs/site/reference/catalog-members/` (replacing `catalog-members.md`, same URL): a section page, then `blueprints/`, `resources/` and `traits/` subsections with one `type: reference` page per member;
  - the generated table inside `docs/site/reference/kubernetes-resources.md`.
- **Tasks and CI.** `task generate:reference` writes the pages; `task generate:reference:check` fails when any is stale and runs in `task check` and CI. The release workflow regenerates the pages in the same commit that advances `identity.Version` on a release PR, because every page is stamped with its module's version.
- **Rules.** `AGENTS.md` and `openspec/config.yaml` stop saying the repository holds no Go code, and gain the description and reference rules.

## Before / After

No member's shape changes. The published change is metadata text and doc comments, shown on one member:

**Before**

```cue
#ScalingTrait: c.#Trait & {
	metadata: {
		name:        "scaling"
		description: "A trait to specify scaling behavior for a workload"
	}
	optional: bool | *true
	spec: scaling: #ScalingSchema
}
```

**After**

```cue
// The replica count of a workload, with optional autoscaling. With auto set,
// it also renders a HorizontalPodAutoscaler.
#ScalingTrait: c.#Trait & {
	metadata: {
		name:        "scaling"
		description: "The replica count of a workload, with optional autoscaling"
	}
	optional: bool | *true
	spec: scaling: #ScalingSchema
}
```

## Impact

- **Consumers.** No module, platform or `cli` fixture has to do anything. `metadata.description` is on the compatibility gate's provenance denylist (0010:D30), so a changed description is not a contract change, and no matcher reads it.
- **Release class.** Section 1 is `fix(catalog):`: it changes published text in both modules, so `opm` (stable) cuts a patch and `k8s` (beta) advances `-beta.N`. Sections 2 and 3 touch nothing under `opm/` or `k8s/` and release nothing. No member moves to a new `apiVersion` segment, and nothing is breaking.
- **Site.** `/docs/reference/catalog-members/` keeps its URL as a section page. Two HTML planning comments in this repo's authoring guides point at the old file path and are updated; the same pointers in `opm` (`your-first-module.md`, `glossary.md`) are outside this repository and stay as they are until opm edits them. The stub's "each entry pointing at the abstraction that covers it" on `kubernetes-resources.md` is dropped (design.md, No covering-abstraction column).
- **Toolchain.** `task check` now needs Go to run the staleness check. CI installs it from `tools/refgen/go.mod`.
- **Release workflow.** The identity-advance step also installs Go and Task and regenerates the reference; a release PR whose pages were not regenerated would fail its own CI.

## Enhancement

None. The rules come from the owner's 2026-10-02 decisions in the workspace `STYLE.md` ("Site Pages"); enhancement 0018, which first described generated reference, was rejected. The enforcement facts the pages state cite 0010:D28, 0010:D32 and 0010:D37.
