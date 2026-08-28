package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #APIServiceTransformer passes native Kubernetes APIService resources through
// with OPM context applied (labels). APIService is cluster-scoped: no namespace.
//
// Unlike other transformers, the name is NOT instance-prefixed: the aggregation
// layer requires the APIService name to be exactly "<version>.<group>", so the
// user-supplied metadata.name is emitted verbatim.
#APIServiceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "apiservice-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/apiservice-transformer@\(id.Version)"
		description:    "Passes native Kubernetes APIService resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "apiregistration"
			"core.opmodel.dev/resource-type":     "apiservice"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#APIServiceResource.metadata.fqn): res.#APIServiceResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_as: #component.spec.apiservice

		output: {
			apiVersion: "apiregistration.k8s.io/v1"
			kind:       "APIService"
			metadata: {
				// exact — <version>.<group> is the aggregation contract; never prefixed,
				// never overridden.
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

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testAPIServiceContext: {
	#moduleInstanceMetadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/catalogs/k8s/shop@0.1.0"
		version:   "0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: name: "metrics"
	#runtimeName: "opm-test"
	componentAnnotations: {}
}

// Override ignored: metadata.resourceName does not reach an exact-name kind.
_testAPIServiceOverrideIgnoredComponent: res.#APIService & {
	metadata: {
		name:         "metrics"
		resourceName: "custom"
	}
	spec: apiservice: {
		metadata: name: "v1beta1.metrics.k8s.io"
		spec: {
			group:                "metrics.k8s.io"
			version:              "v1beta1"
			groupPriorityMinimum: 100
			versionPriority:      100
		}
	}
}

_testAPIServiceOverrideIgnoredTransformer: (#APIServiceTransformer.#transform & {
	#component: _testAPIServiceOverrideIgnoredComponent
	#context:   _testAPIServiceContext
}).output

_testAPIServiceOverrideIgnoredResolves: "\(_testAPIServiceOverrideIgnoredTransformer.metadata.name)" & "v1beta1.metrics.k8s.io"
