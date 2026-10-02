# k8s — Definition Index

CUE module: `opmodel.dev/catalogs/k8s@v1`

---

## Project Structure

```
+-- identity/
+-- resources/
|   +-- v1/
|   +-- v2/
+-- schemas/
+-- transformers/
```

---

## Identity

| Definition | File | Description |
|---|---|---|
| `#VersionType` | `identity/identity.cue` | #VersionType mirrors core |

---

## Resources

### v1

| Definition | File | Description |
|---|---|---|
| `#APIService` | `resources/v1/apiservice.cue` |  |
| `#APIServiceResource` | `resources/v1/apiservice.cue` | A native Kubernetes APIService that registers an aggregated API server |
| `#ClusterRole` | `resources/v1/cluster_role.cue` |  |
| `#ClusterRoleResource` | `resources/v1/cluster_role.cue` | A native Kubernetes ClusterRole, granting permissions cluster-wide or in every namespace |
| `#ClusterRoleBinding` | `resources/v1/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingResource` | `resources/v1/cluster_role_binding.cue` | A native Kubernetes ClusterRoleBinding that binds a ClusterRole to subjects cluster-wide |
| `#ConfigMap` | `resources/v1/configmap.cue` |  |
| `#ConfigMapResource` | `resources/v1/configmap.cue` | A native Kubernetes ConfigMap of non-sensitive key-value data |
| `#CronJob` | `resources/v1/cronjob.cue` |  |
| `#CronJobResource` | `resources/v1/cronjob.cue` | A native Kubernetes CronJob that runs a job on a cron schedule |
| `#CSIDriver` | `resources/v1/csidriver.cue` |  |
| `#CSIDriverResource` | `resources/v1/csidriver.cue` | A native Kubernetes CSIDriver, rendered under its authored name |
| `#DaemonSet` | `resources/v1/daemonset.cue` |  |
| `#DaemonSetResource` | `resources/v1/daemonset.cue` | A native Kubernetes DaemonSet that runs a pod on every node, or on selected nodes |
| `#Deployment` | `resources/v1/deployment.cue` |  |
| `#DeploymentResource` | `resources/v1/deployment.cue` | A native Kubernetes Deployment, for direct control over the Deployment spec |
| `#Ingress` | `resources/v1/ingress.cue` |  |
| `#IngressResource` | `resources/v1/ingress.cue` | A native Kubernetes Ingress that routes external HTTP and HTTPS traffic to services |
| `#IngressClass` | `resources/v1/ingressclass.cue` |  |
| `#IngressClassResource` | `resources/v1/ingressclass.cue` | A native Kubernetes IngressClass that configures an ingress controller implementation |
| `#Job` | `resources/v1/job.cue` |  |
| `#JobResource` | `resources/v1/job.cue` | A native Kubernetes Job for a batch or one-off task that runs to completion |
| `#MutatingWebhookConfiguration` | `resources/v1/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationResource` | `resources/v1/mutating_webhook.cue` | A native Kubernetes MutatingWebhookConfiguration that registers mutating admission webhooks |
| `#Namespace` | `resources/v1/namespace.cue` |  |
| `#NamespaceResource` | `resources/v1/namespace.cue` | A native Kubernetes Namespace |
| `#NetworkPolicy` | `resources/v1/networkpolicy.cue` |  |
| `#NetworkPolicyResource` | `resources/v1/networkpolicy.cue` | A native Kubernetes NetworkPolicy that controls ingress and egress traffic between pods |
| `#ObjectEntrySchema` | `resources/v1/object.cue` | A single arbitrary object plus its scope discriminator |
| `#Objects` | `resources/v1/object.cue` |  |
| `#ObjectsResource` | `resources/v1/object.cue` | Arbitrary Kubernetes objects, including Custom Resource instances |
| `#PodDisruptionBudget` | `resources/v1/pdb.cue` |  |
| `#PodDisruptionBudgetResource` | `resources/v1/pdb.cue` | A native Kubernetes PodDisruptionBudget that limits voluntary disruptions |
| `#Pod` | `resources/v1/pod.cue` |  |
| `#PodResource` | `resources/v1/pod.cue` | A native Kubernetes Pod, standalone |
| `#PersistentVolume` | `resources/v1/pv.cue` |  |
| `#PersistentVolumeResource` | `resources/v1/pv.cue` | A native Kubernetes PersistentVolume, provisioned at cluster scope |
| `#PersistentVolumeClaim` | `resources/v1/pvc.cue` |  |
| `#PersistentVolumeClaimResource` | `resources/v1/pvc.cue` | A native Kubernetes PersistentVolumeClaim that requests persistent storage |
| `#Role` | `resources/v1/role.cue` |  |
| `#RoleResource` | `resources/v1/role.cue` | A native Kubernetes Role that grants permissions within a namespace |
| `#RoleBinding` | `resources/v1/role_binding.cue` |  |
| `#RoleBindingResource` | `resources/v1/role_binding.cue` | A native Kubernetes RoleBinding that binds a Role or ClusterRole to subjects in a namespace |
| `#Secret` | `resources/v1/secret.cue` |  |
| `#SecretResource` | `resources/v1/secret.cue` | A native Kubernetes Secret for sensitive data such as passwords, tokens and TLS certificates |
| `#Service` | `resources/v1/service.cue` |  |
| `#ServiceResource` | `resources/v1/service.cue` | A native Kubernetes Service that exposes workloads inside or outside the cluster |
| `#ServiceAccount` | `resources/v1/serviceaccount.cue` |  |
| `#ServiceAccountResource` | `resources/v1/serviceaccount.cue` | A native Kubernetes ServiceAccount that gives pods an identity |
| `#StatefulSet` | `resources/v1/statefulset.cue` |  |
| `#StatefulSetResource` | `resources/v1/statefulset.cue` | A native Kubernetes StatefulSet, for direct control over the StatefulSet spec |
| `#StorageClass` | `resources/v1/storageclass.cue` |  |
| `#StorageClassResource` | `resources/v1/storageclass.cue` | A native Kubernetes StorageClass that configures a storage provisioner |
| `#ValidatingWebhookConfiguration` | `resources/v1/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationResource` | `resources/v1/validating_webhook.cue` | A native Kubernetes ValidatingWebhookConfiguration that registers validating admission webhooks |
| `#VolumeSnapshotClass` | `resources/v1/volumesnapshotclass.cue` |  |
| `#VolumeSnapshotClassResource` | `resources/v1/volumesnapshotclass.cue` | A native Kubernetes VolumeSnapshotClass that configures a snapshot driver |

