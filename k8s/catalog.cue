// Catalog manifest for the OPM Kubernetes catalog. Embeds bare c.#Catalog
// (modules pattern — no Catalog: wrapper), sources metadata from the sibling
// identity/ package, and enumerates every transformer keyed by its own
// metadata.fqn. The #Catalog pattern constraint stamps each entry's
// modulePath/version in lockstep (enhancement 0001 D19/D25).
//
// This catalog is the RAW PASSTHROUGH surface: native Kubernetes APIs carried
// as-is, the last resort for what the abstraction catalog
// (opmodel.dev/catalogs/opm) does not model. The dependency never runs the
// other way: nothing here imports the abstraction catalog, and the abstraction
// catalog never imports this one.
//
// Resources are not enumerated here — they surface transitively through each
// transformer's required/optional maps.
package k8s

import (
	c "opmodel.dev/core@v2"
	id "opmodel.dev/catalogs/k8s/identity"
	t "opmodel.dev/catalogs/k8s/transformers"
)

c.#Catalog
metadata: {
	modulePath:  id.ModulePath
	version:     id.Version
	description: "OPM Kubernetes catalog — native Kubernetes APIs carried through as-is"
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
