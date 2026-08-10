package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sRoleBindingTransformer passes native Kubernetes RoleBinding resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sRoleBindingTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-rolebinding-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-rolebinding-transformer@\(id.Version)"
		description:    "Passes native Kubernetes RoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "rolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sRoleBindingResource.metadata.fqn): res.#K8sRoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_rb:   #component.spec.k8sRolebinding
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "RoleBinding"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _rb.metadata != _|_ {
					if _rb.metadata.annotations != _|_ {
						annotations: _rb.metadata.annotations
					}
				}
			}
			if _rb.subjects != _|_ {
				subjects: _rb.subjects
			}
			if _rb.roleRef != _|_ {
				roleRef: _rb.roleRef
			}
		}
	}
}
