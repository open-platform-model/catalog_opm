package v1alpha1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// WHY it is a separate trait and not a field of backup: the policy applies
// to the volumes resource and the command applies to the container resource,
// and a module may want either without the other. Provider-fulfilled like
// the policy: this catalog declares it and ships no transformer, not even a
// stub (0010 D37).

// The backup is the artefact a command writes to stdout; the command owns
// its own quiesce. Renders nothing here; a platform's backup engine adapter
// reads it.
#BackupCommandTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1alpha1"
		name:           "backup-command"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/backup-command@v1alpha1"
		description:    "The backup is the artefact a command writes to stdout; the command owns its quiesce"
		labels: {
			"trait.opmodel.dev/category": "storage"
		}
	}

	fulfilment: "provider"

	// Load-bearing posture (0010 D46): an unhandled command means the
	// artefact is never written. A module may narrow it at the attachment
	// site.
	optional: bool | *false

	appliesTo: [res.#ContainerResource]

	spec: backupCommand: #BackupCommandSchema
}

#BackupCommand: c.#Component & {
	#traits: (#BackupCommandTrait.metadata.fqn): #BackupCommandTrait
}

// WHY no quoting rule on command: an engine that wraps the line in its own
// shell invocation (k8up's sh -c '...') must escape or use an exec form.
// Quoting is the adapter's problem; the contract says "a shell line", and a
// ban on one quote character in the contract only moves the breakage.

// What a component hands an engine to produce a consistent artefact.
// container and command are the contract; the rest tells an adapter how to
// place and name the output.
#BackupCommandSchema: {
	// The component container whose image and environment the command runs
	// in.
	container!: string

	// A shell line that writes the artefact to stdout, with any quiesce
	// inside it. Every engine runs it as `sh -c <command>`.
	//   save-off && save-all flush && sync && tar -C /data -c .
	command!: string & !=""

	// Component volume keys the command reads. Engines that run it in their
	// own pod mount those volumes read-only beside the workload.
	volumes?: [...string]

	// Where a FILE-capturing engine (Velero) puts the output: the adapter
	// appends `> <mount>/<path>` and captures that volume only. A
	// STREAM-consuming engine (k8up) reads stdout and ignores this. A
	// file-capturing adapter refuses a component without it, naming the
	// field.
	landing?: {
		volume!: string
		path!:   string & =~"^[^/].*"
	}

	// Suffix for the artefact's file name; the adapter prefixes instance and
	// component. Absent: the adapter derives one from landing.path or
	// applies its own default.
	fileExtension?: string & =~"^\\.[a-z0-9]+(\\.[a-z0-9]+)*$"

	// An idempotent shell line releasing a quiesce that does not self-heal
	// (Minecraft save-on). Engines with post hooks run it after every
	// capture, successful or not.
	compensate?: string & !=""
}
