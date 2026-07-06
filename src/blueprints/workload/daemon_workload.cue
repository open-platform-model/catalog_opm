package workload

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
	res "opmodel.dev/catalogs/opm/resources"
	tr "opmodel.dev/catalogs/opm/traits"
)

#DaemonWorkloadSchema: {
	container:       res.#ContainerSchema
	restartPolicy?:  tr.#RestartPolicySchema
	updateStrategy?: tr.#UpdateStrategySchema
	sidecarContainers?: [...tr.#SidecarContainersSchema]
	initContainers?: [...tr.#InitContainersSchema]
}

#DaemonWorkloadBlueprint: c.#Blueprint & {
	metadata: {
		modulePath:  "\(id.ModulePath)/blueprints/workload"
		version:     id.Version
		name:        "daemon-workload"
		description: "A daemon workload that runs on all (or selected) nodes in a cluster"
	}

	composedResources: [
		res.#ContainerResource,
	]

	composedTraits: [
		tr.#RestartPolicyTrait,
		tr.#UpdateStrategyTrait,
		tr.#SidecarContainersTrait,
		tr.#InitContainersTrait,
	]

	spec: daemonWorkload: #DaemonWorkloadSchema
}

#DaemonWorkload: c.#Component & {
	metadata: labels: {
		"core.opmodel.dev/workload-type": "daemon"
	}

	#blueprints: (#DaemonWorkloadBlueprint.metadata.fqn): #DaemonWorkloadBlueprint

	res.#Container
	tr.#RestartPolicy
	tr.#UpdateStrategy
	tr.#SidecarContainers
	tr.#InitContainers

	// Override spec to propagate values from daemonWorkload.
	//
	// Guards hoisted at component level — do not move back inside the spec
	// block (CUE v0.17.0 closedness regression; see
	// docs/cue-guard-closedness-workaround.md in the catalog_opm repo).
	spec: {
		daemonWorkload: #DaemonWorkloadSchema
		container:      spec.daemonWorkload.container
	}
	if spec.daemonWorkload.restartPolicy != _|_ {
		spec: restartPolicy: spec.daemonWorkload.restartPolicy
	}
	if spec.daemonWorkload.updateStrategy != _|_ {
		spec: updateStrategy: spec.daemonWorkload.updateStrategy
	}
	if spec.daemonWorkload.sidecarContainers != _|_ {
		spec: sidecarContainers: spec.daemonWorkload.sidecarContainers
	}
	if spec.daemonWorkload.initContainers != _|_ {
		spec: initContainers: spec.daemonWorkload.initContainers
	}
}
