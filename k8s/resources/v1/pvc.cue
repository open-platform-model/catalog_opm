package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolumeClaim Resource Definition
/////////////////////////////////////////////////////////////////

// #PersistentVolumeClaimResource defines a native Kubernetes PVC as an OPM resource.
// Use this to request persistent storage for stateful workloads.
#PersistentVolumeClaimResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "persistentvolumeclaim"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/persistentvolumeclaim@v1"
		description:    "A native Kubernetes PersistentVolumeClaim resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: persistentvolumeclaim: schemas.#PersistentVolumeClaimSchema
}

#PersistentVolumeClaim: c.#Component & {
	#resources: {(#PersistentVolumeClaimResource.metadata.fqn): #PersistentVolumeClaimResource}
}
