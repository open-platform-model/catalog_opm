package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sCronJobTransformer passes native Kubernetes CronJob resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sCronJobTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-cronjob-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-cronjob-transformer@\(id.Version)"
		description:    "Passes native Kubernetes CronJob resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "cronjob"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sCronJobResource.metadata.fqn): res.#K8sCronJobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cj:   #component.spec.k8sCronjob
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
