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
_testHttpRouteModuleInstance: {
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testHttpRouteContext: #runtimeName: "opm-test"

_testHttpRouteComponent: {
	res.#Container
	tr.#Expose
	tr.#HttpRoute

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
		httpRoute: {
			gatewayRef: name: "edge"
			rules: [{backendPort: 80}]
		}
	}
}

_testHttpRouteTransformer: (#HttpRouteTransformer.#transform & {
	#moduleInstance: _testHttpRouteModuleInstance
	#component:      _testHttpRouteComponent
	#context:        _testHttpRouteContext
}).output

// The route's own name follows the component's resourceName.
_testHttpRouteNameResolves: "\(_testHttpRouteTransformer.metadata.name)" & "shop-web"

// backendRefs must point at the Service the #ServiceTransformer renders for
// the same stub, whatever expose.name resolves to.
_testHttpRouteBackendResolves: "\(_testHttpRouteTransformer.spec.rules[0].backendRefs[0].name)" & "\((#ServiceTransformer.#transform & {
	#moduleInstance: _testHttpRouteModuleInstance
	#component:      _testHttpRouteComponent
	#context:        _testHttpRouteContext
}).output.metadata.name)" & "shop-web"

// Legacy shape: a routed component compiled against a build <= alpha.5, whose
// expose carries `name?: string` unset. expose is hand-written on purpose
// (embedding tr.#Expose gives `name!`); container, route and #instance are
// current, their shapes did not move. Covers grpc/tcp/tls too: they read the
// backend name through the same #ServiceName line.
_testHttpRouteLegacyExposeComponent: {
	res.#Container
	tr.#HttpRoute

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
			ports: http: {name: "http", targetPort: 8080, exposedPort: 80, protocol: "TCP"}
			name?: string
		}
		httpRoute: {
			gatewayRef: name: "edge"
			rules: [{backendPort: 80}]
		}
	}
}

_testHttpRouteLegacyExposeTransformer: (#HttpRouteTransformer.#transform & {
	#moduleInstance: _testHttpRouteModuleInstance
	#component:      _testHttpRouteLegacyExposeComponent
	#context:        _testHttpRouteContext
}).output

// backendRefs must point at the Service the #ServiceTransformer renders for
// the same legacy stub: the instance-scoped default.
_testHttpRouteLegacyExposeBackendResolves: "\(_testHttpRouteLegacyExposeTransformer.spec.rules[0].backendRefs[0].name)" & "\((#ServiceTransformer.#transform & {
	#moduleInstance: _testHttpRouteModuleInstance
	#component:      _testHttpRouteLegacyExposeComponent
	#context:        _testHttpRouteContext
}).output.metadata.name)" & "shop-web"
