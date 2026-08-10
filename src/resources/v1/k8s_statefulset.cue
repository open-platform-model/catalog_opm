package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// StatefulSet Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sStatefulSetResource defines a native Kubernetes StatefulSet as an OPM resource.
// Use this when you need direct control over the StatefulSet spec, e.g. for
// stateful workloads requiring stable network identities or persistent storage.
#K8sStatefulSetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-statefulset"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-statefulset@v1"
		description:    "A native Kubernetes StatefulSet resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sStatefulset: schemas.#StatefulSetSchema
}

#K8sStatefulSet: c.#Component & {
	#resources: {(#K8sStatefulSetResource.metadata.fqn): #K8sStatefulSetResource}
}
