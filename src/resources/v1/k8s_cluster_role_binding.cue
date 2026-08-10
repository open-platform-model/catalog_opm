package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// ClusterRoleBinding Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sClusterRoleBindingResource defines a native Kubernetes ClusterRoleBinding as an OPM resource.
// Use this to bind a ClusterRole to subjects cluster-wide.
#K8sClusterRoleBindingResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-clusterrolebinding"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-clusterrolebinding@v1"
		description:    "A native Kubernetes ClusterRoleBinding resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: k8sClusterrolebinding: schemas.#ClusterRoleBindingSchema
}

#K8sClusterRoleBinding: c.#Component & {
	#resources: {(#K8sClusterRoleBindingResource.metadata.fqn): #K8sClusterRoleBindingResource}
}
