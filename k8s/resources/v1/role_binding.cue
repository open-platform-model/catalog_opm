package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// RoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes RoleBinding that binds a Role or ClusterRole to subjects
// in a namespace.
#RoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "rolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/rolebinding@v1"
		description:    "A native Kubernetes RoleBinding that binds a Role or ClusterRole to subjects in a namespace"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: rolebinding: schemas.#RoleBindingSchema
}

#RoleBinding: c.#Component & {
	#resources: {(#RoleBindingResource.metadata.fqn): #RoleBindingResource}
}
