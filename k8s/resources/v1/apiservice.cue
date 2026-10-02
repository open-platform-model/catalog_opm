package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// APIService Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes APIService that registers an aggregated API server.
// Cluster-scoped, apiregistration.k8s.io/v1. Use it for an aggregated API
// server such as metrics-server.
#APIServiceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "apiservice"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/apiservice@v1"
		description:    "A native Kubernetes APIService that registers an aggregated API server"
		labels: {
			"resource.opmodel.dev/category": "apiregistration"
		}
	}

	spec: apiservice: schemas.#APIServiceSchema
}

#APIService: c.#Component & {
	#resources: {(#APIServiceResource.metadata.fqn): #APIServiceResource}
}
