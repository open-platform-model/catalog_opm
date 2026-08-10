package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Pod Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sPodResource defines a native Kubernetes Pod as an OPM resource.
// Use this for standalone pods; prefer Deployment or StatefulSet for
// production workloads that need scheduling guarantees.
#K8sPodResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-pod"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-pod@v1"
		description:    "A native Kubernetes Pod resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sPod: schemas.#PodSchema
}

#K8sPod: c.#Component & {
	#resources: {(#K8sPodResource.metadata.fqn): #K8sPodResource}
}
