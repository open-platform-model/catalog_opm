// Catalog manifest for the OPM core catalog. Embeds bare c.#Catalog
// (modules pattern — no Catalog: wrapper), sources metadata from the sibling
// identity/ package, and enumerates every member keyed by its own
// metadata.fqn. The #Catalog pattern constraints stamp each entry's
// modulePath/catalogVersion in lockstep (enhancement 0001 D19/D25).
//
// Resources, traits and blueprints are listed in #resources, #traits and
// #blueprints (enhancement 0015 D1): the listing is what makes a contract
// visible to a subscribing platform, including a provider-fulfilled one that
// no transformer here implements. Every member under resources/, traits/ and
// blueprints/ is a key; one import alias per version segment directory.
package opm

import (
	c "opmodel.dev/core@v2"
	id "opmodel.dev/catalogs/opm/identity"
	t "opmodel.dev/catalogs/opm/transformers"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	resa "opmodel.dev/catalogs/opm/resources/v1alpha1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
	tra "opmodel.dev/catalogs/opm/traits/v1alpha1"
	bp "opmodel.dev/catalogs/opm/blueprints/v1beta1"
)

c.#Catalog
metadata: {
	modulePath:  id.ModulePath
	version:     id.Version
	description: "OPM core catalog — Kubernetes resources, traits, blueprints, and transformers"
}

#resources: {
	(res.#ConfigMapsResource.metadata.fqn):     res.#ConfigMapsResource
	(res.#ContainerResource.metadata.fqn):      res.#ContainerResource
	(res.#CRDsResource.metadata.fqn):           res.#CRDsResource
	(res.#RoleResource.metadata.fqn):           res.#RoleResource
	(res.#SecretsResource.metadata.fqn):        res.#SecretsResource
	(res.#ServiceAccountResource.metadata.fqn): res.#ServiceAccountResource
	(res.#VolumesResource.metadata.fqn):        res.#VolumesResource

	// Experimental abstraction candidates (v1alpha1 contracts; ex
	// catalog_opm_experimental — 0010 D47).
	(resa.#MutatingWebhooksResource.metadata.fqn):            resa.#MutatingWebhooksResource
	(resa.#NamespacesResource.metadata.fqn):                  resa.#NamespacesResource
	(resa.#TransformerRegistrationResource.metadata.fqn):     resa.#TransformerRegistrationResource
	(resa.#ValidatingAdmissionPoliciesResource.metadata.fqn): resa.#ValidatingAdmissionPoliciesResource
	(resa.#ValidatingWebhooksResource.metadata.fqn):          resa.#ValidatingWebhooksResource
}

#traits: {
	(tr.#CronJobConfigTrait.metadata.fqn):     tr.#CronJobConfigTrait
	(tr.#DisruptionBudgetTrait.metadata.fqn):  tr.#DisruptionBudgetTrait
	(tr.#EncryptionConfigTrait.metadata.fqn):  tr.#EncryptionConfigTrait
	(tr.#ExposeTrait.metadata.fqn):            tr.#ExposeTrait
	(tr.#GracefulShutdownTrait.metadata.fqn):  tr.#GracefulShutdownTrait
	(tr.#GrpcRouteTrait.metadata.fqn):         tr.#GrpcRouteTrait
	(tr.#HostIPCTrait.metadata.fqn):           tr.#HostIPCTrait
	(tr.#HostNetworkTrait.metadata.fqn):       tr.#HostNetworkTrait
	(tr.#HostPIDTrait.metadata.fqn):           tr.#HostPIDTrait
	(tr.#HttpRouteTrait.metadata.fqn):         tr.#HttpRouteTrait
	(tr.#ImagePullSecretsTrait.metadata.fqn):  tr.#ImagePullSecretsTrait
	(tr.#InitContainersTrait.metadata.fqn):    tr.#InitContainersTrait
	(tr.#JobConfigTrait.metadata.fqn):         tr.#JobConfigTrait
	(tr.#NetworkPolicyTrait.metadata.fqn):     tr.#NetworkPolicyTrait
	(tr.#PodMetadataTrait.metadata.fqn):       tr.#PodMetadataTrait
	(tr.#PodSchedulingTrait.metadata.fqn):     tr.#PodSchedulingTrait
	(tr.#RestartPolicyTrait.metadata.fqn):     tr.#RestartPolicyTrait
	(tr.#RuntimeClassTrait.metadata.fqn):      tr.#RuntimeClassTrait
	(tr.#ScalingTrait.metadata.fqn):           tr.#ScalingTrait
	(tr.#SecurityContextTrait.metadata.fqn):   tr.#SecurityContextTrait
	(tr.#SidecarContainersTrait.metadata.fqn): tr.#SidecarContainersTrait
	(tr.#SizingTrait.metadata.fqn):            tr.#SizingTrait
	(tr.#TcpRouteTrait.metadata.fqn):          tr.#TcpRouteTrait
	(tr.#TlsRouteTrait.metadata.fqn):          tr.#TlsRouteTrait
	(tr.#UpdateStrategyTrait.metadata.fqn):    tr.#UpdateStrategyTrait
	(tr.#WorkloadIdentityTrait.metadata.fqn):  tr.#WorkloadIdentityTrait

	// Experimental abstraction candidates (v1alpha1 contracts — 0010 D34).
	// Both are provider-fulfilled: listing them is what makes them visible
	// to a subscribing platform, and no transformer here implements them.
	(tra.#BackupTrait.metadata.fqn):        tra.#BackupTrait
	(tra.#BackupCommandTrait.metadata.fqn): tra.#BackupCommandTrait
}

#blueprints: {
	(bp.#DaemonWorkloadBlueprint.metadata.fqn):        bp.#DaemonWorkloadBlueprint
	(bp.#ScheduledTaskWorkloadBlueprint.metadata.fqn): bp.#ScheduledTaskWorkloadBlueprint
	(bp.#StatefulWorkloadBlueprint.metadata.fqn):      bp.#StatefulWorkloadBlueprint
	(bp.#StatelessWorkloadBlueprint.metadata.fqn):     bp.#StatelessWorkloadBlueprint
	(bp.#TaskWorkloadBlueprint.metadata.fqn):          bp.#TaskWorkloadBlueprint
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
	(t.#AdmissionPolicyTransformer.metadata.fqn):         t.#AdmissionPolicyTransformer
	(t.#MutatingWebhookTransformer.metadata.fqn):         t.#MutatingWebhookTransformer
	(t.#NamespaceTransformer.metadata.fqn):               t.#NamespaceTransformer
	(t.#TransformerRegistrationTransformer.metadata.fqn): t.#TransformerRegistrationTransformer
	(t.#ValidatingWebhookTransformer.metadata.fqn):       t.#ValidatingWebhookTransformer
}
