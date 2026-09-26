---
title: "Attach a trait to a component"
description: "Add behaviour such as scaling, health checks or exposure to one component."
type: how-to
sidebar:
  order: 21
---

<!-- One sentence: attaching a trait adds one behaviour to one component, such as a Service, a disruption budget or a pod security context, without changing its blueprint. Use it whenever the component needs something its blueprint does not already carry.
The description names "health checks", but probes are container fields (`livenessProbe`, `readinessProbe`, `startupProbe` on the container schema), not a trait. Either say so in one line here or ask the author to drop "health checks" from the description.
Which traits are legal on which blueprint is written nowhere in the schema: `appliesTo` is `[#ContainerResource]` on nearly every trait. What decides it is whether a transformer that matched the component lists the trait. Steps 4 and 5 carry that as conditions.
Check against: catalog_opm/opm/traits/v1beta1/, catalog_opm/opm/resources/v1beta1/container.cue (#ContainerSchema probes) -->

## Before you begin

<!-- By title: a component built from a blueprint, as in "Choose a blueprint".
Check against: catalog_opm/docs/site/authoring/choose-a-blueprint.md, catalog_opm/opm/blueprints/v1beta1/ -->

## Steps

1. Check whether the blueprint already carries the trait.

   <!-- If the trait is in the blueprint's composed set, do not embed anything: set its fields inside the blueprint's key, for example `spec: statelessWorkload: scaling: count: 3`. The composed sets: `restartPolicy`, `sidecarContainers` and `initContainers` on all five blueprints; `scaling` on StatelessWorkload and StatefulWorkload; `updateStrategy` on those two and DaemonWorkload; `jobConfig` on TaskWorkload; `cronJobConfig` on ScheduledTaskWorkload. Autoscaling is `scaling.auto`, which also renders a HorizontalPodAutoscaler.
   Check against: catalog_opm/opm/blueprints/v1beta1/*.cue (composedTraits), catalog_opm/opm/traits/v1beta1/scaling.cue, catalog_opm/opm/transformers/hpa_transformer.cue -->

2. Import the traits package.

   <!-- `tr "opmodel.dev/catalogs/opm/traits/v1beta1"`. Backup and BackupCommand live in `traits/v1alpha1` and are alpha.
   Check against: catalog_opm/opm/traits/v1beta1/, catalog_opm/opm/traits/v1alpha1/ -->

3. Embed the trait's wrapper in the component.

   <!-- The wrapper is the name without the `Trait` suffix: `tr.#Expose`, not `tr.#ExposeTrait`. The wrapper supplies defaults the bare definition cannot, for example the Service name, which the `#Expose` wrapper defaults to the component's short DNS name; attaching `#ExposeTrait` without it leaves the name unset and vet refuses.
   - If the trait should follow configuration, wrap the embed in a guard: `if #config.httpRoute != _|_ { tr.#HttpRoute }`, and guard the matching spec field the same way (opm-modules/jellyfin/components.cue).
   Check against: catalog_opm/opm/traits/v1beta1/expose.cue (#Expose, #ExposeSchema.name), opm-modules/jellyfin/components.cue -->

4. Write the trait's fields under its key.

   <!-- The key is the trait's name in camelCase at spec level, beside the blueprint's key: `spec: expose: {...}`, `spec: disruptionBudget: {...}`, `spec: httpRoute: {...}`. Writing the field without embedding the trait is refused as "field not allowed", because a component's spec admits only the fields its resources, traits and blueprints contribute.
   - If you attach a route trait (`#HttpRoute`, `#GrpcRoute`, `#TcpRoute`, `#TlsRoute`), attach `#Expose` too: each route transformer requires both, and without Expose the route trait is only reported as unhandled.
   Check against: core/src/component.cue (spec: close({_allFields})), catalog_opm/opm/transformers/http_route_transformer.cue, catalog_opm/opm/transformers/grpc_route_transformer.cue, catalog_opm/opm/transformers/tcp_route_transformer.cue, catalog_opm/opm/transformers/tls_route_transformer.cue -->

5. Confirm a transformer on the platform handles the trait.

   <!-- A trait is handled when a transformer that matched the component requires it or lists it in `optionalTraits`. Conditions:
   - If the trait renders its own object, its transformer matches on its own: Expose (Service), the route traits (Gateway API routes), DisruptionBudget (PodDisruptionBudget), NetworkPolicy (NetworkPolicy), `scaling.auto` (HorizontalPodAutoscaler).
   - If the trait changes the pod, the workload transformer must list it. HostNetwork is listed by the DaemonSet and StatefulSet transformers only, so on a StatelessWorkload it is unhandled. Verify: EncryptionConfig and Sizing appear in no transformer in catalog_opm/opm/transformers.
   - If an unhandled trait's posture is advisory (`optional: bool | *true`, every v1beta1 trait), the render continues and warns `component "<name>": trait "<fqn>" is not handled by any matched transformer (values will be ignored)`.
   - If it is load-bearing (`optional: bool | *false`: Backup and BackupCommand, which declare `fulfilment: "provider"` and ship no transformer in this catalog), the render refuses with an unresolved demand unless the platform carries a provider transformer. A module may narrow the posture at the attachment site through `#traits: (<fqn>): optional: true`. Verify that spelling against a render.
   Check against: library/opm/internal/renderstage/render.cue.tmpl (_handled, warnings), cli/internal/workflow/render/render.go (formatAdvisories), library/opm/errors/match.go (UnresolvedDemand), core/src/trait.cue (optional, fulfilment), catalog_opm/opm/transformers/deployment_transformer.cue (optionalTraits), catalog_opm/opm/traits/v1alpha1/backup.cue -->

## Check that it worked

<!-- Command: `opm module build`.
Success: for a trait that renders its own object, a new `▸ <component> ← <transformer fqn>` line and the object in the YAML; for a trait folded into the workload, the field in the workload's pod template. In both cases no "is not handled by any matched transformer" warning. A refusal points at "Unresolved demands".
Check against: cli/internal/workflow/render/output_internal.go, cli/internal/workflow/render/log_output.go -->

## Related

<!-- By title: the reference entry "Catalog members" (each trait's generated page, with the transformers that serve it) and the concept page "Resources and traits".
Check against: catalog_opm/docs/site/reference/catalog-members.md, core/docs/site/concepts/resources-and-traits.md -->
