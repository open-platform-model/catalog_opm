package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sServiceAccountTransformer passes native Kubernetes ServiceAccount resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sServiceAccountTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-serviceaccount-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-serviceaccount-transformer@\(id.Version)"
		description:    "Passes native Kubernetes ServiceAccount resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "rbac"
			"core.opmodel.dev/resource-type":     "serviceaccount"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sServiceAccountResource.metadata.fqn): res.#K8sServiceAccountResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_sa:   #component.spec.k8sServiceaccount
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

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
