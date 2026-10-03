@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

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
// or disagreed with the volume map key errors. `cue eval -c -t fixtures -e
// _testVolumeLabel ./transformers` additionally proves concreteness.
_testVolumeLabel: {
	let P = _testVolumeLabelOutput
	pvc0: "\(P[0].metadata.name)|\(P[0].metadata.labels["volume.opmodel.dev/name"])" & "app-db-data|data"
	pvc1: "\(P[1].metadata.name)|\(P[1].metadata.labels["volume.opmodel.dev/name"])" & "app-db-exports|exports"
}
