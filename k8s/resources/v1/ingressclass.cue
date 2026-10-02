package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// IngressClass Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes IngressClass that configures an ingress controller
// implementation.
#IngressClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "ingressclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/ingressclass@v1"
		description:    "A native Kubernetes IngressClass that configures an ingress controller implementation"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: ingressclass: schemas.#IngressClassSchema
}

#IngressClass: c.#Component & {
	#resources: {(#IngressClassResource.metadata.fqn): #IngressClassResource}
}
