package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through
// with OPM context applied (name from the component's `#names`, labels). ClusterRoleBinding is cluster-scoped: no namespace.
#ClusterRoleBindingTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "clusterrolebinding-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/clusterrolebinding-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ClusterRoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ClusterRoleBindingResource.metadata.fqn): res.#ClusterRoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_crb:  #component.spec.clusterrolebinding
		_name: #component.#names.resourceName

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRoleBinding"
			metadata: {
				name:   _name
				labels: #context.labels
				if _crb.metadata != _|_ {
					if _crb.metadata.annotations != _|_ {
						annotations: _crb.metadata.annotations
					}
				}
			}
			if _crb.subjects != _|_ {
				subjects: _crb.subjects
			}
			if _crb.roleRef != _|_ {
				roleRef: _crb.roleRef
			}
		}
	}
}
