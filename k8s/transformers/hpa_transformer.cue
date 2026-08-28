package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v2"
)

// #HorizontalPodAutoscalerTransformer passes native Kubernetes HPA resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#HorizontalPodAutoscalerTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "horizontalpodautoscaler-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/horizontalpodautoscaler-transformer@\(id.Version)"
		description:    "Passes native Kubernetes HorizontalPodAutoscaler resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "policy"
			"core.opmodel.dev/resource-type":     "horizontalpodautoscaler"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#HorizontalPodAutoscalerResource.metadata.fqn): res.#HorizontalPodAutoscalerResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_hpa:  #component.spec.horizontalpodautoscaler
		_name: #component.#names.resourceName

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
