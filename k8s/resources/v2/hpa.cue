package v2

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// HorizontalPodAutoscaler Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes HorizontalPodAutoscaler that scales replicas on metrics.
#HorizontalPodAutoscalerResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v2"
		name:           "horizontalpodautoscaler"
		apiVersion:     "v2"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/horizontalpodautoscaler@v2"
		description:    "A native Kubernetes HorizontalPodAutoscaler that scales replicas on metrics"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	spec: horizontalpodautoscaler: schemas.#HorizontalPodAutoscalerSchema
}

#HorizontalPodAutoscaler: c.#Component & {
	#resources: {(#HorizontalPodAutoscalerResource.metadata.fqn): #HorizontalPodAutoscalerResource}
}
