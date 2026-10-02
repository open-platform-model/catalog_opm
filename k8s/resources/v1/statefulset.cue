package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// StatefulSet Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes StatefulSet, for direct control over the StatefulSet
// spec. Use it for stateful workloads that need stable network identities or
// persistent storage beyond what OPM's abstractions model.
#StatefulSetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "statefulset"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/statefulset@v1"
		description:    "A native Kubernetes StatefulSet, for direct control over the StatefulSet spec"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: statefulset: schemas.#StatefulSetSchema
}

#StatefulSet: c.#Component & {
	#resources: {(#StatefulSetResource.metadata.fqn): #StatefulSetResource}
}
