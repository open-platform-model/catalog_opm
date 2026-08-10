package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Job Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sJobResource defines a native Kubernetes Job as an OPM resource.
// Use this for batch or one-off tasks that run to completion.
#K8sJobResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-job"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-job@v1"
		description:    "A native Kubernetes Job resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sJob: schemas.#JobSchema
}

#K8sJob: c.#Component & {
	#resources: {(#K8sJobResource.metadata.fqn): #K8sJobResource}
}
