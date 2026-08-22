package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// PodDisruptionBudget Resource Definition
/////////////////////////////////////////////////////////////////

// #PodDisruptionBudgetResource defines a native Kubernetes PodDisruptionBudget as an OPM resource.
// Use this to limit voluntary disruptions during cluster maintenance or rolling updates.
#PodDisruptionBudgetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "poddisruptionbudget"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/poddisruptionbudget@v1"
		description:    "A native Kubernetes PodDisruptionBudget resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	spec: poddisruptionbudget: schemas.#PodDisruptionBudgetSchema
}

#PodDisruptionBudget: c.#Component & {
	#resources: {(#PodDisruptionBudgetResource.metadata.fqn): #PodDisruptionBudgetResource}
}
