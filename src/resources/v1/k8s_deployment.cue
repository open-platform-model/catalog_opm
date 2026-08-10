package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// Deployment Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sDeploymentResource defines a native Kubernetes Deployment as an OPM resource.
// Use this when you need direct control over the Deployment spec without
// OPM's portable Container abstraction.
#K8sDeploymentResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-deployment"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-deployment@v1"
		description:    "A native Kubernetes Deployment resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sDeployment: schemas.#DeploymentSchema
}

#K8sDeployment: c.#Component & {
	#resources: {(#K8sDeploymentResource.metadata.fqn): #K8sDeploymentResource}
}
