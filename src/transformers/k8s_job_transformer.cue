package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sJobTransformer passes native Kubernetes Job resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sJobTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-job-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-job-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Job resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "job"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sJobResource.metadata.fqn): res.#K8sJobResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_job:  #component.spec.k8sJob
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
