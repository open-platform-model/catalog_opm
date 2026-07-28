package traits

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
	res "opmodel.dev/catalogs/opm/resources"
)

#DisruptionBudgetTrait: c.#Trait & {
	metadata: {
		modulePath:  "\(id.ModulePath)/traits"
		version:     id.Version
		name:        "disruption-budget"
		description: "Availability constraints during voluntary disruptions"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	appliesTo: [res.#ContainerResource]

	spec: disruptionBudget: #DisruptionBudgetSchema
}

#DisruptionBudget: c.#Component & {
	#traits: (#DisruptionBudgetTrait.metadata.fqn): #DisruptionBudgetTrait
}

// Exactly one of minAvailable or maxUnavailable must be set.
//
// Spelled as one struct with matchN rather than a disjunction of two, matching
// #VolumeSchema and #ProjectedSourceSchema. The disjunction form was unusable:
// its arms were open structs, so setting `minAvailable` did not eliminate the
// `maxUnavailable` arm — the value stayed a two-armed disjunction, never became
// concrete, and no PodDisruptionBudget could be rendered from it. matchN
// resolves as soon as one field is set, and makes setting both a hard error
// rather than another silently incomplete value.
#DisruptionBudgetSchema: {
	minAvailable?:   int | string & =~"^[0-9]+%$"
	maxUnavailable?: int | string & =~"^[0-9]+%$"

	matchN(1, [
		{minAvailable!: _},
		{maxUnavailable!: _},
	])
}
