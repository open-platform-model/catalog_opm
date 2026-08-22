package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// ClusterRoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #ClusterRoleBindingResource defines a native Kubernetes ClusterRoleBinding as an OPM resource.
// Use this to bind a ClusterRole to subjects cluster-wide.
#ClusterRoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "clusterrolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/clusterrolebinding@v1"
		description:    "A native Kubernetes ClusterRoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: clusterrolebinding: schemas.#ClusterRoleBindingSchema
}

#ClusterRoleBinding: c.#Component & {
	#resources: {(#ClusterRoleBindingResource.metadata.fqn): #ClusterRoleBindingResource}
}
