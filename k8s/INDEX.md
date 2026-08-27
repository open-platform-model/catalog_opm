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
| `#APIServiceResource` | `resources/v1/apiservice.cue` | #APIServiceResource defines a native Kubernetes APIService (apiregistration |
| `#ClusterRole` | `resources/v1/cluster_role.cue` |  |
| `#ClusterRoleResource` | `resources/v1/cluster_role.cue` | #ClusterRoleResource defines a native Kubernetes ClusterRole as an OPM resource |
| `#ClusterRoleBinding` | `resources/v1/cluster_role_binding.cue` |  |
| `#ClusterRoleBindingResource` | `resources/v1/cluster_role_binding.cue` | #ClusterRoleBindingResource defines a native Kubernetes ClusterRoleBinding as an OPM resource |
| `#ConfigMap` | `resources/v1/configmap.cue` |  |
| `#ConfigMapResource` | `resources/v1/configmap.cue` | #ConfigMapResource defines a native Kubernetes ConfigMap as an OPM resource |
| `#CronJob` | `resources/v1/cronjob.cue` |  |
| `#CronJobResource` | `resources/v1/cronjob.cue` | #CronJobResource defines a native Kubernetes CronJob as an OPM resource |
| `#CSIDriver` | `resources/v1/csidriver.cue` |  |
| `#CSIDriverResource` | `resources/v1/csidriver.cue` | #CSIDriverResource defines a native Kubernetes CSIDriver as an OPM resource |
| `#DaemonSet` | `resources/v1/daemonset.cue` |  |
| `#DaemonSetResource` | `resources/v1/daemonset.cue` | #DaemonSetResource defines a native Kubernetes DaemonSet as an OPM resource |
| `#Deployment` | `resources/v1/deployment.cue` |  |
| `#DeploymentResource` | `resources/v1/deployment.cue` | #DeploymentResource defines a native Kubernetes Deployment as an OPM resource |
| `#Ingress` | `resources/v1/ingress.cue` |  |
| `#IngressResource` | `resources/v1/ingress.cue` | #IngressResource defines a native Kubernetes Ingress as an OPM resource |
| `#IngressClass` | `resources/v1/ingressclass.cue` |  |
| `#IngressClassResource` | `resources/v1/ingressclass.cue` | #IngressClassResource defines a native Kubernetes IngressClass as an OPM resource |
| `#Job` | `resources/v1/job.cue` |  |
| `#JobResource` | `resources/v1/job.cue` | #JobResource defines a native Kubernetes Job as an OPM resource |
| `#MutatingWebhookConfiguration` | `resources/v1/mutating_webhook.cue` |  |
| `#MutatingWebhookConfigurationResource` | `resources/v1/mutating_webhook.cue` | #MutatingWebhookConfigurationResource defines a native Kubernetes MutatingWebhookConfiguration as an OPM resource |
| `#Namespace` | `resources/v1/namespace.cue` |  |
| `#NamespaceResource` | `resources/v1/namespace.cue` | #NamespaceResource defines a native Kubernetes Namespace as an OPM resource |
| `#NetworkPolicy` | `resources/v1/networkpolicy.cue` |  |
| `#NetworkPolicyResource` | `resources/v1/networkpolicy.cue` | #NetworkPolicyResource defines a native Kubernetes NetworkPolicy as an OPM resource |
| `#ObjectEntrySchema` | `resources/v1/object.cue` | A single arbitrary object plus its scope discriminator |
| `#Objects` | `resources/v1/object.cue` |  |
| `#ObjectsResource` | `resources/v1/object.cue` | #ObjectsResource renders arbitrary Kubernetes objects — built-in kinds OR Custom Resource instances (Issuer, Gateway, MongoDBCommunity, …) |
| `#PodDisruptionBudget` | `resources/v1/pdb.cue` |  |
| `#PodDisruptionBudgetResource` | `resources/v1/pdb.cue` | #PodDisruptionBudgetResource defines a native Kubernetes PodDisruptionBudget as an OPM resource |
| `#Pod` | `resources/v1/pod.cue` |  |
| `#PodResource` | `resources/v1/pod.cue` | #PodResource defines a native Kubernetes Pod as an OPM resource |
| `#PersistentVolume` | `resources/v1/pv.cue` |  |
| `#PersistentVolumeResource` | `resources/v1/pv.cue` | #PersistentVolumeResource defines a native Kubernetes PV as an OPM resource |
| `#PersistentVolumeClaim` | `resources/v1/pvc.cue` |  |
| `#PersistentVolumeClaimResource` | `resources/v1/pvc.cue` | #PersistentVolumeClaimResource defines a native Kubernetes PVC as an OPM resource |
| `#Role` | `resources/v1/role.cue` |  |
| `#RoleResource` | `resources/v1/role.cue` | #RoleResource defines a native Kubernetes Role as an OPM resource |
| `#RoleBinding` | `resources/v1/role_binding.cue` |  |
| `#RoleBindingResource` | `resources/v1/role_binding.cue` | #RoleBindingResource defines a native Kubernetes RoleBinding as an OPM resource |
| `#Secret` | `resources/v1/secret.cue` |  |
| `#SecretResource` | `resources/v1/secret.cue` | #SecretResource defines a native Kubernetes Secret as an OPM resource |
| `#Service` | `resources/v1/service.cue` |  |
| `#ServiceResource` | `resources/v1/service.cue` | #ServiceResource defines a native Kubernetes Service as an OPM resource |
| `#ServiceAccount` | `resources/v1/serviceaccount.cue` |  |
| `#ServiceAccountResource` | `resources/v1/serviceaccount.cue` | #ServiceAccountResource defines a native Kubernetes ServiceAccount as an OPM resource |
| `#StatefulSet` | `resources/v1/statefulset.cue` |  |
| `#StatefulSetResource` | `resources/v1/statefulset.cue` | #StatefulSetResource defines a native Kubernetes StatefulSet as an OPM resource |
| `#StorageClass` | `resources/v1/storageclass.cue` |  |
| `#StorageClassResource` | `resources/v1/storageclass.cue` | #StorageClassResource defines a native Kubernetes StorageClass as an OPM resource |
| `#ValidatingWebhookConfiguration` | `resources/v1/validating_webhook.cue` |  |
| `#ValidatingWebhookConfigurationResource` | `resources/v1/validating_webhook.cue` | #ValidatingWebhookConfigurationResource defines a native Kubernetes ValidatingWebhookConfiguration as an OPM resource |
| `#VolumeSnapshotClass` | `resources/v1/volumesnapshotclass.cue` |  |
| `#VolumeSnapshotClassResource` | `resources/v1/volumesnapshotclass.cue` | #VolumeSnapshotClassResource defines a native VolumeSnapshotClass (snapshot |

