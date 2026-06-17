package traits

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v0"
	res "opmodel.dev/catalogs/opm/resources"
)

#ExposeTrait: c.#Trait & {
	metadata: {
		modulePath:  "\(id.ModulePath)/traits"
		version:     id.Version
		name:        "expose"
		description: "A trait to expose a workload via a service"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	appliesTo: [res.#ContainerResource]

	spec: expose: #ExposeSchema
}

#Expose: c.#Component & {
	#traits: (#ExposeTrait.metadata.fqn): #ExposeTrait
}

// Service expose specification.
#ExposeSchema: {
	ports: [portName=string]: res.#PortSchema & {name: portName}
	type: "ClusterIP" | "NodePort" | "LoadBalancer"

	// clusterIP pins the Service's cluster IP. The only supported value is
	// "None", which makes the Service headless: no virtual IP is allocated and
	// DNS resolves directly to the backing pods. This is the idiomatic governing
	// Service for a StatefulSet's stable per-pod network identity. Omit for a
	// normal virtual-IP Service. Only meaningful with type "ClusterIP".
	clusterIP?: "None"
}
