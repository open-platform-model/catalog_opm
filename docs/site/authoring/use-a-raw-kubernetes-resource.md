---
title: "Use a raw Kubernetes resource"
description: "Fall back to a plain Kubernetes object when no OPM abstraction covers what you need."
type: how-to
weight: 23
---

<!-- One sentence: a component can carry Kubernetes objects written in their native shape through the `objects` resource of the abstraction catalog (`#Objects` in `opmodel.dev/catalogs/opm/resources/v1alpha1`), which renders each one as written. It is the last resort, for objects no abstraction models: a custom resource instance (Issuer, IPAddressPool, ServiceMonitor) or a kind such as StorageClass, CSIDriver or APIService.
Say plainly what the reader gives up: an objects entry takes no traits and joins no blueprint, and the member is alpha (`v1alpha1`): a catalog release may tighten it.
It needs nothing beyond the abstraction catalog the module already depends on: no extra dependency, no extra platform subscription.
Check against: catalog_opm/src/resources/v1alpha1/objects.cue, catalog_opm/src/catalog.cue -->

## Before you begin

<!-- By title: a module, as built in "Your first module". Having read "Choose a blueprint" and "Attach a trait to a component", since step 1 sends most readers back there. The module pins `opmodel.dev/catalogs/opm@v4` at the first release carrying `objects@v1alpha1` or later; verify the version in catalog_opm/CHANGELOG.md at writing time.
Check against: opm/docs/site/authoring/your-first-module.md, catalog_opm/docs/site/authoring/choose-a-blueprint.md, catalog_opm/docs/site/authoring/attach-a-trait.md, catalog_opm/CHANGELOG.md -->

## Steps

1. Check whether an abstraction covers the object.

   <!-- Forks as conditions; stop here when one applies:
   - If it is a Deployment, StatefulSet, DaemonSet, Job or CronJob, use a blueprint: "Choose a blueprint".
   - If it is a Service, attach the Expose trait. A HorizontalPodAutoscaler is the Scaling trait's `auto` block. A PodDisruptionBudget is the DisruptionBudget trait. A NetworkPolicy is the NetworkPolicy trait. See "Attach a trait to a component".
   - If it is a PersistentVolumeClaim, use the Volumes resource; a ConfigMap, the ConfigMaps resource; a ServiceAccount, the ServiceAccount resource or the WorkloadIdentity trait; a Role, RoleBinding, ClusterRole or ClusterRoleBinding, the Role resource with `scope: "namespace"` or `"cluster"` (it renders the binding from `subjects`). All in `opmodel.dev/catalogs/opm/resources/v1beta1`.
   - If it is a Namespace, a ValidatingWebhookConfiguration or a MutatingWebhookConfiguration, use `#Namespaces`, `#ValidatingWebhooks` or `#MutatingWebhooks` from `resources/v1alpha1` (alpha).
   - If it is an Ingress, there is no Ingress abstraction; the route traits render Gateway API routes instead. Write an Ingress as an objects entry only when the cluster serves Ingress and not the Gateway API.
   - Secrets: leave out of this page; secrets documentation is pending.
   - Otherwise (APIService, CSIDriver, IngressClass, Pod, PersistentVolume, StorageClass, or a custom resource) continue with `#Objects`.
   Check against: catalog_opm/src/resources/v1beta1/, catalog_opm/src/resources/v1alpha1/, catalog_opm/src/traits/v1beta1/, catalog_opm/src/transformers/role_transformer.cue -->

2. Import the resource package.

   <!-- `resa "opmodel.dev/catalogs/opm/resources/v1alpha1"`. The alias is the author's choice; pick one that does not collide with `res`, the usual alias for `resources/v1beta1`.
   Check against: catalog_opm/src/resources/v1alpha1/objects.cue -->

