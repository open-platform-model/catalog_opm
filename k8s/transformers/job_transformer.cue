package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #JobTransformer passes native Kubernetes Job resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#JobTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "job-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/job-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Job resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "job"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#JobResource.metadata.fqn): res.#JobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_job:  #component.spec.job
		_name: #component.#names.resourceName

		output: {
			apiVersion: "batch/v1"
			kind:       "Job"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _job.metadata != _|_ {
					if _job.metadata.annotations != _|_ {
						annotations: _job.metadata.annotations
					}
				}
			}
			if _job.spec != _|_ {
				spec: _job.spec
			}
		}
	}
}
