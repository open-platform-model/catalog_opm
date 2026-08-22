package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// StatefulSet Resource Definition
/////////////////////////////////////////////////////////////////

// #StatefulSetResource defines a native Kubernetes StatefulSet as an OPM resource.
// Use this when you need direct control over the StatefulSet spec, e.g. for
// stateful workloads requiring stable network identities or persistent storage.
#StatefulSetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "statefulset"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/statefulset@v1"
		description:    "A native Kubernetes StatefulSet resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: statefulset: schemas.#StatefulSetSchema
}

#StatefulSet: c.#Component & {
	#resources: {(#StatefulSetResource.metadata.fqn): #StatefulSetResource}
}
