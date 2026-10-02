package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// VolumeSnapshotClass Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes VolumeSnapshotClass that configures a snapshot driver.
// It is snapshot.storage.k8s.io/v1, and the rendered name is the component's
// resourceName, like StorageClass.
#VolumeSnapshotClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "volumesnapshotclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/volumesnapshotclass@v1"
		description:    "A native Kubernetes VolumeSnapshotClass that configures a snapshot driver"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: volumesnapshotclass: schemas.#VolumeSnapshotClassSchema
}

#VolumeSnapshotClass: c.#Component & {
	#resources: {(#VolumeSnapshotClassResource.metadata.fqn): #VolumeSnapshotClassResource}
}
