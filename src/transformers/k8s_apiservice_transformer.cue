package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sAPIServiceTransformer passes native Kubernetes APIService resources through
// with OPM context applied (labels). APIService is cluster-scoped: no namespace.
//
// Unlike other transformers, the name is NOT instance-prefixed: the aggregation
// layer requires the APIService name to be exactly "<version>.<group>", so the
// user-supplied metadata.name is emitted verbatim.
#K8sAPIServiceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-apiservice-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-apiservice-transformer@\(id.Version)"
		description:    "Passes native Kubernetes APIService resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "apiregistration"
			"core.opmodel.dev/resource-type":     "apiservice"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sAPIServiceResource.metadata.fqn): res.#K8sAPIServiceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_as: #component.spec.k8sApiservice

		output: {
			apiVersion: "apiregistration.k8s.io/v1"
			kind:       "APIService"
			metadata: {
				// Verbatim name (must be "<version>.<group>"); not prefixed.
				name:   _as.metadata.name
				labels: #context.labels
				if _as.metadata.annotations != _|_ {
					annotations: _as.metadata.annotations
				}
			}
			spec: _as.spec
		}
	}
}
