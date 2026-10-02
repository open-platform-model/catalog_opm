package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Job Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes Job for a batch or one-off task that runs to completion.
#JobResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "job"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/job@v1"
		description:    "A native Kubernetes Job for a batch or one-off task that runs to completion"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: job: schemas.#JobSchema
}

#Job: c.#Component & {
	#resources: {(#JobResource.metadata.fqn): #JobResource}
}
