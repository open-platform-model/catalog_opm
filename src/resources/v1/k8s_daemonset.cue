package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/opm/schemas/k8s"
)

/////////////////////////////////////////////////////////////////
//// DaemonSet Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sDaemonSetResource defines a native Kubernetes DaemonSet as an OPM resource.
// Use this when you need to run a pod on every (or selected) node in the cluster.
#K8sDaemonSetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-daemonset"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-daemonset@v1"
		description:    "A native Kubernetes DaemonSet resource"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: k8sDaemonset: schemas.#DaemonSetSchema
}

#K8sDaemonSet: c.#Component & {
	#resources: {(#K8sDaemonSetResource.metadata.fqn): #K8sDaemonSetResource}
}