### v2

| Definition | File | Description |
|---|---|---|
| `#HorizontalPodAutoscaler` | `resources/v2/hpa.cue` |  |
| `#HorizontalPodAutoscalerResource` | `resources/v2/hpa.cue` | A native Kubernetes HorizontalPodAutoscaler that scales replicas on metrics |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#MutatingWebhookConfigurationSchema` | `schemas/admission.cue` | #MutatingWebhookConfigurationSchema accepts the full Kubernetes MutatingWebhookConfiguration spec |
| `#ValidatingWebhookConfigurationSchema` | `schemas/admission.cue` | #ValidatingWebhookConfigurationSchema accepts the full Kubernetes ValidatingWebhookConfiguration spec |
| `#APIServiceSchema` | `schemas/apiregistration.cue` | #APIServiceSchema is an open schema for an aggregated APIService (apiregistration |
| `#NamespaceSchema` | `schemas/cluster.cue` | #NamespaceSchema accepts the full Kubernetes Namespace spec |
| `#ConfigMapSchema` | `schemas/config.cue` | #ConfigMapSchema accepts the full Kubernetes ConfigMap spec |
| `#SecretSchema` | `schemas/config.cue` | #SecretSchema accepts the full Kubernetes Secret spec |
| `#IngressClassSchema` | `schemas/network.cue` | #IngressClassSchema accepts the full Kubernetes IngressClass spec |
| `#IngressSchema` | `schemas/network.cue` | #IngressSchema accepts the full Kubernetes Ingress spec |
| `#NetworkPolicySchema` | `schemas/network.cue` | #NetworkPolicySchema accepts the full Kubernetes NetworkPolicy spec |
| `#ServiceSchema` | `schemas/network.cue` | #ServiceSchema accepts the full Kubernetes Service spec |
| `#HorizontalPodAutoscalerSchema` | `schemas/policy.cue` | #HorizontalPodAutoscalerSchema accepts the full Kubernetes HPA v2 spec |
| `#PodDisruptionBudgetSchema` | `schemas/policy.cue` | #PodDisruptionBudgetSchema accepts the full Kubernetes PodDisruptionBudget spec |
| `#ClusterRoleBindingSchema` | `schemas/rbac.cue` | #ClusterRoleBindingSchema accepts the full Kubernetes ClusterRoleBinding spec |
| `#ClusterRoleSchema` | `schemas/rbac.cue` | #ClusterRoleSchema accepts the full Kubernetes ClusterRole spec |
| `#RoleBindingSchema` | `schemas/rbac.cue` | #RoleBindingSchema accepts the full Kubernetes RoleBinding spec |
| `#RoleSchema` | `schemas/rbac.cue` | #RoleSchema accepts the full Kubernetes Role spec |
| `#ServiceAccountSchema` | `schemas/rbac.cue` | #ServiceAccountSchema accepts the full Kubernetes ServiceAccount spec |
| `#CSIDriverSchema` | `schemas/storage.cue` | #CSIDriverSchema accepts the full Kubernetes CSIDriver (storage |
| `#PersistentVolumeClaimSchema` | `schemas/storage.cue` | #PersistentVolumeClaimSchema accepts the full Kubernetes PVC spec |
| `#PersistentVolumeSchema` | `schemas/storage.cue` | #PersistentVolumeSchema accepts the full Kubernetes PV spec |
| `#StorageClassSchema` | `schemas/storage.cue` | #StorageClassSchema accepts the full Kubernetes StorageClass spec |
| `#VolumeSnapshotClassSchema` | `schemas/storage.cue` | #VolumeSnapshotClassSchema accepts the full VolumeSnapshotClass (snapshot |
| `#CronJobSchema` | `schemas/workload.cue` | #CronJobSchema accepts the full Kubernetes CronJob spec |
| `#DaemonSetSchema` | `schemas/workload.cue` | #DaemonSetSchema accepts the full Kubernetes DaemonSet spec |
| `#DeploymentSchema` | `schemas/workload.cue` | #DeploymentSchema accepts the full Kubernetes Deployment spec |
| `#JobSchema` | `schemas/workload.cue` | #JobSchema accepts the full Kubernetes Job spec |
| `#PodSchema` | `schemas/workload.cue` | #PodSchema accepts the full Kubernetes Pod spec |
| `#StatefulSetSchema` | `schemas/workload.cue` | #StatefulSetSchema accepts the full Kubernetes StatefulSet spec |

