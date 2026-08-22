package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #DeploymentTransformer passes native Kubernetes Deployment resources through
// with OPM context applied (name prefix, namespace, labels).
#DeploymentTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "deployment-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/deployment-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Deployment resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "workload"
			"core.opmodel.dev/resource-type":     "deployment"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#DeploymentResource.metadata.fqn): res.#DeploymentResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_deploy: #component.spec.deployment
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
