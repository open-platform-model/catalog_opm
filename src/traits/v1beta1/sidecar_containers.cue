package v1beta1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// Additional containers that run beside a workload's main container.
#SidecarContainersTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1beta1"
		name:           "sidecar-containers"
		apiVersion:     "v1beta1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/sidecar-containers@v1beta1"
		description:    "Additional containers that run beside a workload's main container"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	// Advisory posture (0010 D46): a workload without this trait still
	// renders; a module may narrow the default at the attachment site.
	optional: bool | *true

	appliesTo: [res.#ContainerResource]

	spec: sidecarContainers: [...#SidecarContainersSchema]
}

#SidecarContainers: c.#Component & {
	#traits: (#SidecarContainersTrait.metadata.fqn): #SidecarContainersTrait
}

// Sidecar container shape — alias of #ContainerSchema.
#SidecarContainersSchema: res.#ContainerSchema
