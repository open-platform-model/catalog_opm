package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Service Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sServiceResource defines a native Kubernetes Service as an OPM resource.
// Use this to expose workloads within or outside the cluster.
#K8sServiceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-service"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-service@v1"
		description:    "A native Kubernetes Service resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: k8sService: schemas.#ServiceSchema
}

#K8sService: c.#Component & {
	#resources: {(#K8sServiceResource.metadata.fqn): #K8sServiceResource}
}
