package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #CronJobTransformer passes native Kubernetes CronJob resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#CronJobTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "cronjob-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/cronjob-transformer@\(id.Version)"
		description:    "Passes native Kubernetes CronJob resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "cronjob"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#CronJobResource.metadata.fqn): res.#CronJobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cj:   #component.spec.cronjob
		_name: #component.#names.resourceName

		output: {
			apiVersion: "batch/v1"
			kind:       "CronJob"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _cj.metadata != _|_ {
					if _cj.metadata.annotations != _|_ {
						annotations: _cj.metadata.annotations
					}
				}
			}
			if _cj.spec != _|_ {
				spec: _cj.spec
			}
		}
	}
}
