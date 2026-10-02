package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Secret Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes Secret for sensitive data such as passwords, tokens and
// TLS certificates.
#SecretResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "secret"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/secret@v1"
		description:    "A native Kubernetes Secret for sensitive data such as passwords, tokens and TLS certificates"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	spec: secret: schemas.#SecretSchema
}

#Secret: c.#Component & {
	#resources: {(#SecretResource.metadata.fqn): #SecretResource}
}
