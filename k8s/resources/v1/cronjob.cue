package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// CronJob Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes CronJob that runs a job on a cron schedule.
#CronJobResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "cronjob"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/cronjob@v1"
		description:    "A native Kubernetes CronJob that runs a job on a cron schedule"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: cronjob: schemas.#CronJobSchema
}

#CronJob: c.#Component & {
	#resources: {(#CronJobResource.metadata.fqn): #CronJobResource}
}
