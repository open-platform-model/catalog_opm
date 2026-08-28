package v1beta1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// Deprecated: set #Component.metadata.resourceName instead; removed in a
// later catalog release. Renders a workload under an exact name instead of
// the instance-scoped default.
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

// Deprecated: set #Component.metadata.resourceName instead; removed in a
// later catalog release. Component wrapper attaching #ResourceNameTrait.
#ResourceName: c.#Component & {
	#traits: (#ResourceNameTrait.metadata.fqn): #ResourceNameTrait
}

// WHY: Opt-in, and only correct when the
// name is a contract with something OUTSIDE the module — Istio's CNI plugin
// recognises its own agent pod by the `istio-cni-node-` name prefix and, in a
// degraded state where it cannot reach the API server, uses that check to let
// its own replacement pod through. A prefixed name fails the check and the
// plugin blocks its own replacement.
//
// Exact names are not instance-safe: two instances of the same module in one
// namespace would collide, so the default stays prefixed. #ExposeSchema.name
// is the Service-side counterpart, since 0019 D22 an always-read field the
// #Expose wrapper defaults from the component's own short DNS name.
//
// This governs the rendered object name ONLY. The pod selector stays
// instance-scoped (see #context.componentLabels) so two instances never fight
// over each other's pods. Migration semantics differ: this trait renamed the
// workload object alone, while metadata.resourceName also moves
// #names.dns.* and with it the #Expose wrapper's default Service name.

// Deprecated: set #Component.metadata.resourceName instead (note it also
// moves the DNS names); removed in a later catalog release.
// Explicit workload name, rendered verbatim instead of the default
// instance-scoped {instance}-{component}. Opt-in; only correct for a name
// that is a contract with something outside the module.
// See docs/name-constraints.md.
#ResourceNameSchema: string
