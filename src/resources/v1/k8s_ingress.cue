package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Ingress Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sIngressResource defines a native Kubernetes Ingress as an OPM resource.
// Use this to route external HTTP/HTTPS traffic to in-cluster services.
#K8sIngressResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-ingress"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-ingress@v1"
		description:    "A native Kubernetes Ingress resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: k8sIngress: schemas.#IngressSchema
}

#K8sIngress: c.#Component & {
	#resources: {(#K8sIngressResource.metadata.fqn): #K8sIngressResource}
}
