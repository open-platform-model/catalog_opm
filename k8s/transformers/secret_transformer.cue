package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #SecretTransformer passes native Kubernetes Secret resources through
// with OPM context applied (name prefix, namespace, labels).
#SecretTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "secret-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/secret-transformer@\(id.Version)"
		description:    "Passes native Kubernetes Secret resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "config"
			"core.opmodel.dev/resource-type":     "secret"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#SecretResource.metadata.fqn): res.#SecretResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_secret: #component.spec.secret
		_name:   "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "Secret"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _secret.metadata != _|_ {
					if _secret.metadata.annotations != _|_ {
						annotations: _secret.metadata.annotations
					}
				}
			}
			if _secret.type != _|_ {
				type: _secret.type
			}
			if _secret.data != _|_ {
				data: _secret.data
			}
			if _secret.stringData != _|_ {
				stringData: _secret.stringData
			}
			if _secret.immutable != _|_ {
				immutable: _secret.immutable
			}
		}
	}
}
