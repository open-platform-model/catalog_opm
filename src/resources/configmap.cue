package resources

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
)

/////////////////////////////////////////////////////////////////
//// ConfigMaps Resource
/////////////////////////////////////////////////////////////////

#ConfigMapsResource: c.#Resource & {
	metadata: {
		modulePath:  "\(id.ModulePath)/resources"
		version:     id.Version
		name:        "config-maps"
		description: "A ConfigMap definition for external configuration"
		labels: {
			"resource.opmodel.dev/category": "config"
		}
	}

	spec: configMaps: [cmName=string]: #ConfigMapSchema & {name: string | *cmName}
}

#ConfigMaps: c.#Component & {
	#resources: (#ConfigMapsResource.metadata.fqn): #ConfigMapsResource
}

/////////////////////////////////////////////////////////////////
//// ConfigMap Schema
/////////////////////////////////////////////////////////////////

// ConfigMap specification.
// `name` is auto-populated from the map key in the resource spec.
#ConfigMapSchema: {
	name!: string
	// Default false so a module that omits `immutable` still renders a
	// concrete value — a bare `bool` leaves the field non-concrete and the
	// instance fails to compile ("incomplete value bool").
	immutable: bool | *false

	// Render `name` verbatim instead of the instance-scoped
	// {instance}-{component}-{name}. Opt-in, and only correct when the name
	// is a contract with something OUTSIDE the module — a controller that
	// reads a well-known ConfigMap (istiod reads mesh config from the
	// ConfigMap literally named `istio`). Exact names are not instance-safe:
	// two instances of the same module in one namespace would collide, so
	// the default stays prefixed.
	exactName: bool | *false

	// An exact-name ConfigMap cannot also be immutable: immutability appends
	// a content-hash suffix, which is precisely the name instability the
	// external reader cannot tolerate. Setting both is a conflict error
	// rather than a silently-ignored field.
	if exactName {
		immutable: false
	}

	data: [string]: string
}

#ConfigMapDefaults: #ConfigMapSchema & {
	immutable: false
	exactName: false
}
