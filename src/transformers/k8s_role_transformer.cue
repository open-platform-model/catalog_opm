package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sRoleTransformer passes native Kubernetes Role resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sRoleTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-role-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-role-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Role resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "role"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sRoleResource.metadata.fqn): res.#K8sRoleResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_role: #component.spec.k8sRole
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
