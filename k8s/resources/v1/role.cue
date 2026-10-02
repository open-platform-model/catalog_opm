package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Role Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes Role that grants permissions within a namespace.
#RoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "role"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/role@v1"
		description:    "A native Kubernetes Role that grants permissions within a namespace"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: role: schemas.#RoleSchema
}

#Role: c.#Component & {
	#resources: {(#RoleResource.metadata.fqn): #RoleResource}
}
