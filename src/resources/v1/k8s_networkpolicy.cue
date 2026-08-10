package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// NetworkPolicy Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sNetworkPolicyResource defines a native Kubernetes NetworkPolicy as an OPM resource.
// Use this to control ingress and egress traffic between pods.
#K8sNetworkPolicyResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-networkpolicy"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-networkpolicy@v1"
		description:    "A native Kubernetes NetworkPolicy resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: k8sNetworkpolicy: schemas.#NetworkPolicySchema
}

#K8sNetworkPolicy: c.#Component & {
	#resources: {(#K8sNetworkPolicyResource.metadata.fqn): #K8sNetworkPolicyResource}
}
