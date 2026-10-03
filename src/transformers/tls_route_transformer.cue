package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

// TlsRouteTransformer creates Gateway API TLSRoutes from components with TlsRoute and Expose traits.
// Untyped struct output — see #HttpRouteTransformer for rationale.
#TlsRouteTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "tls-route-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/tls-route-transformer@\(id.Version)"
		description:    "Creates Gateway API TLSRoutes for components with TlsRoute and Expose traits"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "tls-route"
		}
	}

	requiredLabels: {}
	requiredResources: {}
	optionalResources: {}

	// #ExposeTrait is required: a route without a Service has nothing to point
	// at, so that shape is refused at match time instead of rendering a
	// dangling backendRef.
	requiredTraits: {
		(tr.#TlsRouteTrait.metadata.fqn): tr.#TlsRouteTrait
		(tr.#ExposeTrait.metadata.fqn):   tr.#ExposeTrait
	}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_tlsRoute: #component.spec.tlsRoute
		_name:     #component.#names.resourceName
		// The backing Service has one authoritative name field (0019 D22), read
		// through #ServiceName so the reference cannot drift from the Service
		// transformer's output, legacy (<= alpha.5) expose shape included.
		_backendName: (#ServiceName & {#comp: #component}).out

		_tlsAnnotations: {
			if _tlsRoute.tls != _|_ {
				if _tlsRoute.tls.mode != _|_ {
					"route.opmodel.dev/tls-mode": _tlsRoute.tls.mode
				}
				if _tlsRoute.tls.certificateRef != _|_ {
					if _tlsRoute.tls.certificateRef.namespace != _|_ {
						"route.opmodel.dev/tls-certificate-ref": "\(_tlsRoute.tls.certificateRef.namespace)/\(_tlsRoute.tls.certificateRef.name)"
					}
					if _tlsRoute.tls.certificateRef.namespace == _|_ {
						"route.opmodel.dev/tls-certificate-ref": _tlsRoute.tls.certificateRef.name
					}
				}
			}
		}

		_routeAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
			_tlsAnnotations
		}

		output: {
			apiVersion: "gateway.networking.k8s.io/v1alpha2"
			kind:       "TLSRoute"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if len(_routeAnnotations) > 0 {
					annotations: _routeAnnotations
				}
			}
			spec: {
				if _tlsRoute.gatewayRef != _|_ {
					parentRefs: [{
						name: _tlsRoute.gatewayRef.name
						if _tlsRoute.gatewayRef.namespace != _|_ {
							namespace: _tlsRoute.gatewayRef.namespace
						}
					}]
				}

				if _tlsRoute.hostnames != _|_ {
					hostnames: _tlsRoute.hostnames
				}

				rules: [for rule in _tlsRoute.rules {
					backendRefs: [{
						name: _backendName
						port: rule.backendPort
					}]
				}]
			}
		}
	}
}
