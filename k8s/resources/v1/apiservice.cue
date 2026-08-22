package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// APIService Resource Definition
/////////////////////////////////////////////////////////////////

// #APIServiceResource defines a native Kubernetes APIService
// (apiregistration.k8s.io/v1) as an OPM resource. Use this to register an
// aggregated API server (e.g. metrics-server). Cluster-scoped.
#APIServiceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "apiservice"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/apiservice@v1"
		description:    "A native Kubernetes APIService (aggregated API registration) resource"
		labels: {
			"resource.opmodel.dev/category": "apiregistration"
		}
	}

	spec: apiservice: schemas.#APIServiceSchema
}

#APIService: c.#Component & {
	#resources: {(#APIServiceResource.metadata.fqn): #APIServiceResource}
}
