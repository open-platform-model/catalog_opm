package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Pod Resource Definition
/////////////////////////////////////////////////////////////////

// #PodResource defines a native Kubernetes Pod as an OPM resource.
// Use this for standalone pods; prefer Deployment or StatefulSet for
// production workloads that need scheduling guarantees.
#PodResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "pod"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/pod@v1"
		description:    "A native Kubernetes Pod resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: pod: schemas.#PodSchema
}

#Pod: c.#Component & {
	#resources: {(#PodResource.metadata.fqn): #PodResource}
}
