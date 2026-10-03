@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Transformer fixtures never pass through #Module, so #instance is set by hand
// on the component stub; without it the resourceName default (and the #Expose
// wrapper's expose.name default) is incomplete and a golden would unify
// vacuously (see docs/name-constraints.md).
_testTlsRouteModuleInstance: {
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testTlsRouteContext: #runtimeName: "opm-test"

_testTlsRouteComponent: {
	res.#Container
	tr.#Expose
	tr.#TlsRoute

	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "web"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: {
			name: "web"
			image: {
				repository: "nginx"
				tag:        "1.27"
				digest:     ""
			}
			ports: http: {
				name:       "http"
				targetPort: 8080
			}
		}
		expose: {
			type: "ClusterIP"
			ports: http: {
				targetPort:  8080
				exposedPort: 80
			}
		}
		tlsRoute: {
			gatewayRef: name: "edge"
			rules: [{backendPort: 80}]
		}
	}
}

_testTlsRouteTransformer: (#TlsRouteTransformer.#transform & {
	#moduleInstance: _testTlsRouteModuleInstance
	#component:      _testTlsRouteComponent
	#context:        _testTlsRouteContext
}).output

// The route's own name follows the component's resourceName.
_testTlsRouteNameResolves: "\(_testTlsRouteTransformer.metadata.name)" & "shop-web"

// backendRefs must point at the Service the #ServiceTransformer renders for
// the same stub, whatever expose.name resolves to.
_testTlsRouteBackendResolves: "\(_testTlsRouteTransformer.spec.rules[0].backendRefs[0].name)" & "\((#ServiceTransformer.#transform & {
	#moduleInstance: _testTlsRouteModuleInstance
	#component:      _testTlsRouteComponent
	#context:        _testTlsRouteContext
}).output.metadata.name)" & "shop-web"
