package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #CSIDriverTransformer passes native Kubernetes CSIDriver resources through
// with OPM labels applied. The name renders verbatim from the authored spec
// (exact-name kind); CSIDriver is cluster-scoped: no namespace.
#CSIDriverTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "csidriver-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/csidriver-transformer@\(id.Version)"
		description:    "Passes native Kubernetes CSIDriver resources through with OPM labels applied"
		labels: {
			"core.opmodel.dev/resource-category": "storage"
			"core.opmodel.dev/resource-type":     "csidriver"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#CSIDriverResource.metadata.fqn): res.#CSIDriverResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_csi: #component.spec.csidriver

		output: {
			apiVersion: "storage.k8s.io/v1"
			kind:       "CSIDriver"
			metadata: {
				// exact — kubelet CSINodeInfo registration and StorageClass.provisioner
				// reference this name; never prefixed, never overridden.
				name:   _csi.metadata.name
				labels: #context.labels
				if _csi.metadata.annotations != _|_ {
					annotations: _csi.metadata.annotations
				}
			}
			spec: _csi.spec
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testCSIDriverModuleInstance: {
	metadata: {
		name:      "openebs"
		namespace: "storage"
		fqn:       "opmodel.dev/modules/openebs@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testCSIDriverContext: #runtimeName: "opm-test"

// Exact naming: the authored name renders verbatim, no instance prefix.
_testCSIDriverExactNameComponent: res.#CSIDriver & {
	metadata: name: "zfs-driver"
	spec: csidriver: {
		metadata: name: "zfs.csi.openebs.io"
		spec: {
			attachRequired: false
			podInfoOnMount: false
		}
	}
}

_testCSIDriverExactNameTransformer: (#CSIDriverTransformer.#transform & {
	#moduleInstance: _testCSIDriverModuleInstance
	#component:      _testCSIDriverExactNameComponent
	#context:        _testCSIDriverContext
}).output

_testCSIDriverExactNameResolves: "\(_testCSIDriverExactNameTransformer.metadata.name)" & "zfs.csi.openebs.io"

// Override ignored: metadata.resourceName does not reach an exact-name kind.
_testCSIDriverOverrideIgnoredComponent: res.#CSIDriver & {
	metadata: {
		name:         "zfs-driver"
		resourceName: "custom"
	}
	spec: csidriver: {
		metadata: name:       "zfs.csi.openebs.io"
		spec: attachRequired: false
	}
}

_testCSIDriverOverrideIgnoredTransformer: (#CSIDriverTransformer.#transform & {
	#moduleInstance: _testCSIDriverModuleInstance
	#component:      _testCSIDriverOverrideIgnoredComponent
	#context:        _testCSIDriverContext
}).output

_testCSIDriverOverrideIgnoredResolves: "\(_testCSIDriverOverrideIgnoredTransformer.metadata.name)" & "zfs.csi.openebs.io"
