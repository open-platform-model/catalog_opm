package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #VolumeSnapshotClassTransformer passes native VolumeSnapshotClass resources
// through with OPM context applied: the name is the component's resourceName
// (instance-prefixed by default, `metadata.resourceName` overrides it) plus
// labels. VolumeSnapshotClass is cluster-scoped: no namespace.
#VolumeSnapshotClassTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "volumesnapshotclass-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/volumesnapshotclass-transformer@\(id.Version)"
		description:    "Passes native Kubernetes VolumeSnapshotClass resources through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "volumesnapshotclass"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#VolumeSnapshotClassResource.metadata.fqn): res.#VolumeSnapshotClassResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_vsc: #component.spec.volumesnapshotclass

		output: {
			apiVersion: "snapshot.storage.k8s.io/v1"
			kind:       "VolumeSnapshotClass"
			metadata: {
				name:   #component.#names.resourceName
				labels: #context.labels
				if _vsc.metadata != _|_ {
					if _vsc.metadata.annotations != _|_ {
						annotations: _vsc.metadata.annotations
					}
				}
			}
			driver:         _vsc.driver
			deletionPolicy: _vsc.deletionPolicy
			if _vsc.parameters != _|_ {
				parameters: _vsc.parameters
			}
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Transformer fixtures never pass through #Module, so #instance is set by hand
// on the component stub; without it the resourceName default is incomplete and
// a golden would unify vacuously (see docs/name-constraints.md).
_testVolumeSnapshotClassContext: {
	#moduleInstanceMetadata: {
		name:      "openebs"
		namespace: "storage"
		fqn:       "opmodel.dev/catalogs/k8s/openebs@0.1.0"
		version:   "0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: name: "zfs-snap"
	#runtimeName: "opm-test"
	componentAnnotations: {}
}

// Default naming: instance-prefixed resourceName.
_testVolumeSnapshotClassDefaultNameComponent: res.#VolumeSnapshotClass & {
	#instance: {name: "openebs", namespace: "storage", uuid: "00000000-0000-0000-0000-000000000000"}
	metadata: name: "zfs-snap"
	spec: volumesnapshotclass: {
		driver:         "zfs.csi.openebs.io"
		deletionPolicy: "Delete"
		parameters: snapshotType: "zfs"
	}
}

_testVolumeSnapshotClassDefaultNameTransformer: (#VolumeSnapshotClassTransformer.#transform & {
	#component: _testVolumeSnapshotClassDefaultNameComponent
	#context:   _testVolumeSnapshotClassContext
}).output

_testVolumeSnapshotClassDefaultNameResolves: "\(_testVolumeSnapshotClassDefaultNameTransformer.metadata.name)" & "openebs-zfs-snap"

// Override naming: metadata.resourceName wins over the instance prefix.
_testVolumeSnapshotClassOverrideNameComponent: res.#VolumeSnapshotClass & {
	#instance: {name: "openebs", namespace: "storage", uuid: "00000000-0000-0000-0000-000000000000"}
	metadata: {
		name:         "zfs-snap"
		resourceName: "custom"
	}
	spec: volumesnapshotclass: {
		driver:         "zfs.csi.openebs.io"
		deletionPolicy: "Retain"
	}
}

_testVolumeSnapshotClassOverrideNameTransformer: (#VolumeSnapshotClassTransformer.#transform & {
	#component: _testVolumeSnapshotClassOverrideNameComponent
	#context:   _testVolumeSnapshotClassContext
}).output

_testVolumeSnapshotClassOverrideNameResolves: "\(_testVolumeSnapshotClassOverrideNameTransformer.metadata.name)" & "custom"
