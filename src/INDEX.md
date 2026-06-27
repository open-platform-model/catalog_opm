# catalog_opm — Definition Index

CUE module: `opmodel.dev/catalogs/opm@v1`

---

## Project Structure

```
```

---

## Blueprints

### workload

| Definition | File | Description |
|---|---|---|
| `#DaemonWorkload` | `blueprints/workload/daemon_workload.cue` |  |
| `#DaemonWorkloadBlueprint` | `blueprints/workload/daemon_workload.cue` |  |
| `#DaemonWorkloadSchema` | `blueprints/workload/daemon_workload.cue` |  |
| `#ScheduledTaskWorkload` | `blueprints/workload/scheduled_task_workload.cue` |  |
| `#ScheduledTaskWorkloadBlueprint` | `blueprints/workload/scheduled_task_workload.cue` |  |
| `#ScheduledTaskWorkloadSchema` | `blueprints/workload/scheduled_task_workload.cue` |  |
| `#StatefulWorkload` | `blueprints/workload/stateful_workload.cue` |  |
| `#StatefulWorkloadBlueprint` | `blueprints/workload/stateful_workload.cue` |  |
| `#StatefulWorkloadSchema` | `blueprints/workload/stateful_workload.cue` |  |
| `#StatelessWorkload` | `blueprints/workload/stateless_workload.cue` |  |
| `#StatelessWorkloadBlueprint` | `blueprints/workload/stateless_workload.cue` |  |
| `#StatelessWorkloadSchema` | `blueprints/workload/stateless_workload.cue` |  |
| `#TaskWorkload` | `blueprints/workload/task_workload.cue` |  |
| `#TaskWorkloadBlueprint` | `blueprints/workload/task_workload.cue` |  |
| `#TaskWorkloadSchema` | `blueprints/workload/task_workload.cue` |  |

---

## Identity

| Definition | File | Description |
|---|---|---|
| `#VersionType` | `identity/identity.cue` | #VersionType mirrors core |

---

## Resources

