package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ClusterRoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes ClusterRoleBinding that binds a ClusterRole to subjects
// cluster-wide.
#ClusterRoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "clusterrolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/clusterrolebinding@v1"
		description:    "A native Kubernetes ClusterRoleBinding that binds a ClusterRole to subjects cluster-wide"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: clusterrolebinding: schemas.#ClusterRoleBindingSchema
}

#ClusterRoleBinding: c.#Component & {
	#resources: {(#ClusterRoleBindingResource.metadata.fqn): #ClusterRoleBindingResource}
}
