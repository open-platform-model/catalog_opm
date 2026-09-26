---
title: "Use a raw Kubernetes resource"
description: "Fall back to a plain Kubernetes object when no OPM abstraction covers what you need."
type: how-to
sidebar:
  order: 23
---

<!-- One sentence: a component can carry a Kubernetes object written in its native shape, from the raw catalog `opmodel.dev/catalogs/k8s@v1`, which OPM passes through with only its name, namespace and labels set. It is the last resort, for objects the abstraction catalog (`opmodel.dev/catalogs/opm@v4`) does not model.
Say plainly what the reader gives up: a raw resource takes no traits, joins no blueprint, and renders exactly one object per component (the `objects` resource excepted, one per entry). No first-party module in modules/ or opm-modules/ imports the raw catalog, and the two catalogs never import each other.
The reference page "Raw Kubernetes resources" lists every member; this page decides when to reach for one.
Check against: catalog_opm/k8s/catalog.cue (header comment), catalog_opm/Taskfile.yml (vet:layering) -->

## Before you begin

<!-- By title: a module, as built in "Your first module". Having read "Choose a blueprint" and "Attach a trait to a component", since step 1 sends most readers back there.
Check against: opm/docs/site/authoring/your-first-module.md, catalog_opm/docs/site/authoring/choose-a-blueprint.md, catalog_opm/docs/site/authoring/attach-a-trait.md -->

## Steps

1. Check whether an abstraction covers the object.

   <!-- Forks as conditions; stop here when one applies:
   - If it is a Deployment, StatefulSet, DaemonSet, Job or CronJob, use a blueprint: "Choose a blueprint".
   - If it is a Service, attach the Expose trait. A HorizontalPodAutoscaler is the Scaling trait's `auto` block. A PodDisruptionBudget is the DisruptionBudget trait. A NetworkPolicy is the NetworkPolicy trait. See "Attach a trait to a component".
   - If it is a PersistentVolumeClaim, use the Volumes resource; a ConfigMap, the ConfigMaps resource; a ServiceAccount, the ServiceAccount resource or the WorkloadIdentity trait; a Role, RoleBinding, ClusterRole or ClusterRoleBinding, the Role resource with `scope: "namespace"` or `"cluster"` (it renders the binding from `subjects`). All in `opmodel.dev/catalogs/opm/resources/v1beta1`.
   - If it is a Namespace, a ValidatingWebhookConfiguration or a MutatingWebhookConfiguration, use `#Namespaces`, `#ValidatingWebhooks` or `#MutatingWebhooks` from `resources/v1alpha1` (alpha).
   - If it is an Ingress, there is no Ingress abstraction; the route traits render Gateway API routes instead. Use the raw `ingress` member only when the cluster serves Ingress and not the Gateway API.
   - Secrets: leave out of this page; secrets documentation is pending.
   - Otherwise (APIService, CSIDriver, IngressClass, Pod, PersistentVolume, StorageClass, VolumeSnapshotClass, or a custom resource) continue with the raw catalog.
   Check against: catalog_opm/opm/resources/v1beta1/, catalog_opm/opm/resources/v1alpha1/, catalog_opm/opm/traits/v1beta1/, catalog_opm/opm/transformers/role_transformer.cue, catalog_opm/k8s/resources/v1/ -->

2. Add the raw catalog as a dependency.

   <!-- The module's `cue.mod/module.cue` needs `opmodel.dev/catalogs/k8s@v1` in `deps`. With the CUE toolchain: `cue mod get opmodel.dev/catalogs/k8s@v1` in the module directory. Without it: add the entry by hand.
   Pin the build the target platform carries. `opm config init` pins v1.0.0-alpha.3 in the local default platform, while the latest release is 1.0.0-alpha.4 (catalog_opm/CHANGELOG-k8s.md). A module that requires a newer build than the platform gets a "version skew" warning, or a refusal under `skewPolicy: "refuse"`. Verify both versions at writing time.
   Check against: cli/internal/config/templates.go (DefaultCatalogPaths, DefaultCatalogPins, skewPolicy), catalog_opm/k8s/cue.mod/module.cue, cli/internal/workflow/render/render.go (formatAdvisories) -->

