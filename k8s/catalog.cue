// Catalog manifest for the OPM Kubernetes catalog. Embeds bare c.#Catalog
// (modules pattern — no Catalog: wrapper), sources metadata from the sibling
// identity/ package, and enumerates every member keyed by its own
// metadata.fqn. The #Catalog pattern constraints stamp each entry's
// modulePath/catalogVersion in lockstep (enhancement 0001 D19/D25).
//
// This catalog is the RAW PASSTHROUGH surface: native Kubernetes APIs carried
// as-is, the last resort for what the abstraction catalog
// (opmodel.dev/catalogs/opm) does not model. The dependency never runs the
// other way: nothing here imports the abstraction catalog, and the abstraction
// catalog never imports this one.
//
// Resources are listed in #resources (enhancement 0015 D1), one import alias
// per version segment directory; each member's apiVersion mirrors the upstream
// Kubernetes API version at adoption (0010 D48). The raw catalog defines no
// traits or blueprints, so #traits and #blueprints stay absent, which is empty.
package k8s

import (
	c "opmodel.dev/core@v2"
	id "opmodel.dev/catalogs/k8s/identity"
	t "opmodel.dev/catalogs/k8s/transformers"
	v1 "opmodel.dev/catalogs/k8s/resources/v1"
	v2 "opmodel.dev/catalogs/k8s/resources/v2"
)

c.#Catalog
metadata: {
	modulePath:  id.ModulePath
	version:     id.Version
	description: "OPM Kubernetes catalog — native Kubernetes APIs carried through as-is"
}

#resources: {
	(v1.#APIServiceResource.metadata.fqn):                     v1.#APIServiceResource
	(v1.#ClusterRoleBindingResource.metadata.fqn):             v1.#ClusterRoleBindingResource
	(v1.#ClusterRoleResource.metadata.fqn):                    v1.#ClusterRoleResource
	(v1.#ConfigMapResource.metadata.fqn):                      v1.#ConfigMapResource
	(v1.#CronJobResource.metadata.fqn):                        v1.#CronJobResource
	(v1.#CSIDriverResource.metadata.fqn):                      v1.#CSIDriverResource
	(v1.#DaemonSetResource.metadata.fqn):                      v1.#DaemonSetResource
	(v1.#DeploymentResource.metadata.fqn):                     v1.#DeploymentResource
	(v1.#IngressClassResource.metadata.fqn):                   v1.#IngressClassResource
	(v1.#IngressResource.metadata.fqn):                        v1.#IngressResource
	(v1.#JobResource.metadata.fqn):                            v1.#JobResource
	(v1.#MutatingWebhookConfigurationResource.metadata.fqn):   v1.#MutatingWebhookConfigurationResource
	(v1.#NamespaceResource.metadata.fqn):                      v1.#NamespaceResource
	(v1.#NetworkPolicyResource.metadata.fqn):                  v1.#NetworkPolicyResource
	(v1.#ObjectsResource.metadata.fqn):                        v1.#ObjectsResource
	(v1.#PersistentVolumeClaimResource.metadata.fqn):          v1.#PersistentVolumeClaimResource
	(v1.#PersistentVolumeResource.metadata.fqn):               v1.#PersistentVolumeResource
	(v1.#PodDisruptionBudgetResource.metadata.fqn):            v1.#PodDisruptionBudgetResource
	(v1.#PodResource.metadata.fqn):                            v1.#PodResource
	(v1.#RoleBindingResource.metadata.fqn):                    v1.#RoleBindingResource
	(v1.#RoleResource.metadata.fqn):                           v1.#RoleResource
	(v1.#SecretResource.metadata.fqn):                         v1.#SecretResource
	(v1.#ServiceAccountResource.metadata.fqn):                 v1.#ServiceAccountResource
	(v1.#ServiceResource.metadata.fqn):                        v1.#ServiceResource
	(v1.#StatefulSetResource.metadata.fqn):                    v1.#StatefulSetResource
	(v1.#StorageClassResource.metadata.fqn):                   v1.#StorageClassResource
	(v1.#ValidatingWebhookConfigurationResource.metadata.fqn): v1.#ValidatingWebhookConfigurationResource
	(v1.#VolumeSnapshotClassResource.metadata.fqn):            v1.#VolumeSnapshotClassResource

	// autoscaling/v2 (0010 D48: the segment is upstream's, not this repo's).
	(v2.#HorizontalPodAutoscalerResource.metadata.fqn): v2.#HorizontalPodAutoscalerResource
}

#transformers: {
	(t.#APIServiceTransformer.metadata.fqn):                     t.#APIServiceTransformer
	(t.#ClusterRoleBindingTransformer.metadata.fqn):             t.#ClusterRoleBindingTransformer
	(t.#ClusterRoleTransformer.metadata.fqn):                    t.#ClusterRoleTransformer
	(t.#ConfigMapTransformer.metadata.fqn):                      t.#ConfigMapTransformer
	(t.#CSIDriverTransformer.metadata.fqn):                      t.#CSIDriverTransformer
	(t.#CronJobTransformer.metadata.fqn):                        t.#CronJobTransformer
	(t.#DaemonSetTransformer.metadata.fqn):                      t.#DaemonSetTransformer
	(t.#DeploymentTransformer.metadata.fqn):                     t.#DeploymentTransformer
	(t.#HorizontalPodAutoscalerTransformer.metadata.fqn):        t.#HorizontalPodAutoscalerTransformer
	(t.#IngressClassTransformer.metadata.fqn):                   t.#IngressClassTransformer
	(t.#IngressTransformer.metadata.fqn):                        t.#IngressTransformer
	(t.#JobTransformer.metadata.fqn):                            t.#JobTransformer
	(t.#MutatingWebhookConfigurationTransformer.metadata.fqn):   t.#MutatingWebhookConfigurationTransformer
	(t.#NamespaceTransformer.metadata.fqn):                      t.#NamespaceTransformer
	(t.#NetworkPolicyTransformer.metadata.fqn):                  t.#NetworkPolicyTransformer
	(t.#ObjectTransformer.metadata.fqn):                         t.#ObjectTransformer
	(t.#PersistentVolumeClaimTransformer.metadata.fqn):          t.#PersistentVolumeClaimTransformer
	(t.#PersistentVolumeTransformer.metadata.fqn):               t.#PersistentVolumeTransformer
	(t.#PodDisruptionBudgetTransformer.metadata.fqn):            t.#PodDisruptionBudgetTransformer
	(t.#PodTransformer.metadata.fqn):                            t.#PodTransformer
	(t.#RoleBindingTransformer.metadata.fqn):                    t.#RoleBindingTransformer
	(t.#RoleTransformer.metadata.fqn):                           t.#RoleTransformer
	(t.#SecretTransformer.metadata.fqn):                         t.#SecretTransformer
	(t.#ServiceAccountTransformer.metadata.fqn):                 t.#ServiceAccountTransformer
	(t.#ServiceTransformer.metadata.fqn):                        t.#ServiceTransformer
	(t.#StatefulSetTransformer.metadata.fqn):                    t.#StatefulSetTransformer
	(t.#StorageClassTransformer.metadata.fqn):                   t.#StorageClassTransformer
	(t.#ValidatingWebhookConfigurationTransformer.metadata.fqn): t.#ValidatingWebhookConfigurationTransformer
	(t.#VolumeSnapshotClassTransformer.metadata.fqn):            t.#VolumeSnapshotClassTransformer
}
