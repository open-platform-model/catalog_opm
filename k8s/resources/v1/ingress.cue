package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Ingress Resource Definition
/////////////////////////////////////////////////////////////////

// #IngressResource defines a native Kubernetes Ingress as an OPM resource.
// Use this to route external HTTP/HTTPS traffic to in-cluster services.
#IngressResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "ingress"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/ingress@v1"
		description:    "A native Kubernetes Ingress resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: ingress: schemas.#IngressSchema
}

#Ingress: c.#Component & {
	#resources: {(#IngressResource.metadata.fqn): #IngressResource}
}
