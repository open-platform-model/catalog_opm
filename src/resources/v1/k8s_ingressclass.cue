package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// IngressClass Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sIngressClassResource defines a native Kubernetes IngressClass as an OPM resource.
// Use this to configure cluster-scoped ingress controller implementations.
#K8sIngressClassResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-ingressclass"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-ingressclass@v1"
		description:    "A native Kubernetes IngressClass resource"
		labels: {
			"resource.opmodel.dev/category": "network"
		}
	}

	spec: k8sIngressclass: schemas.#IngressClassSchema
}

#K8sIngressClass: c.#Component & {
	#resources: {(#K8sIngressClassResource.metadata.fqn): #K8sIngressClassResource}
}
