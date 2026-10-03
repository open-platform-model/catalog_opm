@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// One component carrying both naming modes: `api` is immutable and takes a
// content-hash suffix, `db` is mutable and keeps the stable name.
_testSecretNamingComponent: res.#Secrets & {
	metadata: name: "mycomponent"
	spec: secrets: {
		api: {
			immutable: true
			data: token: "s3cr3t"
		}
		db: data: {
			username: "admin"
			password: "hunter2"
		}
	}
}

_testSecretNamingTransformer: (#SecretTransformer.#transform & {
	#component: _testSecretNamingComponent
	#moduleInstance: {
		metadata: {
			name:      "myapp"
			namespace: "myapp-system"
			fqn:       "opmodel.dev/modules/myapp@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

// Golden — an immutable secret carries the content-hash suffix
// (sha256("token=s3cr3t")[:5]), a mutable one keeps the stable name;
// stringData is the authored map verbatim. Order follows map key order.
_testSecretNamingTransformer: [
	{
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      "myapp-mycomponent-api-51ff59373f"
			namespace: "myapp-system"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "mycomponent"
				"app.kubernetes.io/name":           "mycomponent"
				"module-instance.opmodel.dev/name": "myapp"
			}
		}
		type:      "Opaque"
		immutable: true
		stringData: token: "s3cr3t"
	},
	{
		apiVersion: "v1"
		kind:       "Secret"
		metadata: {
			name:      "myapp-mycomponent-db"
			namespace: "myapp-system"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "mycomponent"
				"app.kubernetes.io/name":           "mycomponent"
				"module-instance.opmodel.dev/name": "myapp"
			}
		}
		type: "Opaque"
		stringData: {
			username: "admin"
			password: "hunter2"
		}
	},
]
