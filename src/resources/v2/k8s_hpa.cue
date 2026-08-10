package v2

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// HorizontalPodAutoscaler Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sHorizontalPodAutoscalerResource defines a native Kubernetes HPA v2 as an OPM resource.
// Use this to automatically scale workload replicas based on metrics.
#K8sHorizontalPodAutoscalerResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v2"
		name:           "k8s-horizontalpodautoscaler"
		apiVersion:     "v2"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-horizontalpodautoscaler@v2"
		description:    "A native Kubernetes HorizontalPodAutoscaler resource"
		labels: {
			"resource.opmodel.dev/category": "policy"
		}
	}

	spec: k8sHorizontalpodautoscaler: schemas.#HorizontalPodAutoscalerSchema
}

#K8sHorizontalPodAutoscaler: c.#Component & {
	#resources: {(#K8sHorizontalPodAutoscalerResource.metadata.fqn): #K8sHorizontalPodAutoscalerResource}
}