### v2

| Definition | File | Description |
|---|---|---|
| `#HorizontalPodAutoscaler` | `resources/v2/hpa.cue` |  |
| `#HorizontalPodAutoscalerResource` | `resources/v2/hpa.cue` | #HorizontalPodAutoscalerResource defines a native Kubernetes HPA v2 as an OPM resource |

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
| `#ClusterRoleBindingTransformer` | `transformers/cluster_role_binding_transformer.cue` | #ClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through with OPM context applied (name prefix, labels) |
| `#ClusterRoleTransformer` | `transformers/cluster_role_transformer.cue` | #ClusterRoleTransformer passes native Kubernetes ClusterRole resources through with OPM context applied (name prefix, labels) |
| `#ConfigMapTransformer` | `transformers/configmap_transformer.cue` | #ConfigMapTransformer passes native Kubernetes ConfigMap resources through with OPM context applied (name prefix, namespace, labels) |
| `#CronJobTransformer` | `transformers/cronjob_transformer.cue` | #CronJobTransformer passes native Kubernetes CronJob resources through with OPM context applied (name prefix, namespace, labels) |
| `#CSIDriverTransformer` | `transformers/csidriver_transformer.cue` | #CSIDriverTransformer passes native Kubernetes CSIDriver resources through with OPM labels applied |
| `#DaemonSetTransformer` | `transformers/daemonset_transformer.cue` | #DaemonSetTransformer passes native Kubernetes DaemonSet resources through with OPM context applied (name prefix, namespace, labels) |
| `#DeploymentTransformer` | `transformers/deployment_transformer.cue` | #DeploymentTransformer passes native Kubernetes Deployment resources through with OPM context applied (name prefix, namespace, labels) |
| `#HorizontalPodAutoscalerTransformer` | `transformers/hpa_transformer.cue` | #HorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through with OPM context applied (name prefix, namespace, labels) |
| `#IngressTransformer` | `transformers/ingress_transformer.cue` | #IngressTransformer passes native Kubernetes Ingress resources through with OPM context applied (name prefix, namespace, labels) |
| `#IngressClassTransformer` | `transformers/ingressclass_transformer.cue` | #IngressClassTransformer passes native Kubernetes IngressClass resources through with OPM context applied (name prefix, labels) |
| `#JobTransformer` | `transformers/job_transformer.cue` | #JobTransformer passes native Kubernetes Job resources through with OPM context applied (name prefix, namespace, labels) |
| `#MutatingWebhookConfigurationTransformer` | `transformers/mutating_webhook_transformer.cue` | #MutatingWebhookConfigurationTransformer passes native Kubernetes MutatingWebhookConfiguration resources through with OPM context applied |
| `#NamespaceTransformer` | `transformers/namespace_transformer.cue` | #NamespaceTransformer passes native Kubernetes Namespace resources through with OPM context applied (name prefix, labels) |
| `#NetworkPolicyTransformer` | `transformers/networkpolicy_transformer.cue` | #NetworkPolicyTransformer passes native Kubernetes NetworkPolicy resources through with OPM context applied (name prefix, namespace, labels) |
| `#ObjectTransformer` | `transformers/object_transformer.cue` | #ObjectTransformer passes arbitrary Kubernetes objects — including Custom Resource instances — through with OPM context applied (name prefix, namespace for namespaced scope, merged labels/annotations) |
| `#PodDisruptionBudgetTransformer` | `transformers/pdb_transformer.cue` | #PodDisruptionBudgetTransformer passes native Kubernetes PodDisruptionBudget resources through with OPM context applied (name prefix, namespace, labels) |
| `#PodTransformer` | `transformers/pod_transformer.cue` | #PodTransformer passes native Kubernetes Pod resources through with OPM context applied (name prefix, namespace, labels) |
| `#PersistentVolumeTransformer` | `transformers/pv_transformer.cue` | #PersistentVolumeTransformer passes native Kubernetes PV resources through with OPM context applied (name prefix, labels) |
| `#PersistentVolumeClaimTransformer` | `transformers/pvc_transformer.cue` | #PersistentVolumeClaimTransformer passes native Kubernetes PVC resources through with OPM context applied (name prefix, namespace, labels) |
| `#RoleBindingTransformer` | `transformers/role_binding_transformer.cue` | #RoleBindingTransformer passes native Kubernetes RoleBinding resources through with OPM context applied (name prefix, namespace, labels) |
| `#RoleTransformer` | `transformers/role_transformer.cue` | #RoleTransformer passes native Kubernetes Role resources through with OPM context applied (name prefix, namespace, labels) |
| `#SecretTransformer` | `transformers/secret_transformer.cue` | #SecretTransformer passes native Kubernetes Secret resources through with OPM context applied (name prefix, namespace, labels) |
| `#ServiceTransformer` | `transformers/service_transformer.cue` | #ServiceTransformer passes native Kubernetes Service resources through with OPM context applied (name prefix, namespace, labels) |
| `#ServiceAccountTransformer` | `transformers/serviceaccount_transformer.cue` | #ServiceAccountTransformer passes native Kubernetes ServiceAccount resources through with OPM context applied (name prefix, namespace, labels) |
| `#StatefulSetTransformer` | `transformers/statefulset_transformer.cue` | #StatefulSetTransformer passes native Kubernetes StatefulSet resources through with OPM context applied (name prefix, namespace, labels) |
| `#StorageClassTransformer` | `transformers/storageclass_transformer.cue` | #StorageClassTransformer passes native Kubernetes StorageClass resources through with OPM context applied (name prefix, labels) |
| `#ValidatingWebhookConfigurationTransformer` | `transformers/validating_webhook_transformer.cue` | #ValidatingWebhookConfigurationTransformer passes native Kubernetes ValidatingWebhookConfiguration resources through with OPM context applied |
| `#VolumeSnapshotClassTransformer` | `transformers/volumesnapshotclass_transformer.cue` | #VolumeSnapshotClassTransformer passes native VolumeSnapshotClass resources through with OPM context applied: the name is the component's resourceName (instance-prefixed by default, `metadata |

---