| Definition | File | Description |
|---|---|---|
| `#ConfigMapDefaults` | `resources/configmap.cue` |  |
| `#ConfigMapSchema` | `resources/configmap.cue` | ConfigMap specification |
| `#ConfigMaps` | `resources/configmap.cue` |  |
| `#ConfigMapsResource` | `resources/configmap.cue` |  |
| `#Container` | `resources/container.cue` |  |
| `#ContainerResource` | `resources/container.cue` |  |
| `#ContainerSchema` | `resources/container.cue` | Container specification |
| `#EnvFromSource` | `resources/container.cue` | Bulk injection source — inject all keys from a ConfigMap or Secret as env vars |
| `#EnvVarSchema` | `resources/container.cue` | Environment variable |
| `#FieldRefDefaults` | `resources/container.cue` |  |
| `#FieldRefSchema` | `resources/container.cue` | Downward API field reference |
| `#GpuResourceSchema` | `resources/container.cue` | GPU extended resource claim |
| `#Image` | `resources/container.cue` | Image specification for container images |
| `#PortSchema` | `resources/container.cue` |  |
| `#ProbeSchema` | `resources/container.cue` | Probe specification used by liveness/readiness/startup probes |
| `#ResourceFieldRefSchema` | `resources/container.cue` | Container resource field reference |
| `#ResourceRequirementsSchema` | `resources/container.cue` |  |
| `#SecurityContextSchema` | `resources/container.cue` |  |
| `#CRDDefaults` | `resources/crd.cue` |  |
| `#CRDSchema` | `resources/crd.cue` | Kubernetes CustomResourceDefinition |
| `#CRDVersionSchema` | `resources/crd.cue` | A single version entry in a CRD |
| `#CRDs` | `resources/crd.cue` |  |
| `#CRDsResource` | `resources/crd.cue` |  |
| `#PolicyRuleSchema` | `resources/role.cue` | Single RBAC permission rule |
| `#Role` | `resources/role.cue` |  |
| `#RoleDefaults` | `resources/role.cue` |  |
| `#RoleResource` | `resources/role.cue` |  |
| `#RoleSchema` | `resources/role.cue` |  |
| `#RoleSubjectSchema` | `resources/role.cue` | Role subject — embeds an identity directly via CUE reference |
| `#AutoSecrets` | `resources/secret.cue` | Discover all #Secret instances from a resolved config and group by $secretName/$dataKey in one step |
| `#ContentHash` | `resources/secret.cue` | Deterministic 10-character hex hash of a string data map |
| `#DiscoverSecrets` | `resources/secret.cue` | Walk a resolved config (up to 10 levels) and collect all fields whose value is a #Secret |
| `#GroupSecrets` | `resources/secret.cue` | Group a flat map of discovered secrets by $secretName, keyed by $dataKey |
| `#ImmutableName` | `resources/secret.cue` | K8s resource name for a ConfigMap |
| `#Secret` | `resources/secret.cue` |  |
| `#SecretContentHash` | `resources/secret.cue` | Normalize #Secret entries and plain strings to a string map, then hash |
| `#SecretDefaults` | `resources/secret.cue` |  |
| `#SecretImmutableName` | `resources/secret.cue` | K8s resource name for a Secret |
| `#SecretK8sRef` | `resources/secret.cue` | References a pre-existing K8s Secret |
| `#SecretLiteral` | `resources/secret.cue` | User provides the actual value |
| `#SecretSchema` | `resources/secret.cue` | `data` holds either #Secret entries (auto-discovered via #AutoSecrets) or plain strings |
| `#SecretType` | `resources/secret.cue` |  |
| `#Secrets` | `resources/secret.cue` |  |
| `#SecretsResource` | `resources/secret.cue` |  |
| `#ServiceAccount` | `resources/service_account.cue` |  |
| `#ServiceAccountResource` | `resources/service_account.cue` |  |
| `#ServiceAccountSchema` | `resources/service_account.cue` |  |
| `#WorkloadIdentitySchema` | `resources/service_account.cue` | Workload identity — used by #WorkloadIdentityTrait and as a #RoleSubjectSchema variant |
| `#EmptyDirDefaults` | `resources/volume.cue` |  |
| `#EmptyDirSchema` | `resources/volume.cue` |  |
| `#FileMode` | `resources/volume.cue` |  |
| `#HostPathDefaults` | `resources/volume.cue` |  |
| `#HostPathSchema` | `resources/volume.cue` | Mounts a file or directory from the host node |
| `#NFSVolumeSourceSchema` | `resources/volume.cue` | Mounts a directory from an NFS server |
| `#PersistentClaimDefaults` | `resources/volume.cue` |  |
| `#PersistentClaimSchema` | `resources/volume.cue` | To mount a CIFS/SMB share use a storageClass that matches a pre-installed SMB StorageClass (e |
| `#SecretVolumeItemSchema` | `resources/volume.cue` |  |
| `#SecretVolumeSourceDefaults` | `resources/volume.cue` |  |
| `#SecretVolumeSourceSchema` | `resources/volume.cue` |  |
| `#VolumeDefaults` | `resources/volume.cue` |  |
| `#VolumeMountDefaults` | `resources/volume.cue` |  |
| `#VolumeMountSchema` | `resources/volume.cue` | Volume mount spec — defines container mount point |
| `#VolumeSchema` | `resources/volume.cue` | Volume specification — defines storage source |
| `#Volumes` | `resources/volume.cue` |  |
| `#VolumesResource` | `resources/volume.cue` |  |

---

## Schemas

| Definition | File | Description |
|---|---|---|
| `#LabelsAnnotationsSchema` | `schemas/common.cue` | Labels and annotations schema |
| `#NameType` | `schemas/common.cue` | DNS label name type (RFC 1123) |
| `#VersionSchema` | `schemas/common.cue` | Semantic version schema |
| `#NormalizeCPU` | `schemas/quantity.cue` | #NormalizeCPU normalizes CPU input to Kubernetes canonical form |
| `#NormalizeMemory` | `schemas/quantity.cue` | #NormalizeMemory normalizes memory input to Kubernetes binary format |

### kubernetes/apiextensions/v1

| Definition | File | Description |
|---|---|---|
| `#CustomResourceColumnDefinition` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinition` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionList` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionNames` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionSpec` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceDefinitionVersion` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceSubresources` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#CustomResourceValidation` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |
| `#JSONSchemaProps` | `schemas/kubernetes/apiextensions/v1/types.cue` |  |

### kubernetes/apps/v1

| Definition | File | Description |
|---|---|---|
| `#ControllerRevision` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ControllerRevisionList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DaemonSetUpdateStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#Deployment` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#DeploymentStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#ReplicaSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateDaemonSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateDeployment` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#RollingUpdateStatefulSetStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSet` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetCondition` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetList` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetOrdinals` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetPersistentVolumeClaimRetentionPolicy` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetSpec` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetStatus` | `schemas/kubernetes/apps/v1/types.cue` |  |
| `#StatefulSetUpdateStrategy` | `schemas/kubernetes/apps/v1/types.cue` |  |

### kubernetes/autoscaling/v2

| Definition | File | Description |
|---|---|---|
| `#ContainerResourceMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ContainerResourceMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#CrossVersionObjectReference` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ExternalMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ExternalMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HPAScalingPolicy` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HPAScalingRules` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscaler` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerBehavior` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerCondition` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerList` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerSpec` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#HorizontalPodAutoscalerStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricIdentifier` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricSpec` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricTarget` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#MetricValueStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ObjectMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ObjectMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#PodsMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#PodsMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ResourceMetricSource` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |
| `#ResourceMetricStatus` | `schemas/kubernetes/autoscaling/v2/types.cue` |  |

### kubernetes/batch/v1

| Definition | File | Description |
|---|---|---|
| `#CronJob` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobList` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#CronJobStatus` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#Job` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobCondition` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobList` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobStatus` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#JobTemplateSpec` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicy` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyOnExitCodesRequirement` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyOnPodConditionsPattern` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#PodFailurePolicyRule` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#SuccessPolicy` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#SuccessPolicyRule` | `schemas/kubernetes/batch/v1/types.cue` |  |
| `#UncountedTerminatedPods` | `schemas/kubernetes/batch/v1/types.cue` |  |

### kubernetes/core/v1

| Definition | File | Description |
|---|---|---|
| `#AWSElasticBlockStoreVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Affinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AppArmorProfile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AttachedVolume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureFilePersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#AzureFileVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Binding` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CSIPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CSIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Capabilities` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CephFSPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CephFSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CinderPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#CinderVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ClientIPConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ClusterTrustBundleProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ComponentStatusList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMap` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapEnvSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapNodeConfigSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ConfigMapVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Container` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerExtendedResourceRequest` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerImage` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerPort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerResizePolicy` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerRestartRule` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerRestartRuleOnExitCodes` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerState` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateRunning` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateTerminated` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStateWaiting` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ContainerUser` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DaemonEndpoint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIVolumeFile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#DownwardAPIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EmptyDirVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointAddress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointPort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointSubset` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Endpoints` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EndpointsList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvFromSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvVar` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EnvVarSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EphemeralContainer` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EphemeralVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Event` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventSeries` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#EventSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ExecAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FCVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FileKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlexPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlexVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#FlockerVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GCEPersistentDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GRPCAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GitRepoVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GlusterfsPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#GlusterfsVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HTTPGetAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HTTPHeader` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostAlias` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostIP` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#HostPathVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ISCSIPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ISCSIVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ImageVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#KeyToPath` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Lifecycle` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LifecycleHandler` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRange` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeItem` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LimitRangeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LinuxContainerUser` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LoadBalancerIngress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LoadBalancerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LocalObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#LocalVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ModifyVolumeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NFSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Namespace` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NamespaceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Node` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeAddress` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeConfigSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeConfigStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeDaemonEndpoints` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeFeatures` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeRuntimeHandler` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeRuntimeHandlerFeatures` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelectorRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSelectorTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSwapStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#NodeSystemInfo` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ObjectFieldSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimTemplate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeClaimVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PersistentVolumeStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PhotonPersistentDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Pod` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAffinityTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodAntiAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodCertificateProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodDNSConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodDNSConfigOption` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodExtendedResourceClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodIP` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodOS` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodReadinessGate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodResourceClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodResourceClaimStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSchedulingGate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSecurityContext` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplate` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplateList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PodTemplateSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PortStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PortworxVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#PreferredSchedulingTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Probe` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ProjectedVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#QuobyteVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#RBDPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#RBDVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationController` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerCondition` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ReplicationControllerStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceClaim` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceFieldSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceHealth` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuota` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceQuotaStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceRequirements` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ResourceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SELinuxOptions` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScaleIOPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScaleIOVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScopeSelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ScopedResourceSelectorRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SeccompProfile` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Secret` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretEnvSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretKeySelector` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecretVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SecurityContext` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Service` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccount` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccountList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceAccountTokenProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceList` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServicePort` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceSpec` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#ServiceStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SessionAffinityConfig` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#SleepAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#StorageOSPersistentVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#StorageOSVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Sysctl` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TCPSocketAction` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Taint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Toleration` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySelectorLabelRequirement` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySelectorTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TopologySpreadConstraint` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TypedLocalObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#TypedObjectReference` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#Volume` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeDevice` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeMount` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeMountStatus` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeNodeAffinity` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeProjection` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VolumeResourceRequirements` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#VsphereVirtualDiskVolumeSource` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#WeightedPodAffinityTerm` | `schemas/kubernetes/core/v1/types.cue` |  |
| `#WindowsSecurityContextOptions` | `schemas/kubernetes/core/v1/types.cue` |  |

### kubernetes/networking/v1

| Definition | File | Description |
|---|---|---|
| `#HTTPIngressPath` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#HTTPIngressRuleValue` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddressList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPAddressSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IPBlock` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#Ingress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressBackend` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClass` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassParametersReference` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressClassSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressLoadBalancerIngress` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressLoadBalancerStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressPortStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressServiceBackend` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#IngressTLS` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicy` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyEgressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyIngressRule` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyPeer` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicyPort` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#NetworkPolicySpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ParentReference` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceBackendPort` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDR` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRList` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRSpec` | `schemas/kubernetes/networking/v1/types.cue` |  |
| `#ServiceCIDRStatus` | `schemas/kubernetes/networking/v1/types.cue` |  |

---

## Traits

| Definition | File | Description |
|---|---|---|
| `#CronJobConfig` | `traits/cron_job_config.cue` |  |
| `#CronJobConfigSchema` | `traits/cron_job_config.cue` |  |
| `#CronJobConfigTrait` | `traits/cron_job_config.cue` |  |
| `#DisruptionBudget` | `traits/disruption_budget.cue` |  |
| `#DisruptionBudgetSchema` | `traits/disruption_budget.cue` | Exactly one of minAvailable or maxUnavailable must be set |
| `#DisruptionBudgetTrait` | `traits/disruption_budget.cue` |  |
| `#EncryptionConfig` | `traits/encryption.cue` |  |
| `#EncryptionConfigSchema` | `traits/encryption.cue` |  |
| `#EncryptionConfigTrait` | `traits/encryption.cue` |  |
| `#Expose` | `traits/expose.cue` |  |
| `#ExposeSchema` | `traits/expose.cue` | Service expose specification |
| `#ExposeTrait` | `traits/expose.cue` |  |
| `#GracefulShutdown` | `traits/graceful_shutdown.cue` |  |
| `#GracefulShutdownSchema` | `traits/graceful_shutdown.cue` |  |
| `#GracefulShutdownTrait` | `traits/graceful_shutdown.cue` |  |
| `#GrpcRoute` | `traits/grpc_route.cue` |  |
| `#GrpcRouteMatchSchema` | `traits/grpc_route.cue` |  |
| `#GrpcRouteRuleSchema` | `traits/grpc_route.cue` |  |
| `#GrpcRouteSchema` | `traits/grpc_route.cue` |  |
| `#GrpcRouteTrait` | `traits/grpc_route.cue` |  |
| `#HostIPC` | `traits/host_ipc.cue` |  |
| `#HostIPCTrait` | `traits/host_ipc.cue` | Enables hostIPC: true on the pod spec, sharing the node's IPC namespace |
| `#HostNetwork` | `traits/host_network.cue` |  |
| `#HostNetworkTrait` | `traits/host_network.cue` | Enables hostNetwork: true on the pod spec, sharing the node's network namespace |
| `#HostPID` | `traits/host_pid.cue` |  |
| `#HostPIDTrait` | `traits/host_pid.cue` | Enables hostPID: true on the pod spec, sharing the node's PID namespace |
| `#HttpRoute` | `traits/http_route.cue` |  |
| `#HttpRouteMatchSchema` | `traits/http_route.cue` |  |
| `#HttpRouteRuleSchema` | `traits/http_route.cue` |  |
| `#HttpRouteSchema` | `traits/http_route.cue` |  |
| `#HttpRouteTrait` | `traits/http_route.cue` |  |
| `#ImagePullSecrets` | `traits/image_pull_secrets.cue` |  |
| `#ImagePullSecretsSchema` | `traits/image_pull_secrets.cue` | References to pre-existing K8s Secrets |
| `#ImagePullSecretsTrait` | `traits/image_pull_secrets.cue` | References pre-existing K8s Secrets (type kubernetes |
| `#InitContainers` | `traits/init_containers.cue` |  |
| `#InitContainersSchema` | `traits/init_containers.cue` | Init container shape — alias of #ContainerSchema |
| `#InitContainersTrait` | `traits/init_containers.cue` |  |
| `#JobConfig` | `traits/job_config.cue` |  |
| `#JobConfigSchema` | `traits/job_config.cue` |  |
| `#JobConfigTrait` | `traits/job_config.cue` |  |
| `#RestartPolicy` | `traits/restart_policy.cue` |  |
| `#RestartPolicySchema` | `traits/restart_policy.cue` |  |
| `#RestartPolicyTrait` | `traits/restart_policy.cue` |  |
| `#RouteAttachmentSchema` | `traits/route_common.cue` | Shared attachment fields for route schemas (gateway, TLS, className) |
| `#RouteHeaderMatch` | `traits/route_common.cue` | Header match for route rules |
| `#RouteRuleBase` | `traits/route_common.cue` | Base fields shared by all route rules |
| `#AutoscalingSpec` | `traits/scaling.cue` |  |
| `#MetricSpec` | `traits/scaling.cue` |  |
| `#MetricTargetSpec` | `traits/scaling.cue` |  |
| `#Scaling` | `traits/scaling.cue` |  |
| `#ScalingSchema` | `traits/scaling.cue` |  |
| `#ScalingTrait` | `traits/scaling.cue` |  |
| `#SecurityContext` | `traits/security_context.cue` |  |
| `#SecurityContextTrait` | `traits/security_context.cue` |  |
| `#SidecarContainers` | `traits/sidecar_containers.cue` |  |
| `#SidecarContainersSchema` | `traits/sidecar_containers.cue` | Sidecar container shape — alias of #ContainerSchema |
| `#SidecarContainersTrait` | `traits/sidecar_containers.cue` |  |
| `#Sizing` | `traits/sizing.cue` |  |
| `#SizingSchema` | `traits/sizing.cue` |  |
| `#SizingTrait` | `traits/sizing.cue` |  |
| `#VerticalScalingSchema` | `traits/sizing.cue` | Placeholder for future VPA support |
| `#TcpRoute` | `traits/tcp_route.cue` |  |
| `#TcpRouteRuleSchema` | `traits/tcp_route.cue` | No L7 match fields for TCP |
| `#TcpRouteSchema` | `traits/tcp_route.cue` |  |
| `#TcpRouteTrait` | `traits/tcp_route.cue` |  |
| `#TlsRoute` | `traits/tls_route.cue` |  |
| `#TlsRouteRuleSchema` | `traits/tls_route.cue` | No L7 match fields for TLS |
| `#TlsRouteSchema` | `traits/tls_route.cue` |  |
| `#TlsRouteTrait` | `traits/tls_route.cue` |  |
| `#UpdateStrategy` | `traits/update_strategy.cue` |  |
| `#UpdateStrategyDefaults` | `traits/update_strategy.cue` |  |
| `#UpdateStrategySchema` | `traits/update_strategy.cue` |  |
| `#UpdateStrategyTrait` | `traits/update_strategy.cue` |  |
| `#WorkloadIdentity` | `traits/workload_identity.cue` |  |
| `#WorkloadIdentityTrait` | `traits/workload_identity.cue` |  |

---

## Transformers

| Definition | File | Description |
|---|---|---|
| `#ConfigMapTransformer` | `transformers/configmap_transformer.cue` | ConfigMapTransformer converts ConfigMaps resources to Kubernetes ConfigMaps |
| `#ToK8sContainer` | `transformers/container_helpers.cue` | #ToK8sContainer converts an OPM #ContainerSchema to a Kubernetes #Container |
| `#ToK8sContainers` | `transformers/container_helpers.cue` | #ToK8sContainers converts a list of OPM containers to Kubernetes containers |
| `#ToK8sVolumes` | `transformers/container_helpers.cue` | #ToK8sVolumes converts OPM volumes map to Kubernetes volumes list |
| `#CRDTransformer` | `transformers/crd_transformer.cue` | CRDTransformer converts CRDs resources to Kubernetes CustomResourceDefinitions |
| `#CronJobTransformer` | `transformers/cronjob_transformer.cue` | CronJobTransformer converts scheduled task components to Kubernetes CronJobs |
| `#DaemonSetTransformer` | `transformers/daemonset_transformer.cue` | DaemonSetTransformer converts daemon workload components to Kubernetes DaemonSets |
| `#DeploymentTransformer` | `transformers/deployment_transformer.cue` | DeploymentTransformer converts stateless workload components to Kubernetes Deployments |
| `#GrpcRouteTransformer` | `transformers/grpc_route_transformer.cue` | GrpcRouteTransformer creates Gateway API GRPCRoutes from components with GrpcRoute trait |
| `#HttpRouteTransformer` | `transformers/http_route_transformer.cue` | HttpRouteTransformer creates Gateway API HTTPRoutes from components with HttpRoute trait |
| `#JobTransformer` | `transformers/job_transformer.cue` | JobTransformer converts task workload components to Kubernetes Jobs |
| `#PVCTransformer` | `transformers/pvc_transformer.cue` | PVCTransformer creates standalone PersistentVolumeClaims from Volume resources |
| `#RoleTransformer` | `transformers/role_transformer.cue` | RoleTransformer converts OPM Role resources to Kubernetes RBAC objects |
| `#ToK8sServiceAccount` | `transformers/sa_helpers.cue` | #ToK8sServiceAccount converts an OPM identity spec (either #WorkloadIdentitySchema or #ServiceAccountSchema — both share the same shape) to a Kubernetes ServiceAccount |
| `#ServiceAccountResourceTransformer` | `transformers/sa_resource_transformer.cue` | ServiceAccountResourceTransformer converts standalone ServiceAccount resources to Kubernetes ServiceAccounts |
| `#SecretTransformer` | `transformers/secret_transformer.cue` | SecretTransformer converts Secrets resources to Kubernetes Secrets |
| `#ServiceTransformer` | `transformers/service_transformer.cue` | ServiceTransformer creates Kubernetes Services from components with Expose trait |
| `#StatefulsetTransformer` | `transformers/statefulset_transformer.cue` | StatefulsetTransformer converts stateful workload components to Kubernetes StatefulSets |
| `#TcpRouteTransformer` | `transformers/tcp_route_transformer.cue` | TcpRouteTransformer creates Gateway API TCPRoutes from components with TcpRoute trait |
| `#TlsRouteTransformer` | `transformers/tls_route_transformer.cue` | TlsRouteTransformer creates Gateway API TLSRoutes from components with TlsRoute trait |

---

