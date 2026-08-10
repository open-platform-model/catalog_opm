package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sDeploymentTransformer passes native Kubernetes Deployment resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sDeploymentTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-deployment-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-deployment-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Deployment resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "deployment"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sDeploymentResource.metadata.fqn): res.#K8sDeploymentResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_deploy: #component.spec.k8sDeployment
		_name:   "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "apps/v1"
			kind:       "Deployment"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _deploy.metadata != _|_ {
					if _deploy.metadata.annotations != _|_ {
						annotations: _deploy.metadata.annotations
					}
				}
			}
			if _deploy.spec != _|_ {
				spec: _deploy.spec
			}
		}
	}
}
