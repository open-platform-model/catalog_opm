package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// APIService Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sAPIServiceResource defines a native Kubernetes APIService
// (apiregistration.k8s.io/v1) as an OPM resource. Use this to register an
// aggregated API server (e.g. metrics-server). Cluster-scoped.
#K8sAPIServiceResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-apiservice"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-apiservice@v1"
		description:    "A native Kubernetes APIService (aggregated API registration) resource"
		labels: {
			"resource.opmodel.dev/category": "apiregistration"
		}
	}

	spec: k8sApiservice: schemas.#APIServiceSchema
}

#K8sAPIService: c.#Component & {
	#resources: {(#K8sAPIServiceResource.metadata.fqn): #K8sAPIServiceResource}
}
