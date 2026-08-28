package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #DeploymentTransformer passes native Kubernetes Deployment resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
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
		_name:   #component.#names.resourceName

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

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Transformer fixtures never pass through #Module, so #instance is set by hand
// on the component stub; without it the resourceName default is incomplete and
// a golden would unify vacuously (see docs/name-constraints.md).
_testDeploymentContext: {
	#moduleInstanceMetadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/catalogs/k8s/shop@0.1.0"
		version:   "0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: name: "web"
	#runtimeName: "opm-test"
	componentAnnotations: {}
}

// Default naming: instance-prefixed resourceName.
_testDeploymentDefaultNameComponent: res.#Deployment & {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}
	metadata: name: "web"
	spec: deployment: spec: {
		selector: matchLabels: app: "web"
		template: {
			metadata: labels: app: "web"
			spec: containers: [{name: "web", image: "nginx:1.27"}]
		}
	}
}

_testDeploymentDefaultNameTransformer: (#DeploymentTransformer.#transform & {
	#component: _testDeploymentDefaultNameComponent
	#context:   _testDeploymentContext
}).output

_testDeploymentDefaultNameResolves: "\(_testDeploymentDefaultNameTransformer.metadata.name)" & "shop-web"