3. Give the objects a component of their own.

   <!-- A new entry in `#components` that embeds `resa.#Objects` and writes each object under `spec: objects: <name>:` exactly as the API server takes it: `apiVersion`, `kind`, `metadata`, `spec` and any other top-level field. One component may hold many objects; each renders as one object.
   The objects resource may also sit beside a workload's resources in the same component (a ServiceMonitor next to the workload it scrapes); its transformer renders the entries independently of the rest. A trait attached to a component holding only objects matches no transformer and is reported as unhandled.
   Show one example with two entries: a ClusterRole (built-in, cluster-scoped) and a cert-manager ClusterIssuer with `#scope: "Cluster"` (custom).
   Check against: catalog_opm/src/resources/v1alpha1/objects.cue (#Objects, #ObjectSchema), catalog_opm/src/transformers/objects_transformer.cue (fixtures, including the embedded form) -->

4. Name each object as it must appear in the cluster.

   <!-- The map key is `metadata.name` unless the entry sets one, and the name renders exactly as written: never prefixed with the instance or component name, so references between objects (`roleRef.name`, a backend's Service name) hold.
   The cost: two instances of one module in one namespace, or two modules choosing the same name, render the same object. Put the instance name into each name when a module can be installed twice in one namespace. `metadata.resourceName` on the component does not rename these objects.
   Check against: catalog_opm/src/transformers/objects_transformer.cue, catalog_opm/docs/name-constraints.md (the #ObjectsResource row) -->

5. State the scope of a custom resource.

   <!-- A built-in kind takes its scope from the catalog's kind table; write nothing. Any other kind needs the definition field `#scope: "Namespaced"` or `#scope: "Cluster"` on the entry. It is OPM's input, never rendered.
   - A Namespaced object without `metadata.namespace` renders into the instance's namespace; one that sets it keeps it.
   - A Cluster object must not set `metadata.namespace`; the render refuses it.
   - Labels you write merge over OPM's context labels, and yours win on a clash. Annotations and every other field pass through untouched.
   Check against: catalog_opm/src/resources/v1alpha1/objects.cue, catalog_opm/src/schemas/kinds/table.cue, catalog_opm/src/transformers/objects_transformer.cue -->

6. Fix what validation refuses.

   <!-- A built-in kind (any apiVersion and kind Kubernetes 1.36 serves) is checked against its closed upstream definition at `opm module vet` and `opm module build`: an unknown field, a wrong type or a missing required field is refused with the field's path. There is no per-object way to switch this off; a field added after Kubernetes 1.36 is refused until the catalog raises its ceiling. Values are checked by type only: an invalid enum value or quantity passes.
   Quote each refusal verbatim, with its fix:
   - `field not allowed` at `...spec.objects.<name>.<field>`: a typo, or a field the kind does not have in 1.36.
   - `<apiVersion> <kind> is not a Kubernetes 1.36 kind, and its API group is built in: check apiVersion and kind` (for example `apps/v2`).
   - `<apiVersion> <kind> is not a Kubernetes 1.36 object kind: set #scope to "Namespaced" or "Cluster"`: a custom resource without `#scope`.
   - `<apiVersion> <kind> is cluster-scoped: remove metadata.namespace`.
   - `#scope: conflicting values "Namespaced" and "Cluster"`: a `#scope` that disagrees with a built-in kind's scope; remove it.
   A custom resource is not validated. An author may unify an entry with a schema they import themselves (for example from `cue.dev/x/crd/...`); the catalog ships none.
   Check against: catalog_opm/src/resources/v1alpha1/objects.cue, catalog_opm/src/transformers/objects_transformer.cue (_testObjectsRefused), catalog_opm/openspec/changes/archive/*-add-objects-resource/design.md (Research & Decisions) -->

## Check that it worked

<!-- Command: `opm module build` (with `--platform <dir>` when the target is a cluster; `opm platform pull <dir>` writes the cluster's platform, and any platform subscribing to `opmodel.dev/catalogs/opm@v4` at the release carrying this member serves it).
Success: a line `▸ <component> ← opmodel.dev/catalogs/opm/transformers/objects-transformer@<catalog version>` and each object in the YAML with your fields intact, its name as written, and a namespace only on namespaced objects. A refusal naming an unresolved demand for `objects@v1alpha1` means the platform's catalog predates the member: see "Unresolved demands".
Check against: cli/internal/workflow/render/log_output.go, catalog_opm/src/transformers/objects_transformer.cue -->

## Related

<!-- By title: the reference page "Objects" (the generated member page, which lists every built-in kind and its scope) and the concept page "Platforms and catalogs".
Check against: catalog_opm/docs/site/reference/catalog-members/resources/objects.md, core/docs/site/concepts/platforms-and-catalogs.md -->
