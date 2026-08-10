package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sPersistentVolumeClaimTransformer passes native Kubernetes PVC resources through
// with OPM context applied (name prefix, namespace, labels).
#K8sPersistentVolumeClaimTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-persistentvolumeclaim-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-persistentvolumeclaim-transformer@\(id.Version)"
		description:    "Passes native Kubernetes PersistentVolumeClaim resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolumeclaim"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sPersistentVolumeClaimResource.metadata.fqn): res.#K8sPersistentVolumeClaimResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_pvc:  #component.spec.k8sPersistentvolumeclaim
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
