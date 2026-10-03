package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// NamespaceTransformer converts Namespaces resources to Kubernetes Namespaces.
// Names are emitted exactly as authored — namespaces are cluster-scoped
// identities referenced from outside the module (ModuleInstance.metadata,
// RBAC subjects, webhook clientConfigs), so prefixing is never useful.
#NamespaceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "namespace-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/namespace-transformer@\(id.Version)"
		description:    "Converts Namespaces resources to Kubernetes Namespaces with exact names and user-label passthrough"

		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "namespace"
		}
	}

	requiredLabels: {}

	// Required resources - Namespaces resource MUST be present
	requiredResources: {
		(res.#NamespacesResource.metadata.fqn): res.#NamespacesResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["Namespace"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// Emit one K8s Namespace per entry in the component's namespaces map.
		output: [
			for _, ns in #component.spec.namespaces
			let _userLabels = [if ns.labels != _|_ {ns.labels}, {}][0] {
				apiVersion: "v1"
				kind:       "Namespace"
				metadata: {
					name: ns.name // exact — namespaces are externally referenced
					// Merge labels: context labels the user did not set, then
					// user labels (user wins on conflict, no unify clash).
					labels: {
						for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
						for k, v in _userLabels {(k): v}
					}
					if ns.annotations != _|_ {
						annotations: ns.annotations
					}
				}
			},
		]
	}
}
