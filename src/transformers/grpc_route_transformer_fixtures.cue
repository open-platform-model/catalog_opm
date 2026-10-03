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
_testGrpcRouteModuleInstance: {
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testGrpcRouteContext: #runtimeName: "opm-test"

_testGrpcRouteComponent: {
	res.#Container
	tr.#Expose
	tr.#GrpcRoute

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
		grpcRoute: {
			gatewayRef: name: "edge"
			rules: [{backendPort: 80}]
		}
	}
}

_testGrpcRouteTransformer: (#GrpcRouteTransformer.#transform & {
	#moduleInstance: _testGrpcRouteModuleInstance
	#component:      _testGrpcRouteComponent
	#context:        _testGrpcRouteContext
}).output

// The route's own name follows the component's resourceName.
_testGrpcRouteNameResolves: "\(_testGrpcRouteTransformer.metadata.name)" & "shop-web"

// backendRefs must point at the Service the #ServiceTransformer renders for
// the same stub, whatever expose.name resolves to.
_testGrpcRouteBackendResolves: "\(_testGrpcRouteTransformer.spec.rules[0].backendRefs[0].name)" & "\((#ServiceTransformer.#transform & {
	#moduleInstance: _testGrpcRouteModuleInstance
	#component:      _testGrpcRouteComponent
	#context:        _testGrpcRouteContext
}).output.metadata.name)" & "shop-web"
