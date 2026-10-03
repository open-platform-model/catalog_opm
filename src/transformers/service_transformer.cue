package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
	k8scorev1 "opmodel.dev/catalogs/opm/schemas/kubernetes/core/v1"
)

// ServiceTransformer creates Kubernetes Services from components with Expose trait
#ServiceTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "service-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/service-transformer@\(id.Version)"
		description:    "Creates Kubernetes Services for components with Expose trait"

		labels: {
			"core.opmodel.dev/trait-type":    "network"
			"core.opmodel.dev/resource-type": "service"
		}
	}

	requiredLabels: {} // No specific labels required; matches any component with Expose trait

	// Required resources - Container MUST be present to know which ports to expose
	requiredResources: {
		(res.#ContainerResource.metadata.fqn): res.#ContainerResource
	}

	// No optional resources
	optionalResources: {}

	// Required traits - Expose is mandatory for Service creation
	requiredTraits: {
		(tr.#ExposeTrait.metadata.fqn): tr.#ExposeTrait
	}

	// No optional traits
	optionalTraits: {}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		// Extract required Container resource (will be bottom if not present)
		_container: #component.spec.container

		// Extract required Expose trait (will be bottom if not present)
		_expose: #component.spec.expose

		// Build port list from expose trait ports
		// Schema: targetPort = container port, exposedPort = optional external port
		// K8s Service: port = service port (external), targetPort = pod port
		_ports: [
			for portName, portConfig in _expose.ports {
				{
					name: portName
					// WHY: The list-index form is load-bearing. The obvious spelling,
					// `portConfig.exposedPort | *portConfig.targetPort`, reads as
					// "exposedPort, defaulting to targetPort" but means the
					// opposite: a default arm wins over a concrete one, so
					// `443 | *10250` resolves to 10250 and EVERY exposedPort was
					// silently discarded. Unification-based goldens cannot catch
					// it either — `(443 | *10250) & 443` succeeds — hence the
					// resolution guard in service_transformer_fixtures.cue.

					// Service port: exposedPort when the author set one, else targetPort.
					port: [
						if portConfig.exposedPort != _|_ {portConfig.exposedPort},
						portConfig.targetPort,
					][0]
					targetPort: portConfig.targetPort
					// #PortSchema already defaults protocol to TCP; taking it
					// verbatim is what preserves an author's UDP/SCTP (the same
					// `| *"TCP"` bug forced every Service port back to TCP).
					protocol: portConfig.protocol
					if _expose.type == "NodePort" && portConfig.exposedPort != _|_ {
						nodePort: portConfig.exposedPort
					}
				}
			},
		]

		// Build Service resource
		output: k8scorev1.#Service & {
			apiVersion: "v1"
			kind:       "Service"
			metadata: {
				// WHY: the helper's fallback arm is what keeps a component
				// compiled against a build <= alpha.5 (expose.name?: string,
				// unset) rendering here (0010 D27); alpha.6 dropped it and every
				// older module lost its Services. The StatefulSet and route
				// transformers reference this name through the same helper, so
				// the cross-object references cannot drift.

				// Service name through #ServiceName (name_helpers.cue): expose.name
				// when the component set or defaulted it (0019 D22), else the
				// component's own #names.dns.short. See docs/name-constraints.md.
				name: (#ServiceName & {#comp: #component}).out
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				// Include component annotations if present
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				type: _expose.type

				// Headless Service when clusterIP is pinned to "None" (no virtual
				// IP; DNS resolves to backing pods). Omitted otherwise so the API
				// server allocates a cluster IP as usual.
				if _expose.clusterIP != _|_ {
					clusterIP: _expose.clusterIP
				}

				selector: #context.componentLabels

				ports: _ports
			}
		}
	}
}
