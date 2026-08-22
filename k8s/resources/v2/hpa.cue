package v2

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// HorizontalPodAutoscaler Resource Definition
/////////////////////////////////////////////////////////////////

// #HorizontalPodAutoscalerResource defines a native Kubernetes HPA v2 as an OPM resource.
// Use this to automatically scale workload replicas based on metrics.
#HorizontalPodAutoscalerResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v2"
		name:           "horizontalpodautoscaler"
		apiVersion:     "v2"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/horizontalpodautoscaler@v2"
		description:    "A native Kubernetes HorizontalPodAutoscaler resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	spec: horizontalpodautoscaler: schemas.#HorizontalPodAutoscalerSchema
}

#HorizontalPodAutoscaler: c.#Component & {
	#resources: {(#HorizontalPodAutoscalerResource.metadata.fqn): #HorizontalPodAutoscalerResource}
}
