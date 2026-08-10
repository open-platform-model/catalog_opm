package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// PodDisruptionBudget Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sPodDisruptionBudgetResource defines a native Kubernetes PodDisruptionBudget as an OPM resource.
// Use this to limit voluntary disruptions during cluster maintenance or rolling updates.
#K8sPodDisruptionBudgetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-poddisruptionbudget"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-poddisruptionbudget@v1"
		description:    "A native Kubernetes PodDisruptionBudget resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	spec: k8sPoddisruptionbudget: schemas.#PodDisruptionBudgetSchema
}

#K8sPodDisruptionBudget: c.#Component & {
	#resources: {(#K8sPodDisruptionBudgetResource.metadata.fqn): #K8sPodDisruptionBudgetResource}
}
