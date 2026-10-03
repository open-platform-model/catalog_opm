package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// ValidatingWebhookTransformer converts ValidatingWebhooks resources to
// Kubernetes ValidatingWebhookConfigurations. Names are emitted exactly as
// authored — external controllers (istiod, cert-manager cainjector) reference
// and patch these cluster-scoped objects by name.
#ValidatingWebhookTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "validating-webhook-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/validating-webhook-transformer@\(id.Version)"
		description:    "Converts ValidatingWebhooks resources to Kubernetes ValidatingWebhookConfigurations with exact names"

		labels: {
			"core.opmodel.dev/resource-category": "admission"
			"core.opmodel.dev/resource-type":     "validating-webhooks"
		}
	}

	requiredLabels: {}

	// Required resources - ValidatingWebhooks resource MUST be present
	requiredResources: {
		(res.#ValidatingWebhooksResource.metadata.fqn): res.#ValidatingWebhooksResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["ValidatingWebhookConfiguration"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// Emit one ValidatingWebhookConfiguration per map entry.
		output: [
			for _, cfg in #component.spec.validatingWebhooks
			let _userLabels = [if cfg.labels != _|_ {cfg.labels}, {}][0] {
				apiVersion: "admissionregistration.k8s.io/v1"
				kind:       "ValidatingWebhookConfiguration"
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
