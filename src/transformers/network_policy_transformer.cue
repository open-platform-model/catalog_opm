package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

// WHY: #context.componentLabels is computed by core per (component, transformer)
// pair, so the value here is the same one the Deployment / DaemonSet /
// StatefulSet transformer used for `spec.selector.matchLabels`. That is the
// whole reason this is a trait: the selector is derived, never authored, so it
// cannot drift from the pods it is meant to protect.

// NetworkPolicyTransformer converts the #NetworkPolicyTrait to a Kubernetes
// NetworkPolicy whose podSelector is the workload's own rendered pod labels.
#NetworkPolicyTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "network-policy-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/network-policy-transformer@\(id.Version)"
		description:    "Converts the NetworkPolicy trait to a Kubernetes NetworkPolicy selecting the workload's pods"

		labels: {
			"core.opmodel.dev/resource-type": "networkpolicy"
		}
	}

	requiredLabels: {}
	requiredResources: {}

	requiredTraits: {
		(tr.#NetworkPolicyTrait.metadata.fqn): tr.#NetworkPolicyTrait
	}

	optionalResources: {}
	optionalTraits: {}

	producesKinds: ["NetworkPolicy"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_policy: #component.spec.networkPolicy

		output: {
			apiVersion: "networking.k8s.io/v1"
			kind:       "NetworkPolicy"
			metadata: {
				name:      #component.#names.resourceName
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				// Derived, never authored — see the note above.
				podSelector: matchLabels: #context.componentLabels
				policyTypes: _policy.policyTypes
				if _policy.ingress != _|_ {
					ingress: _policy.ingress
				}
				if _policy.egress != _|_ {
					egress: _policy.egress
				}
			}
		}
	}
}
