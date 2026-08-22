package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// NetworkPolicy Resource Definition
/////////////////////////////////////////////////////////////////

// #NetworkPolicyResource defines a native Kubernetes NetworkPolicy as an OPM resource.
// Use this to control ingress and egress traffic between pods.
#NetworkPolicyResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "networkpolicy"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/networkpolicy@v1"
		description:    "A native Kubernetes NetworkPolicy resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: networkpolicy: schemas.#NetworkPolicySchema
}

#NetworkPolicy: c.#Component & {
	#resources: {(#NetworkPolicyResource.metadata.fqn): #NetworkPolicyResource}
}
