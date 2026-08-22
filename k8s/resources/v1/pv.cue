package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolume Resource Definition
/////////////////////////////////////////////////////////////////

// #PersistentVolumeResource defines a native Kubernetes PV as an OPM resource.
// Use this for cluster-scoped persistent volume provisioning.
#PersistentVolumeResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "persistentvolume"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/persistentvolume@v1"
		description:    "A native Kubernetes PersistentVolume resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: persistentvolume: schemas.#PersistentVolumeSchema
}

#PersistentVolume: c.#Component & {
	#resources: {(#PersistentVolumeResource.metadata.fqn): #PersistentVolumeResource}
}
