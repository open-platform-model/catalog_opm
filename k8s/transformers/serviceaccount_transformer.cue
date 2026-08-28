package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ServiceAccountTransformer passes native Kubernetes ServiceAccount resources through
// with OPM context applied (name from the component's `#names`, namespace, labels).
#ServiceAccountTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "serviceaccount-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/serviceaccount-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ServiceAccount resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "serviceaccount"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ServiceAccountResource.metadata.fqn): res.#ServiceAccountResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_sa:   #component.spec.serviceaccount
		_name: #component.#names.resourceName

		output: {
			apiVersion: "v1"
			kind:       "ServiceAccount"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _sa.metadata != _|_ {
					if _sa.metadata.annotations != _|_ {
						annotations: _sa.metadata.annotations
					}
				}
			}
			if _sa.automountServiceAccountToken != _|_ {
				automountServiceAccountToken: _sa.automountServiceAccountToken
			}
			if _sa.imagePullSecrets != _|_ {
				imagePullSecrets: _sa.imagePullSecrets
			}
			if _sa.secrets != _|_ {
				secrets: _sa.secrets
			}
		}
	}
}
