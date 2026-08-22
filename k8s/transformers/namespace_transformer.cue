package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #NamespaceTransformer passes native Kubernetes Namespace resources through
// with OPM context applied (name prefix, labels). Namespace is cluster-scoped: no namespace in metadata.
#NamespaceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "namespace-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/namespace-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Namespace resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "namespace"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#NamespaceResource.metadata.fqn): res.#NamespaceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_nsSpec: #component.spec.namespace
		_name:   "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Namespace"
			metadata: {
				name:   _name
				labels: #context.labels
				if _nsSpec.metadata != _|_ {
					if _nsSpec.metadata.annotations != _|_ {
						annotations: _nsSpec.metadata.annotations
					}
				}
			}
			if _nsSpec.spec != _|_ {
				spec: _nsSpec.spec
			}
		}
	}
}
