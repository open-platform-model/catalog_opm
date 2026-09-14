// Experimental abstraction candidates at v1alpha1 — alpha promises nothing
// (enhancement 0010 D34). A shape change here is a new v1alpha2 file, never
// an in-place mutation.
package v1alpha1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	sch "opmodel.dev/catalogs/opm/schemas"
)

// WHY this catalog ships no transformer for it: fulfilment "provider" says
// the implementation is a platform's, and the declaring catalog ships none
// — not even a stub, because a stub is a provider and the first real one
// then becomes the second (0010 D37). Until a platform carries an adapter,
// attaching this trait refuses the render naming the contract (0010 D28),
// which is the designed behaviour.

// Scheduled backup policy for a component's persistent state. Renders
// nothing here; a platform's backup engine adapter reads it.
#BackupTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1alpha1"
		name:           "backup"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/backup@v1alpha1"
		description:    "Scheduled backup policy for the component's persistent state"
		labels: {
			"trait.opmodel.dev/category": "storage"
		}
	}

	fulfilment: "provider"

	// Load-bearing posture (0010 D46): an unhandled backup means there are
	// no backups. A module may narrow the default at the attachment site.
	optional: bool | *false

	// The policy is about persistent state, so a component without volumes
	// has nothing to back up.
	appliesTo: [res.#VolumesResource]

	spec: backup: #BackupSchema
}

#Backup: c.#Component & {
	#traits: (#BackupTrait.metadata.fqn): #BackupTrait
}

// WHY three of these fields are advisory rather than contractual: under the
// keep-more rule an adapter that ignores method, excludes or maintenance
// captures at least as much as one that honours them, so a wrong reading
// costs storage, never data. A field whose wrong reading could lose data
// would be a contract, not an advisory field; none of these is.

// The backup policy. schedule and retention are the contract; repository
// names a store the PLATFORM registered, never inline storage.
#BackupSchema: {
	schedule!:  sch.#CronSchema
	retention!: #BackupRetentionSchema

	// WHY a name and not an inline store: on Velero a backup location is an
	// admin object and on k8up the credentials Secret must live in the
	// instance namespace. Both are the platform's, never the module's.

	// A repository the platform registered, by name. Absent: the platform's
	// default.
	repository?: sch.#NameType

	// Which of the component's volumes to capture, by volume map key.
	// Absent: all of them. An adapter selects a volume's PVC by matching
	// volume.opmodel.dev/name, which the PVC transformer stamps.
	volumes?: [string, ...string]

	// ADVISORY capture preference; every value is a complete capture.
	method: *"any" | "snapshot" | "filesystem"

	// ADVISORY paths to leave out, under the keep-more rule.
	excludes?: [...string & !=""]

	// ADVISORY repository upkeep, for engines that can maintain their own
	// repository format. An engine without the concept ignores it.
	maintenance?: {
		pruneSchedule?: sch.#CronSchema
		checkSchedule?: sch.#CronSchema
	}
}

// How long captures are kept: keep counts per tier, a keepWithin span, or
// both. At least one tier must be set. An adapter with a single span (Velero
// ttl) takes the longest tier; one with counts maps them directly.
#BackupRetentionSchema: {
	keepLast?:    int & >0
	keepHourly?:  int & >0
	keepDaily?:   int & >0
	keepWeekly?:  int & >0
	keepMonthly?: int & >0
	keepYearly?:  int & >0
	keepWithin?:  string & =~"^[0-9]+[hdw]$"
	matchN(>=1, [
		{keepLast!: _}, {keepHourly!: _}, {keepDaily!: _}, {keepWeekly!: _},
		{keepMonthly!: _}, {keepYearly!: _}, {keepWithin!: _},
	])
}
