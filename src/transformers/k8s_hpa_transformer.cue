package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v2"
)

// #K8sHorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sHorizontalPodAutoscalerTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-horizontalpodautoscaler-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-horizontalpodautoscaler-transformer@\(id.Version)"
		description:    "Passes native Kubernetes HorizontalPodAutoscaler resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "horizontalpodautoscaler"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sHorizontalPodAutoscalerResource.metadata.fqn): res.#K8sHorizontalPodAutoscalerResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_hpa:  #component.spec.k8sHorizontalpodautoscaler
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "autoscaling/v2"
			kind:       "HorizontalPodAutoscaler"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _hpa.metadata != _|_ {
					if _hpa.metadata.annotations != _|_ {
						annotations: _hpa.metadata.annotations
					}
				}
			}
			if _hpa.spec != _|_ {
				spec: _hpa.spec
			}
		}
	}
}
