package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sClusterRoleBindingTransformer passes native Kubernetes ClusterRoleBinding resources through
// with OPM context applied (name prefix, labels). ClusterRoleBinding is cluster-scoped: no namespace.
#K8sClusterRoleBindingTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-clusterrolebinding-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-clusterrolebinding-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ClusterRoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "clusterrolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sClusterRoleBindingResource.metadata.fqn): res.#K8sClusterRoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_crb:  #component.spec.k8sClusterrolebinding
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
