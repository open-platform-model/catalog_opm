package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Role Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sRoleResource defines a native Kubernetes Role as an OPM resource.
// Use this to grant namespace-scoped permissions to subjects.
#K8sRoleResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-role"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-role@v1"
		description:    "A native Kubernetes Role resource"
		labels: {
			"resource.opmodel.dev/category": "rbac"
		}
	}

	spec: k8sRole: schemas.#RoleSchema
}

#K8sRole: c.#Component & {
	#resources: {(#K8sRoleResource.metadata.fqn): #K8sRoleResource}
}
