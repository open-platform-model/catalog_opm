package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	k8scorev1 "opmodel.dev/catalogs/opm/schemas/kubernetes/core/v1"
)

// PVCTransformer creates standalone PersistentVolumeClaims from Volume resources
#PVCTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "pvc-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/pvc-transformer@\(id.Version)"
		description:    "Creates standalone Kubernetes PersistentVolumeClaims from Volume resources"

		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "persistentvolumeclaim"
		}
	}

	requiredLabels: {} // No specific labels required; matches any component with Volumes resource

	// Required resources - Volumes MUST be present
	requiredResources: {
		(res.#VolumesResource.metadata.fqn): res.#VolumesResource
	}

	// No optional resources
	optionalResources: {}

	// No required traits
	requiredTraits: {}

	// No optional traits
	optionalTraits: {}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		// Extract required Volumes resource (will be bottom if not present)
		_volumes: #component.spec.volumes

		// Emit one PVC per volume that declares a persistentClaim. Output is
		// a list of resources; the renderer dispatches on cue.Kind and
		// produces one Compiled per list element.
		output: [
			for volumeName, volume in _volumes if volume.persistentClaim != _|_ {
				k8scorev1.#PersistentVolumeClaim & {
					apiVersion: "v1"
					kind:       "PersistentVolumeClaim"
					metadata: {
						name:      "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)-\(volumeName)"
						namespace: #context.#moduleInstanceMetadata.namespace

						// WHY unification and not a key folded into componentLabels:
						// #context.labels is open and accepts an extra key, while
						// #context.componentLabels is closed and refuses one
						// ("field not allowed", surfaced only as an opaque transformer
						// error at render). The value is the component's volume map key,
						// which is exactly what a policy naming volumes says, so the two
						// sides agree by construction.

						// Rendered labels plus the per-volume selection key. An adapter
						// backing up one of a component's volumes selects that volume's
						// PVC by matching volume.opmodel.dev/name against the volume's
						// map key. Labels are mutable, so the key lands in place.
						labels: #context.labels & {"volume.opmodel.dev/name": volumeName}
						if len(#context.componentAnnotations) > 0 {
							annotations: #context.componentAnnotations
						}
					}
					spec: {
						accessModes: [volume.persistentClaim.accessMode | *"ReadWriteOnce"]
						resources: {
							requests: {
								storage: volume.persistentClaim.size
							}
						}
						if volume.persistentClaim.storageClass != _|_ {
							storageClassName: volume.persistentClaim.storageClass
						}
					}
				}
			},
		]
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Test: a component with two persistentClaim volumes, so the per-volume
// selection key is proved distinct per PVC rather than constant.
_testVolumeLabelComponent: {
	res.#Volumes
	metadata: name: "db"
	spec: volumes: {
		data: persistentClaim: {
			size:         "10Gi"
			accessMode:   "ReadWriteOnce"
			storageClass: "fast"
		}
		exports: persistentClaim: {
			size:         "5Gi"
			accessMode:   "ReadWriteOnce"
			storageClass: "standard"
		}
	}
}

_testVolumeLabelOutput: (#PVCTransformer.#transform & {
	#moduleInstance: metadata: {
		name:      "app"
		namespace: "prod"
	}
	#component: _testVolumeLabelComponent
	#context: #runtimeName: "opm-cli"
}).output

// Interpolation pins: each PVC's name and its volume.opmodel.dev/name label
// are forced concrete together, so a label that went missing, went constant,
// or disagreed with the volume map key errors. `cue eval -c -e
// _testVolumeLabel ./transformers` additionally proves concreteness.
_testVolumeLabel: {
	let P = _testVolumeLabelOutput
	pvc0: "\(P[0].metadata.name)|\(P[0].metadata.labels["volume.opmodel.dev/name"])" & "app-db-data|data"
	pvc1: "\(P[1].metadata.name)|\(P[1].metadata.labels["volume.opmodel.dev/name"])" & "app-db-exports|exports"
}
