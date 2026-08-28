package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #PersistentVolumeTransformer passes native Kubernetes PV resources through
// with OPM context applied (name from the component's `#names`, labels). PV is cluster-scoped: no namespace.
#PersistentVolumeTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "persistentvolume-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/persistentvolume-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PersistentVolume resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolume"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PersistentVolumeResource.metadata.fqn): res.#PersistentVolumeResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pv:   #component.spec.persistentvolume
		_name: #component.#names.resourceName

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
