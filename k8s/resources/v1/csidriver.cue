package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// CSIDriver Resource Definition
/////////////////////////////////////////////////////////////////

// #CSIDriverResource defines a native Kubernetes CSIDriver as an OPM resource.
// The authored `metadata.name` renders verbatim: it is the name kubelet and
// every StorageClass.provisioner refer to, so no instance prefix applies.
#CSIDriverResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "csidriver"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/csidriver@v1"
		description:    "A native Kubernetes CSIDriver resource"
		labels: {
			"resource.opmodel.dev/category": "storage"
		}
	}

	spec: csidriver: schemas.#CSIDriverSchema
}

#CSIDriver: c.#Component & {
	#resources: {(#CSIDriverResource.metadata.fqn): #CSIDriverResource}
}
