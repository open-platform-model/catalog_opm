package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// Deployment Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes Deployment, for direct control over the Deployment spec.
// Use it when OPM's portable Container abstraction does not model what you
// need.
#DeploymentResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "deployment"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/deployment@v1"
		description:    "A native Kubernetes Deployment, for direct control over the Deployment spec"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: deployment: schemas.#DeploymentSchema
}

#Deployment: c.#Component & {
	#resources: {(#DeploymentResource.metadata.fqn): #DeploymentResource}
}
