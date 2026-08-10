// Catalog manifest for the OPM core catalog. Embeds bare c.#Catalog
// (modules pattern — no Catalog: wrapper), sources metadata from the sibling
// identity/ package, and enumerates every transformer keyed by its own
// metadata.fqn. The #Catalog pattern constraint stamps each entry's
// modulePath/version in lockstep (enhancement 0001 D19/D25).
//
// Resources, traits, and blueprints are not enumerated here — they surface
// transitively through each transformer's required/optional maps.
package opm

import (
	c "opmodel.dev/core@v2"
	id "opmodel.dev/catalogs/opm/identity"
	t "opmodel.dev/catalogs/opm/transformers"
)

c.#Catalog
metadata: {
	modulePath:  id.ModulePath
	version:     id.Version
	description: "OPM core catalog — Kubernetes resources, traits, blueprints, and transformers"
}

#transformers: {
	(t.#ConfigMapTransformer.metadata.fqn):              t.#ConfigMapTransformer
	(t.#CRDTransformer.metadata.fqn):                    t.#CRDTransformer
	(t.#CronJobTransformer.metadata.fqn):                t.#CronJobTransformer
	(t.#DaemonSetTransformer.metadata.fqn):              t.#DaemonSetTransformer
	(t.#DeploymentTransformer.metadata.fqn):             t.#DeploymentTransformer
	(t.#GrpcRouteTransformer.metadata.fqn):              t.#GrpcRouteTransformer
	(t.#HPATransformer.metadata.fqn):                    t.#HPATransformer
	(t.#HttpRouteTransformer.metadata.fqn):              t.#HttpRouteTransformer
	(t.#JobTransformer.metadata.fqn):                    t.#JobTransformer
	(t.#NetworkPolicyTransformer.metadata.fqn):          t.#NetworkPolicyTransformer
	(t.#PDBTransformer.metadata.fqn):                    t.#PDBTransformer
	(t.#PVCTransformer.metadata.fqn):                    t.#PVCTransformer
	(t.#RoleTransformer.metadata.fqn):                   t.#RoleTransformer
	(t.#SecretTransformer.metadata.fqn):                 t.#SecretTransformer
	(t.#ServiceAccountResourceTransformer.metadata.fqn): t.#ServiceAccountResourceTransformer
	(t.#ServiceTransformer.metadata.fqn):                t.#ServiceTransformer
	(t.#StatefulsetTransformer.metadata.fqn):            t.#StatefulsetTransformer
	(t.#TcpRouteTransformer.metadata.fqn):               t.#TcpRouteTransformer
	(t.#TlsRouteTransformer.metadata.fqn):               t.#TlsRouteTransformer

	// Experimental abstraction candidates (v1alpha1 contracts; ex
	// catalog_opm_experimental — 0010 D47).
	(t.#AdmissionPolicyTransformer.metadata.fqn):   t.#AdmissionPolicyTransformer
	(t.#MutatingWebhookTransformer.metadata.fqn):   t.#MutatingWebhookTransformer
	(t.#NamespaceTransformer.metadata.fqn):         t.#NamespaceTransformer
	(t.#ValidatingWebhookTransformer.metadata.fqn): t.#ValidatingWebhookTransformer

	// Raw k8s-* passthrough family (ex catalog_kubernetes — 0010 D47/D48).
	// Native Kubernetes APIs as-is; the last resort for what the abstraction
	// family does not model. The abstraction family never depends on these
	// (task vet:layering).
	(t.#K8sAPIServiceTransformer.metadata.fqn):                     t.#K8sAPIServiceTransformer
	(t.#K8sClusterRoleBindingTransformer.metadata.fqn):             t.#K8sClusterRoleBindingTransformer
	(t.#K8sClusterRoleTransformer.metadata.fqn):                    t.#K8sClusterRoleTransformer
	(t.#K8sConfigMapTransformer.metadata.fqn):                      t.#K8sConfigMapTransformer
	(t.#K8sCronJobTransformer.metadata.fqn):                        t.#K8sCronJobTransformer
	(t.#K8sDaemonSetTransformer.metadata.fqn):                      t.#K8sDaemonSetTransformer
	(t.#K8sDeploymentTransformer.metadata.fqn):                     t.#K8sDeploymentTransformer
	(t.#K8sHorizontalPodAutoscalerTransformer.metadata.fqn):        t.#K8sHorizontalPodAutoscalerTransformer
	(t.#K8sIngressClassTransformer.metadata.fqn):                   t.#K8sIngressClassTransformer
	(t.#K8sIngressTransformer.metadata.fqn):                        t.#K8sIngressTransformer
	(t.#K8sJobTransformer.metadata.fqn):                            t.#K8sJobTransformer
	(t.#K8sMutatingWebhookConfigurationTransformer.metadata.fqn):   t.#K8sMutatingWebhookConfigurationTransformer
	(t.#K8sNamespaceTransformer.metadata.fqn):                      t.#K8sNamespaceTransformer
	(t.#K8sNetworkPolicyTransformer.metadata.fqn):                  t.#K8sNetworkPolicyTransformer
	(t.#K8sObjectTransformer.metadata.fqn):                         t.#K8sObjectTransformer
	(t.#K8sPersistentVolumeClaimTransformer.metadata.fqn):          t.#K8sPersistentVolumeClaimTransformer
	(t.#K8sPersistentVolumeTransformer.metadata.fqn):               t.#K8sPersistentVolumeTransformer
	(t.#K8sPodDisruptionBudgetTransformer.metadata.fqn):            t.#K8sPodDisruptionBudgetTransformer
	(t.#K8sPodTransformer.metadata.fqn):                            t.#K8sPodTransformer
	(t.#K8sRoleBindingTransformer.metadata.fqn):                    t.#K8sRoleBindingTransformer
	(t.#K8sRoleTransformer.metadata.fqn):                           t.#K8sRoleTransformer
	(t.#K8sSecretTransformer.metadata.fqn):                         t.#K8sSecretTransformer
	(t.#K8sServiceAccountTransformer.metadata.fqn):                 t.#K8sServiceAccountTransformer
	(t.#K8sServiceTransformer.metadata.fqn):                        t.#K8sServiceTransformer
	(t.#K8sStatefulSetTransformer.metadata.fqn):                    t.#K8sStatefulSetTransformer
	(t.#K8sStorageClassTransformer.metadata.fqn):                   t.#K8sStorageClassTransformer
	(t.#K8sValidatingWebhookConfigurationTransformer.metadata.fqn): t.#K8sValidatingWebhookConfigurationTransformer
}
