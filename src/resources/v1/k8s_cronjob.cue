package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// CronJob Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sCronJobResource defines a native Kubernetes CronJob as an OPM resource.
// Use this for scheduled recurring tasks expressed as cron expressions.
#K8sCronJobResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-cronjob"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-cronjob@v1"
		description:    "A native Kubernetes CronJob resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sCronjob: schemas.#CronJobSchema
}

#K8sCronJob: c.#Component & {
	#resources: {(#K8sCronJobResource.metadata.fqn): #K8sCronJobResource}
}
