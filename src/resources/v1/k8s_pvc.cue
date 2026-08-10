package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// PersistentVolumeClaim Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sPersistentVolumeClaimResource defines a native Kubernetes PVC as an OPM resource.
// Use this to request persistent storage for stateful workloads.
#K8sPersistentVolumeClaimResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-persistentvolumeclaim"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-persistentvolumeclaim@v1"
		description:    "A native Kubernetes PersistentVolumeClaim resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: k8sPersistentvolumeclaim: schemas.#PersistentVolumeClaimSchema
}

#K8sPersistentVolumeClaim: c.#Component & {
	#resources: {(#K8sPersistentVolumeClaimResource.metadata.fqn): #K8sPersistentVolumeClaimResource}
}
