package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Role Resource Definition
/////////////////////////////////////////////////////////////////

// #RoleResource defines a native Kubernetes Role as an OPM resource.
// Use this to grant namespace-scoped permissions to subjects.
#RoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "role"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/role@v1"
		description:    "A native Kubernetes Role resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: role: schemas.#RoleSchema
}

#Role: c.#Component & {
	#resources: {(#RoleResource.metadata.fqn): #RoleResource}
}
