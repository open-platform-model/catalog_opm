package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// StorageClass Resource Definition
/////////////////////////////////////////////////////////////////

// #StorageClassResource defines a native Kubernetes StorageClass as an OPM resource.
// Use this to define cluster-wide storage provisioner configurations.
#StorageClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "storageclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/storageclass@v1"
		description:    "A native Kubernetes StorageClass resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: storageclass: schemas.#StorageClassSchema
}

#StorageClass: c.#Component & {
	#resources: {(#StorageClassResource.metadata.fqn): #StorageClassResource}
}
