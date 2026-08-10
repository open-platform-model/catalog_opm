package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// RoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sRoleBindingResource defines a native Kubernetes RoleBinding as an OPM resource.
// Use this to bind a Role or ClusterRole to subjects within a namespace.
#K8sRoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-rolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-rolebinding@v1"
		description:    "A native Kubernetes RoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: k8sRolebinding: schemas.#RoleBindingSchema
}

#K8sRoleBinding: c.#Component & {
	#resources: {(#K8sRoleBindingResource.metadata.fqn): #K8sRoleBindingResource}
}
