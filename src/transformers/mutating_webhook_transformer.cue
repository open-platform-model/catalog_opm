package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// MutatingWebhookTransformer converts MutatingWebhooks resources to
// Kubernetes MutatingWebhookConfigurations. Names are emitted exactly as
// authored — external controllers (istiod, cert-manager cainjector) reference
// and patch these cluster-scoped objects by name.
#MutatingWebhookTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "mutating-webhook-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/mutating-webhook-transformer@\(id.Version)"
		description:    "Converts MutatingWebhooks resources to Kubernetes MutatingWebhookConfigurations with exact names"

		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "mutating-webhooks"
		}
	}

	requiredLabels: {}

	// Required resources - MutatingWebhooks resource MUST be present
	requiredResources: {
		(res.#MutatingWebhooksResource.metadata.fqn): res.#MutatingWebhooksResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["MutatingWebhookConfiguration"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// Emit one MutatingWebhookConfiguration per map entry.
		output: [
			for _, cfg in #component.spec.mutatingWebhooks
			let _userLabels = [if cfg.labels != _|_ {cfg.labels}, {}][0] {
				apiVersion: "admissionregistration.k8s.io/v1"
				kind:       "MutatingWebhookConfiguration"
				metadata: {
					name: cfg.name // exact — patched/referenced by name at runtime
					// Merge labels: context labels the user did not set, then
					// user labels (user wins on conflict, no unify clash).
					labels: {
						for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
						for k, v in _userLabels {(k): v}
					}
					if cfg.annotations != _|_ {
						annotations: cfg.annotations
					}
				}
				webhooks: cfg.webhooks
			},
		]
	}
}
