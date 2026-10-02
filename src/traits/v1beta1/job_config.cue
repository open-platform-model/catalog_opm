package v1beta1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// Job settings for a task: completions, parallelism, retries and deadlines.
#JobConfigTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1beta1"
		name:           "job-config"
		apiVersion:     "v1beta1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/job-config@v1beta1"
		description:    "Job settings for a task: completions, parallelism, retries and deadlines"
		labels: {
			"trait.opmodel.dev/category": "workload"
		}
	}

	// Advisory posture (0010 D46): a workload without this trait still
	// renders; a module may narrow the default at the attachment site.
	optional: bool | *true

	appliesTo: [res.#ContainerResource]

	spec: jobConfig: #JobConfigSchema
}

#JobConfig: c.#Component & {
	#traits: (#JobConfigTrait.metadata.fqn): #JobConfigTrait
}

#JobConfigSchema: {
	completions?:             uint
	parallelism?:             uint
	backoffLimit?:            uint
	activeDeadlineSeconds?:   uint
	ttlSecondsAfterFinished?: uint
}
