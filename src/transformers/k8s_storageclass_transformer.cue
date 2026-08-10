package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1"
)

// #K8sStorageClassTransformer passes native Kubernetes StorageClass resources through
// with OPM context applied (name prefix, labels). StorageClass is cluster-scoped: no namespace.
#K8sStorageClassTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "k8s-storageclass-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/k8s-storageclass-transformer@\(id.Version)"
		description:    "Passes native Kubernetes StorageClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "storageclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#K8sStorageClassResource.metadata.fqn): res.#K8sStorageClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_sc:   #component.spec.k8sStorageclass
		_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"

		output: {
			apiVersion: "storage.k8s.io/v1"
			kind:       "StorageClass"
			metadata: {
				name:   _name
				labels: #context.labels
				if _sc.metadata != _|_ {
					if _sc.metadata.annotations != _|_ {
						annotations: _sc.metadata.annotations
					}
				}
			}
			provisioner: _sc.provisioner
			if _sc.reclaimPolicy != _|_ {
				reclaimPolicy: _sc.reclaimPolicy
			}
			if _sc.volumeBindingMode != _|_ {
				volumeBindingMode: _sc.volumeBindingMode
			}
			if _sc.parameters != _|_ {
				parameters: _sc.parameters
			}
			if _sc.allowVolumeExpansion != _|_ {
				allowVolumeExpansion: _sc.allowVolumeExpansion
			}
			if _sc.mountOptions != _|_ {
				mountOptions: _sc.mountOptions
			}
		}
	}
}
