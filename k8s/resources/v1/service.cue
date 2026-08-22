package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Service Resource Definition
/////////////////////////////////////////////////////////////////

// #ServiceResource defines a native Kubernetes Service as an OPM resource.
// Use this to expose workloads within or outside the cluster.
#ServiceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "service"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/service@v1"
		description:    "A native Kubernetes Service resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: service: schemas.#ServiceSchema
}

#Service: c.#Component & {
	#resources: {(#ServiceResource.metadata.fqn): #ServiceResource}
}
