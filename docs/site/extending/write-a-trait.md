---
title: "Write a trait"
description: "Define a new trait that components can attach."
type: how-to
sidebar:
  order: 20
---

<!-- One sentence: this adds a new trait (an optional behaviour such as a disruption budget or a grace period) to a catalog, so that module authors can attach it to a component. The reader needs it when no trait in the catalog models the behaviour. Say that the trait only declares a schema, and that it renders nothing until a transformer handles it; that is the next page, "Write a transformer". Check against: core/src/trait.cue, catalog_opm/opm/traits/v1beta1/disruption_budget.cue -->

## Before you begin

<!-- The reader must already have: a catalog to add the trait to, either a checkout of catalog_opm or their own catalog module (cue.mod/module.cue, identity/identity.cue and a catalog.cue that embeds core's #Catalog); the cue CLI at the version the catalog builds with (catalog_opm CI pins v0.17.1; Verify: the minimum version a reader needs); the opm CLI for the final check. The reader has read the concept page "Resources and traits". Link the page "Publish a catalog" for the catalog layout. Check against: catalog_opm/.github/workflows/ci.yml, catalog_opm/opm/identity/identity.cue, catalog_opm/opm/catalog.cue, core/src/catalog.cue -->

## Steps

<!-- The steps edit CUE files in the catalog source. The running example can be a small trait modelled on graceful-shutdown or disruption-budget. Step 11 applies only when a blueprint should include the trait, and step 12 only to catalog_opm; the step names say so. -->

1. File the trait under its apiVersion.
   <!-- The file goes in <module>/traits/<apiVersion>/<name>.cue with the package clause equal to the version segment (package v1beta1). The segment never enters the fqn. If the trait's shape may still change, file it at v1alpha1: publish's compatibility gate skips alpha members, and a later shape change is a new v1alpha2 file, never an in-place edit. Check against: catalog_opm/AGENTS.md (Version-segment filing), catalog_opm/opm/traits/v1alpha1/backup.cue, cli/internal/publish/compat.go -->
2. Declare the trait's identity.
   <!-- Show #<Name>Trait: c.#Trait & {metadata: {...}} with modulePath "\(id.kindPrefix.traits)/<apiVersion>", name in kebab case, apiVersion, catalogVersion: id.Version, fqn "\(id.kindPrefix.traits)/<name>@<apiVersion>", a one-line description, and labels "trait.opmodel.dev/category" (catalog_opm uses workload, network, security, storage and runtime). Say that metadata.labels only categorise: nothing selects on them. Write the description as the trait's one-line summary (Verify: whether the generated reference that displays it has shipped before saying so). Check against: core/src/trait.cue, core/src/identity_package.cue (kindPrefix), catalog_opm/opm/traits/v1beta1/graceful_shutdown.cue -->
3. Write the spec schema.
   <!-- spec has exactly one field, named after the trait in camel case (disruption-budget becomes disruptionBudget), holding a separate #<Name>Schema definition. The schema must be expressible in OpenAPI v3. If the schema offers two mutually exclusive forms, use matchN (as #DisruptionBudgetSchema does) or make each disjunction arm refuse the other arm's fields with other?: _|_. Arms that differ only by which required field is missing never resolve when a module embeds the component. Check against: core/src/trait.cue (spec!), core/SPEC.md section 2.2 Constraints, catalog_opm/docs/struct-disjunctions.md, catalog_opm/opm/traits/v1beta1/disruption_budget.cue -->
4. State the trait's posture as a default.
   <!-- optional: bool | *true for an advisory trait (a workload without it still runs), bool | *false for a load-bearing one (an unhandled backup means no backups). Never a plain true or false: a module could not override it. Explain what the posture decides at render: an unhandled trait with optional true is a warning row, and with optional false the render refuses with an unresolved demand. Enforced at publish by core's #TraitOptionalGate; plain cue vet does not catch an unstated posture. Check against: core/src/trait.cue (optional, #TraitOptionalGate), core/SPEC.md section 2.2 Rationale, library/opm/internal/renderstage/render.cue.tmpl (unhandledWarnings, unresolvedTraits) -->
5. List the resources it applies to.
   <!-- appliesTo: [res.#ContainerResource] in almost every catalog_opm trait; the backup trait uses res.#VolumesResource. The field is required and must list at least one resource. Verify: core/SPEC.md section 2.2 says a trait attached to a component without a matching resource fails at unification, but core/src/component.cue never reads appliesTo and no kernel code does, so describe it only as required metadata unless the author confirms otherwise. Check against: core/src/trait.cue, core/src/component.cue -->
6. Decide what renders the trait.
   <!-- Three forks, written as conditions. If an existing transformer already renders the object the trait modifies, add the trait to that transformer's optionalTraits (the deployment transformer lists graceful-shutdown this way). If the trait renders an object of its own, write a transformer that lists it under requiredTraits (the pdb transformer does this for disruption-budget), following "Write a transformer". If a platform provider implements it, set fulfilment: "provider" and ship no transformer, not even a stub: a stub is itself a provider, and the first real one would then be the second. Check against: catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/pdb_transformer.cue, catalog_opm/AGENTS.md (Provider-fulfilled members), core/src/trait.cue (fulfilment) -->
7. Declare a name constraint if the trait names a DNS object.
   <!-- If a transformer renders this trait into an object whose name becomes a DNS label (the expose trait's Service), set #nameConstraint to c.#ServiceNameType or c.#NameType. Otherwise leave it alone: the default accepts any name. Never guard on the slot's presence. Check against: catalog_opm/docs/name-constraints.md, core/src/trait.cue (#nameConstraint), catalog_opm/opm/traits/v1beta1/expose.cue -->
8. Add the component wrapper.
   <!-- #<Name>: c.#Component & {#traits: (#<Name>Trait.metadata.fqn): #<Name>Trait}. This is what a module embeds (tr.#Expose in modules/web_app). If the wrapper references #names or matchLabels, declare that field first (#names: _), or vet fails with reference not found. Check against: catalog_opm/opm/traits/v1beta1/graceful_shutdown.cue, catalog_opm/docs/name-constraints.md (Lexical scope), modules/web_app/components.cue -->
9. Write the doc comment.
   <!-- A new catalog member must ship a doc comment directly above #<Name>Trait: what it is, what it renders, what a value must satisfy, at most 6 lines. Rationale goes in a // WHY block above it, separated by one blank line. Notes about this one trait belong here, not in a separate Markdown file, because they move with the definition. task docs:check fails a comment over 6 lines. Verify: catalog CI does not yet refuse a member with no doc comment (today it checks length only); state the rule as a requirement without naming a gate unless one has shipped. Check against: catalog_opm/AGENTS.md (Doc comments), catalog_opm/.tasks/doc-check.sh, catalog_opm/opm/traits/v1alpha1/backup.cue -->
10. List the trait in the catalog manifest.
    <!-- Add (tr.#<Name>Trait.metadata.fqn): tr.#<Name>Trait to the #traits map in catalog.cue, keyed by the fqn reference and never by a string literal. Listing is what makes the trait visible to a platform that subscribes to the catalog, including a provider-fulfilled one. Check against: catalog_opm/opm/catalog.cue, core/src/catalog.cue (#traits), catalog_opm/.tasks/listing.sh -->
11. If a workload blueprint should carry the trait, compose it there.
    <!-- Add it to the blueprint's composedTraits list and to its schema. Any propagation guard (if spec.<x>.<field> != _|_) sits at component level, outside the spec block: the in-spec form fails with "field not allowed" on cue v0.17.1. Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue, catalog_opm/docs/cue-guard-closedness-workaround.md -->
12. In catalog_opm, regenerate the index and run the checks.
    <!-- task generate:index regenerates opm/INDEX.md and k8s/INDEX.md; task check runs format, vet, layering, listing, fixtures, index freshness and the doc-comment limit. task fmt:check diffs the git index, so stage the edits first. Check against: catalog_opm/Taskfile.yml, catalog_opm/AGENTS.md (Build And Dev Commands) -->

## Check that it worked

<!-- One command: opm catalog publish <catalog-dir> --dry-run. Success is the plan's "posture gate" row reading "<n> traits checked, 0 refused" and the "member gate" row showing 0 refused. Say that an "already holds <tag>" refusal only means the committed version is already published and is unrelated to the new trait; opm catalog version set moves it. Check against: cli/internal/publish/plan.go (renderCatalogGates), cli/internal/publish/catalog_gates.go, cli/internal/publish/registry.go -->

## Related

<!-- Reference: "Catalog members". Concept: "Resources and traits". Also name the how-to "Write a transformer" for rendering the trait and "Attach a trait to a component" for how module authors use it. -->
