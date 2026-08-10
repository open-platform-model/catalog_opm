package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sNamespaceTransformer passes native Kubernetes Namespace resources through
// with OPM context applied (name prefix, labels). Namespace is cluster-scoped: no namespace in metadata.
#K8sNamespaceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-namespace-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-namespace-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Namespace resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "namespace"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sNamespaceResource.metadata.fqn): res.#K8sNamespaceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_nsSpec: #component.spec.k8sNamespace
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