---

## Transformers

| Definition | File | Description |
|---|---|---|
| `#APIServiceTransformer` | `transformers/apiservice_transformer.cue` | #APIServiceTransformer passes native Kubernetes APIService resources through with OPM context applied (labels) |
| `#ClusterRoleBindingTransformer` | `transformers/cluster_role_binding_transformer.cue` | #ClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through with OPM context applied (name from the component's `#names`, labels) |
| `#ClusterRoleTransformer` | `transformers/cluster_role_transformer.cue` | #ClusterRoleTransformer passes native Kubernetes ClusterRole resources through with OPM context applied (name from the component's `#names`, labels) |
| `#ConfigMapTransformer` | `transformers/configmap_transformer.cue` | #ConfigMapTransformer passes native Kubernetes ConfigMap resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#CronJobTransformer` | `transformers/cronjob_transformer.cue` | #CronJobTransformer passes native Kubernetes CronJob resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#CSIDriverTransformer` | `transformers/csidriver_transformer.cue` | #CSIDriverTransformer passes native Kubernetes CSIDriver resources through with OPM labels applied |
| `#DaemonSetTransformer` | `transformers/daemonset_transformer.cue` | #DaemonSetTransformer passes native Kubernetes DaemonSet resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#DeploymentTransformer` | `transformers/deployment_transformer.cue` | #DeploymentTransformer passes native Kubernetes Deployment resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#HorizontalPodAutoscalerTransformer` | `transformers/hpa_transformer.cue` | #HorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#IngressTransformer` | `transformers/ingress_transformer.cue` | #IngressTransformer passes native Kubernetes Ingress resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#IngressClassTransformer` | `transformers/ingressclass_transformer.cue` | #IngressClassTransformer passes native Kubernetes IngressClass resources through with OPM context applied (name from the component's `#names`, labels) |
| `#JobTransformer` | `transformers/job_transformer.cue` | #JobTransformer passes native Kubernetes Job resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#MutatingWebhookConfigurationTransformer` | `transformers/mutating_webhook_transformer.cue` | #MutatingWebhookConfigurationTransformer passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied |
| `#NamespaceTransformer` | `transformers/namespace_transformer.cue` | #NamespaceTransformer passes native Kubernetes Namespace resources through with OPM context applied (name from the component's `#names`, labels) |
| `#NetworkPolicyTransformer` | `transformers/networkpolicy_transformer.cue` | #NetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#ObjectTransformer` | `transformers/object_transformer.cue` | #ObjectTransformer passes arbitrary Kubernetes objects — including Custom Resource instances — through with OPM context applied (name from the component's `#names`, namespace for namespaced scope, merged labels/annotations) |
| `#PodDisruptionBudgetTransformer` | `transformers/pdb_transformer.cue` | #PodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#PodTransformer` | `transformers/pod_transformer.cue` | #PodTransformer passes native Kubernetes Pod resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#PersistentVolumeTransformer` | `transformers/pv_transformer.cue` | #PersistentVolumeTransformer passes native Kubernetes PV resources through with OPM context applied (name from the component's `#names`, labels) |
| `#PersistentVolumeClaimTransformer` | `transformers/pvc_transformer.cue` | #PersistentVolumeClaimTransformer passes native Kubernetes PVC resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#RoleBindingTransformer` | `transformers/role_binding_transformer.cue` | #RoleBindingTransformer passes native Kubernetes RoleBinding resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#RoleTransformer` | `transformers/role_transformer.cue` | #RoleTransformer passes native Kubernetes Role resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#SecretTransformer` | `transformers/secret_transformer.cue` | #SecretTransformer passes native Kubernetes Secret resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#ServiceTransformer` | `transformers/service_transformer.cue` | #ServiceTransformer passes native Kubernetes Service resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#ServiceAccountTransformer` | `transformers/serviceaccount_transformer.cue` | #ServiceAccountTransformer passes native Kubernetes ServiceAccount resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#StatefulSetTransformer` | `transformers/statefulset_transformer.cue` | #StatefulSetTransformer passes native Kubernetes StatefulSet resources through with OPM context applied (name from the component's `#names`, namespace, labels) |
| `#StorageClassTransformer` | `transformers/storageclass_transformer.cue` | #StorageClassTransformer passes native Kubernetes StorageClass resources through with OPM context applied (name from the component's `#names`, labels) |
| `#ValidatingWebhookConfigurationTransformer` | `transformers/validating_webhook_transformer.cue` | #ValidatingWebhookConfigurationTransformer passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied |
| `#VolumeSnapshotClassTransformer` | `transformers/volumesnapshotclass_transformer.cue` | #VolumeSnapshotClassTransformer passes native VolumeSnapshotClass resources through with OPM context applied: the name is the component's resourceName (instance-prefixed by default, `metadata |

---

