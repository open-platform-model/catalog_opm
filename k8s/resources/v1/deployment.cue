package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Deployment Resource Definition
/////////////////////////////////////////////////////////////////

// #DeploymentResource defines a native Kubernetes Deployment as an OPM resource.
// Use this when you need direct control over the Deployment spec without
// OPM's portable Container abstraction.
#DeploymentResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "deployment"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/deployment@v1"
		description:    "A native Kubernetes Deployment resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: deployment: schemas.#DeploymentSchema
}

#Deployment: c.#Component & {
	#resources: {(#DeploymentResource.metadata.fqn): #DeploymentResource}
}
