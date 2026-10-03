@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testSAResourceComponent: res.#ServiceAccount & {
	metadata: name: "ci-bot"
	spec: serviceAccount: {
		name:           "ci-bot"
		automountToken: false
	}
}

_testSAResourceTransformer: (#ServiceAccountResourceTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "test-instance"
			namespace: "ci"
			fqn:       "opmodel.dev/modules/test-instance@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#component: _testSAResourceComponent
	#context: #runtimeName: "opm-test"
}).output
