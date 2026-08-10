package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolume Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sPersistentVolumeResource defines a native Kubernetes PV as an OPM resource.
// Use this for cluster-scoped persistent volume provisioning.
#K8sPersistentVolumeResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-persistentvolume"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-persistentvolume@v1"
		description:    "A native Kubernetes PersistentVolume resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: k8sPersistentvolume: schemas.#PersistentVolumeSchema
}

#K8sPersistentVolume: c.#Component & {
	#resources: {(#K8sPersistentVolumeResource.metadata.fqn): #K8sPersistentVolumeResource}
}
