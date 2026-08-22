package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// IngressClass Resource Definition
/////////////////////////////////////////////////////////////////

// #IngressClassResource defines a native Kubernetes IngressClass as an OPM resource.
// Use this to configure cluster-scoped ingress controller implementations.
#IngressClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "ingressclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/ingressclass@v1"
		description:    "A native Kubernetes IngressClass resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: ingressclass: schemas.#IngressClassSchema
}

#IngressClass: c.#Component & {
	#resources: {(#IngressClassResource.metadata.fqn): #IngressClassResource}
}
