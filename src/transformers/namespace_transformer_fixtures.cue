@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testNamespacesComponent: res.#Namespaces & {
	metadata: name: "namespace"
	spec: namespaces: {
		// Privileged namespace: PSS labels must survive and win over context.
		"metallb-system": {
			labels: {
				"pod-security.kubernetes.io/enforce": "privileged"
				"pod-security.kubernetes.io/audit":   "privileged"
				"pod-security.kubernetes.io/warn":    "privileged"
				// Deliberately collides with the stub context label below —
				// the golden output asserts the user value wins.
				"app.kubernetes.io/name": "metallb"
			}
		}
		// Bare namespace: exact name, context labels only, no annotations.
		"cert-manager": {}
	}
}

_testNamespacesTransformer: (#NamespaceTransformer.#transform & {
	#component: _testNamespacesComponent
	#moduleInstance: {
		metadata: {
			name:      "test-instance"
			namespace: "metallb-system"
			fqn:       "opmodel.dev/modules/test-instance@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

// Golden fixtures — `cue vet -t fixtures` (task vet) fails on any drift, not just schema errors.
_testNamespacesTransformer: [
	{
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "metallb-system"
			labels: {
				"app.kubernetes.io/managed-by":       "opm-test"
				"app.kubernetes.io/instance":         "namespace"
				"module-instance.opmodel.dev/name":   "test-instance"
				"pod-security.kubernetes.io/enforce": "privileged"
				"pod-security.kubernetes.io/audit":   "privileged"
				"pod-security.kubernetes.io/warn":    "privileged"
				// User value wins over the context's component-derived name.
				"app.kubernetes.io/name": "metallb"
			}
		}
	},
	{
		apiVersion: "v1"
		kind:       "Namespace"
		metadata: {
			name: "cert-manager"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "namespace"
				"app.kubernetes.io/name":           "namespace"
				"module-instance.opmodel.dev/name": "test-instance"
			}
		}
	},
]
