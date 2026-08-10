package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Secret Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sSecretResource defines a native Kubernetes Secret as an OPM resource.
// Use this for sensitive data such as passwords, tokens, and TLS certificates.
#K8sSecretResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-secret"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-secret@v1"
		description:    "A native Kubernetes Secret resource"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	spec: k8sSecret: schemas.#SecretSchema
}

#K8sSecret: c.#Component & {
	#resources: {(#K8sSecretResource.metadata.fqn): #K8sSecretResource}
}
