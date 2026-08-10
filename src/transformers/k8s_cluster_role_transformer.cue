package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sClusterRoleTransformer passes native Kubernetes ClusterRole resources through
// with OPM context applied (name prefix, labels). ClusterRole is cluster-scoped: no namespace.
#K8sClusterRoleTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-clusterrole-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-clusterrole-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ClusterRole resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrole"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sClusterRoleResource.metadata.fqn): res.#K8sClusterRoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_cr:   #component.spec.k8sClusterrole
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
