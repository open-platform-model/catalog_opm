package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #RoleTransformer passes native Kubernetes Role resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#RoleTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "role-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/role-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Role resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "role"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#RoleResource.metadata.fqn): res.#RoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_role: #component.spec.role
		_name: #component.#names.resourceName

		output: {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "Role"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _role.metadata != _|_ {
					if _role.metadata.annotations != _|_ {
						annotations: _role.metadata.annotations
					}
				}
			}
			if _role.rules != _|_ {
				rules: _role.rules
			}
		}
	}
}
