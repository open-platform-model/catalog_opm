package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sPersistentVolumeTransformer passes native Kubernetes PV resources through
// with OPM context applied (name prefix, labels). PV is cluster-scoped: no namespace.
#K8sPersistentVolumeTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-persistentvolume-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-persistentvolume-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PersistentVolume resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolume"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sPersistentVolumeResource.metadata.fqn): res.#K8sPersistentVolumeResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pv:   #component.spec.k8sPersistentvolume
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "PersistentVolume"
			metadata: {
				name:   _name
				labels: #context.labels
				if _pv.metadata != _|_ {
					if _pv.metadata.annotations != _|_ {
						annotations: _pv.metadata.annotations
					}
				}
			}
			if _pv.spec != _|_ {
				spec: _pv.spec
			}
		}
	}
}
