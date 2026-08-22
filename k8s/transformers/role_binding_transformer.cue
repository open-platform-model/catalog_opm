package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #RoleBindingTransformer passes native Kubernetes RoleBinding resources through
// with OPM context applied (name prefix, namespace, labels).
#RoleBindingTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "rolebinding-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/rolebinding-transformer@\(id.Version)"
		description:    "Passes native Kubernetes RoleBinding resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "rolebinding"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#RoleBindingResource.metadata.fqn): res.#RoleBindingResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_rb:   #component.spec.rolebinding
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
