package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolume Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes PersistentVolume, provisioned at cluster scope.
#PersistentVolumeResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "persistentvolume"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/persistentvolume@v1"
		description:    "A native Kubernetes PersistentVolume, provisioned at cluster scope"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: persistentvolume: schemas.#PersistentVolumeSchema
}

#PersistentVolume: c.#Component & {
	#resources: {(#PersistentVolumeResource.metadata.fqn): #PersistentVolumeResource}
}
