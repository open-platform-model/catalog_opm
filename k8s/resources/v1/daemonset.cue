package v1

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	schemas "opmodel.dev/catalogs/k8s/schemas"
)

/////////////////////////////////////////////////////////////////
//// DaemonSet Resource Definition
/////////////////////////////////////////////////////////////////

// A native Kubernetes DaemonSet that runs a pod on every node, or on selected
// nodes.
#DaemonSetResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "daemonset"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/daemonset@v1"
		description:    "A native Kubernetes DaemonSet that runs a pod on every node, or on selected nodes"
		labels: {
			"resource.opmodel.dev/category": "workload"
		}
	}

	spec: daemonset: schemas.#DaemonSetSchema
}

#DaemonSet: c.#Component & {
	#resources: {(#DaemonSetResource.metadata.fqn): #DaemonSetResource}
}
