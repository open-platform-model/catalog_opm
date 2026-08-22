package v1beta1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

#ResourceNameTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1beta1"
		name:           "resource-name"
		apiVersion:     "v1beta1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/resource-name@v1beta1"
		description:    "Renders a workload under an exact name instead of the instance-scoped default"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	// Advisory posture (0010 D46): a workload without this trait still
	// renders; a module may narrow the default at the attachment site.
	optional: bool | *true

	appliesTo: [res.#ContainerResource]

	spec: resourceName: #ResourceNameSchema
}

#ResourceName: c.#Component & {
	#traits: (#ResourceNameTrait.metadata.fqn): #ResourceNameTrait
}

// Explicit workload name, rendered verbatim instead of the default
// instance-scoped {instance}-{component}. Opt-in, and only correct when the
// name is a contract with something OUTSIDE the module — Istio's CNI plugin
// recognises its own agent pod by the `istio-cni-node-` name prefix and, in a
// degraded state where it cannot reach the API server, uses that check to let
// its own replacement pod through. A prefixed name fails the check and the
// plugin blocks its own replacement.
//
// Exact names are not instance-safe: two instances of the same module in one
// namespace would collide, so the default stays prefixed. Mirrors
// #ExposeSchema.name, which solves the same problem for Services.
//
// This governs the rendered object name ONLY. The pod selector stays
// instance-scoped (see #context.componentLabels) so two instances never fight
// over each other's pods.
#ResourceNameSchema: string
