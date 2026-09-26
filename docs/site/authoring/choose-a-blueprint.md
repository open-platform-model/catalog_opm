---
title: "Choose a blueprint"
description: "Pick the blueprint that matches the workload your component describes."
type: how-to
sidebar:
  order: 20
---

<!-- One sentence: this page picks the workload blueprint for a component that runs a container, which decides the Kubernetes workload kind it renders to (Deployment, StatefulSet, DaemonSet, Job or CronJob). Do it once per component, before attaching traits.
The choice is written nowhere in the schema. Each blueprint stamps one value of the `core.opmodel.dev/workload-type` label (its `matchLabels`), and exactly one workload transformer in opmodel.dev/catalogs/opm requires that value in its `requiredLabels`. The forks below restate those five pairs as conditions a reader can answer.
Check against: catalog_opm/opm/blueprints/v1beta1/, catalog_opm/opm/transformers/deployment_transformer.cue, catalog_opm/opm/transformers/statefulset_transformer.cue, catalog_opm/opm/transformers/daemonset_transformer.cue, catalog_opm/opm/transformers/job_transformer.cue, catalog_opm/opm/transformers/cronjob_transformer.cue -->

## Before you begin

<!-- By title: a module with at least one component, as built in "Your first module", and a component that runs one main container. A component that runs no container needs no blueprint (see step 1).
Check against: opm/docs/site/authoring/your-first-module.md, catalog_opm/opm/resources/v1beta1/container.cue -->

## Steps

1. Match the workload to a blueprint.

   <!-- Forks as conditions, one per real blueprint in catalog_opm/opm/blueprints/v1beta1:
   - If the component runs continuously and any replica can serve any request, with no per-pod identity or storage, use `#StatelessWorkload` (label value `stateless`, renders a Deployment).
   - If each pod needs a stable identity or its own persistent volume, use `#StatefulWorkload` (`stateful`, renders a StatefulSet). It also composes the Volumes resource. The component's resource name must then be a DNS label: no dots, at most 63 characters.
   - If one pod must run on every node, or on selected nodes, use `#DaemonWorkload` (`daemon`, renders a DaemonSet). It composes no scaling.
   - If the component runs once to completion, use `#TaskWorkload` (`task`, renders a Job).
   - If it runs on a schedule, use `#ScheduledTaskWorkload` (`scheduled-task`, renders a CronJob). `cronJobConfig.scheduleCron` is required.
   - If the component runs no container (only ConfigMaps, a Role, CRDs, namespaces or webhooks), use no blueprint: embed the resource wrapper instead (`res.#ConfigMaps`, `res.#Role`, `res.#CRDs` from resources/v1beta1; `#Namespaces`, `#ValidatingWebhooks`, `#MutatingWebhooks` from resources/v1alpha1).
   - If nothing in this catalog models the object, see "Use a raw Kubernetes resource".
   `network_policy_attachment.cue` in the blueprints directory is a test file, not a blueprint.
   Check against: catalog_opm/opm/blueprints/v1beta1/*.cue, catalog_opm/opm/resources/v1beta1/container.cue (the required workload-type key), catalog_opm/opm/resources/v1alpha1/ -->

2. Import the blueprints package.

   <!-- `bp "opmodel.dev/catalogs/opm/blueprints/v1beta1"` in the file that holds `#components`. The module's `cue.mod/module.cue` already depends on `opmodel.dev/catalogs/opm@v4` when it came from `opm mod init`.
   Check against: cli/templates/minimal/cue.mod/module.cue, cli/templates/minimal/module.cue -->

3. Embed the blueprint in the component.

   <!-- `bp.#StatelessWorkload` (or the chosen one) as a line inside `#components: <name>: {...}`. Other resource wrappers may sit beside it, for example `res.#ConfigMaps` next to `bp.#StatefulWorkload` in opm-modules/jellyfin/components.cue.
   Do not set `core.opmodel.dev/workload-type` by hand: the blueprint stamps it. modules/DESIGN_PATTERNS.md section 12 still shows the hand-written label; do not copy it.
   Verify: what CUE reports when two blueprints are embedded in one component (the two label values should conflict).
   Check against: catalog_opm/opm/blueprints/v1beta1/stateless_workload.cue (#StatelessWorkload), core/src/component.cue (matchLabels derived from primitives) -->

4. Write the workload under the blueprint's key.

   <!-- The spec key is the blueprint's name in camelCase: `statelessWorkload`, `statefulWorkload`, `daemonWorkload`, `taskWorkload`, `scheduledTaskWorkload`. `container` is required in all five.
   The blueprint's composed traits are set inside that key, not at spec level: `scaling`, `restartPolicy`, `updateStrategy`, `sidecarContainers`, `initContainers` for stateless and stateful; `volumes` as well for stateful; `restartPolicy`, `updateStrategy`, `sidecarContainers`, `initContainers` for daemon; `jobConfig`, `restartPolicy`, `sidecarContainers`, `initContainers` for task; `cronJobConfig`, `restartPolicy`, `sidecarContainers`, `initContainers` for scheduled task.
   - If you chose `#TaskWorkload` or `#ScheduledTaskWorkload`, leave `restartPolicy` unset (the transformer falls back to `OnFailure`) or set `OnFailure` or `Never`. The schema admits `Always`, which Kubernetes rejects for a Job.
   Check against: catalog_opm/opm/blueprints/v1beta1/*.cue (the #...Schema definitions), catalog_opm/opm/traits/v1beta1/restart_policy.cue, catalog_opm/opm/transformers/job_transformer.cue, catalog_opm/opm/transformers/cronjob_transformer.cue -->

## Check that it worked

<!-- Command: `opm module build` in the module directory (or with its path).
Success: a log line `▸ <component> ← opmodel.dev/catalogs/opm/transformers/<kind>-transformer@<catalog version>`, where `<kind>` is `deployment`, `statefulset`, `daemonset`, `job` or `cronjob`, and the YAML shows the matching `kind:`. For stateless and stateful workloads a second line names `hpa-transformer`: it pairs with every component carrying the Scaling trait and renders nothing unless `scaling.auto` is set. If no transformer matched, the build fails with "<n> component(s) have no matching transformer" and lists the missing labels; point at "No matching transformer".
Check against: cli/internal/workflow/render/log_output.go, cli/internal/output/styles.go (FormatTransformerMatch), catalog_opm/opm/transformers/hpa_transformer.cue, library/opm/errors/unmatched.go -->

## Related

<!-- By title: the reference entry "Catalog members" (each blueprint's generated page) and the concept page "Components and blueprints". Also "How matching works" for why the label decides the kind.
Check against: catalog_opm/docs/site/reference/catalog-members.md, core/docs/site/concepts/components-and-blueprints.md, core/docs/site/concepts/how-matching-works.md -->
