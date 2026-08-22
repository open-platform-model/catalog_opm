package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// RoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #RoleBindingResource defines a native Kubernetes RoleBinding as an OPM resource.
// Use this to bind a Role or ClusterRole to subjects within a namespace.
#RoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "rolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/rolebinding@v1"
		description:    "A native Kubernetes RoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: rolebinding: schemas.#RoleBindingSchema
}

#RoleBinding: c.#Component & {
	#resources: {(#RoleBindingResource.metadata.fqn): #RoleBindingResource}
}
