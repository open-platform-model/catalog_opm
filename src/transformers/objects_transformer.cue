package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// ObjectsTransformer renders each entry of an objects resource as written.
// exact — the name is the entry's metadata.name (the map key by default),
// never prefixed: objects reference each other by name (roleRef.name, a
// backend's Service). Every field but metadata is copied by comprehension,
// so the #scope definition field is never emitted.
#ObjectsTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "objects-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/objects-transformer@\(id.Version)"
		description:    "Renders each Kubernetes object of an objects resource as written, in the instance namespace when namespaced"

		labels: {
			"core.opmodel.dev/resource-category": "extension"
			"core.opmodel.dev/resource-type":     "objects"
		}
	}

	requiredLabels: {}

	// Required resources - Objects resource MUST be present
	requiredResources: {
		(res.#ObjectsResource.metadata.fqn): res.#ObjectsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// One object per entry. Labels: context labels the object does not
		// set, then the object's own (the object wins, no unify clash).
		output: [
			for _, o in #component.spec.objects
			let _userLabels = [if o.metadata.labels != _|_ {o.metadata.labels}, {}][0] {
				for k, v in o if k != "metadata" {(k): v}
				metadata: {
					for k, v in o.metadata if k != "labels" {(k): v}
					if o.#scope == "Namespaced" if o.metadata.namespace == _|_ {
						namespace: #context.#moduleInstanceMetadata.namespace
					}
					labels: {
						for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
						for k, v in _userLabels {(k): v}
					}
				}
			},
		]
	}
}
