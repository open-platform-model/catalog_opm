package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// StorageClass Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sStorageClassResource defines a native Kubernetes StorageClass as an OPM resource.
// Use this to define cluster-wide storage provisioner configurations.
#K8sStorageClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-storageclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-storageclass@v1"
		description:    "A native Kubernetes StorageClass resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: k8sStorageclass: schemas.#StorageClassSchema
}

#K8sStorageClass: c.#Component & {
	#resources: {(#K8sStorageClassResource.metadata.fqn): #K8sStorageClassResource}
}
