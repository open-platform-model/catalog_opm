package traits

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
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

	// Explicit Service name, rendered verbatim instead of the default
	// instance-scoped {instance}-{component}. Opt-in, and only correct when
	// the name is a contract with something OUTSIDE the module — a
	// well-known in-cluster DNS identity (istiod's `istiod.<ns>.svc`, which
	// its webhook configs, CA clients, and proxies all hard-code).
	// Exact names are not instance-safe: two instances of the same module in
	// one namespace would collide, so the default stays prefixed.
	//
	// Spelled as an explicit name rather than a boolean-plus-implicit-source
	// so the contract is readable at the call site and does not silently
	// depend on what the component happens to be called.
	name?: string
}
