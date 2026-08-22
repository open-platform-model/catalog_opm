package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #PersistentVolumeClaimTransformer passes native Kubernetes PVC resources through
// with OPM context applied (name prefix, namespace, labels).
#PersistentVolumeClaimTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "persistentvolumeclaim-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/persistentvolumeclaim-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PersistentVolumeClaim resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolumeclaim"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#PersistentVolumeClaimResource.metadata.fqn): res.#PersistentVolumeClaimResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pvc:  #component.spec.persistentvolumeclaim
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "v1"
			kind:       "PersistentVolumeClaim"
			metadata: {
				name:      _name
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if _pvc.metadata != _|_ {
					if _pvc.metadata.annotations != _|_ {
						annotations: _pvc.metadata.annotations
					}
				}
			}
			if _pvc.spec != _|_ {
				spec: _pvc.spec
			}
		}
	}
}