3. Import the resource package.

   <!-- `k8s "opmodel.dev/catalogs/k8s/resources/v1"`; the HorizontalPodAutoscaler lives in `resources/v2`. The alias is the author's choice; pick one that does not collide with the abstraction catalog's `res`.
   Check against: catalog_opm/k8s/resources/v1/, catalog_opm/k8s/resources/v2/hpa.cue -->

4. Give the object a component of its own.

   <!-- A new entry in `#components` that embeds the wrapper (`k8s.#StorageClass`, `k8s.#Objects`) and writes the object under the wrapper's spec key, which is the lower-case kind: `spec: storageclass: {...}`, `spec: deployment: {spec: ...}`. Nothing else goes in the component: no blueprint, no traits. A trait attached here matches no transformer and is reported as unhandled.
   What OPM overrides: `metadata.name` comes from the component's resource name (`<instance>-<component>`), `metadata.namespace` from the instance, labels from the render context; the Deployment transformer, for example, passes only `metadata.annotations` through from what you write. To pin an exact name, set `metadata: resourceName:` on the component. Verify the pass-through per kind; only deployment, service, configmap, clusterrole, namespace and objects were checked.
   - If the object is a custom resource or a kind with no typed member, use `k8s.#Objects`: `spec: objects: <entry>: {scope: "Namespaced" | "Cluster", object: {apiVersion: ..., kind: ..., ...}}`. It renders one object per entry, named `<resource name>-<entry name or metadata.name>`, gets a namespace only when `scope` is `"Namespaced"` (the default), and merges your labels over the context labels. Prefer a typed member where one exists.
   Check against: catalog_opm/k8s/resources/v1/deployment.cue, catalog_opm/k8s/resources/v1/object.cue, catalog_opm/k8s/transformers/deployment_transformer.cue, catalog_opm/k8s/transformers/object_transformer.cue, modules/DESIGN_PATTERNS.md ("Exact object names") -->

5. Make sure the target platform carries the raw catalog.

   <!-- The local default platform from `opm config init` subscribes to both catalogs. A cluster Platform seeded by `opm operator install` subscribes only to `opmodel.dev/catalogs/opm`, so a render against it refuses with an unresolved resource demand: "no enabled catalog defines this contract".
   - If the module will render against a cluster, reproduce the cluster's platform locally with `opm platform pull <dir>` and build against it with `opm module build --platform <dir>`; `opm platform check <dir>` lists the contracts the platform's catalogs define. If the raw catalog is missing, the platform's owner has to add it; see "Platforms and catalogs".
   Check against: cli/internal/config/templates.go (DefaultCatalogPath), cli/internal/cmd/operator/install.go, cli/internal/cmd/platform/pull.go, cli/internal/cmd/platform/check.go, library/opm/errors/match.go (describe) -->

## Check that it worked

<!-- Command: `opm module build` (with `--platform <dir>` from step 5 when the target is a cluster).
Success: a line `▸ <component> ← opmodel.dev/catalogs/k8s/transformers/<kind>-transformer@<catalog version>` (`<kind>` is the lower-case kind; the `objects` member's is `object-transformer`) and the object in the YAML with your spec intact and OPM's name and namespace. A refusal naming an unresolved demand points at "Unresolved demands".
Check against: cli/internal/workflow/render/log_output.go, catalog_opm/k8s/transformers/ -->

## Related

<!-- By title: the reference entry "Raw Kubernetes resources" (the generated table, each entry pointing at its abstraction) and the concept page "Platforms and catalogs".
Check against: catalog_opm/docs/site/reference/kubernetes-resources.md, core/docs/site/concepts/platforms-and-catalogs.md, catalog_opm/k8s/INDEX.md -->
