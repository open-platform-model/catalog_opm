package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ClusterRoleTransformer passes native Kubernetes ClusterRole resources through
// with OPM context applied (name from the component's `#names`, labels). ClusterRole is cluster-scoped: no namespace.
#ClusterRoleTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "clusterrole-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/clusterrole-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ClusterRole resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrole"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ClusterRoleResource.metadata.fqn): res.#ClusterRoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cr:   #component.spec.clusterrole
		_name: #component.#names.resourceName

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: {
				name:   _name
				labels: #context.labels
				if _cr.metadata != _|_ {
					if _cr.metadata.annotations != _|_ {
						annotations: _cr.metadata.annotations
					}
				}
			}
			if _cr.rules != _|_ {
				rules: _cr.rules
			}
			if _cr.aggregationRule != _|_ {
				aggregationRule: _cr.aggregationRule
			}
		}
	}
}
