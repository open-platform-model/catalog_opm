@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testMutatingWebhooksComponent: res.#MutatingWebhooks & {
	metadata: name: "webhooks"
	spec: mutatingWebhooks: {
		// istiod patches this config's caBundle by exact name at runtime.
		// Exercises the mutating-only reinvocationPolicy plus both selectors.
		"istio-sidecar-injector": {
			webhooks: [{
				name: "rev.namespace.sidecar-injector.istio.io"
				clientConfig: service: {
					name:      "istiod"
					namespace: "istio-system"
					path:      "/inject"
					port:      443
				}
				rules: [{
					apiGroups: [""]
					apiVersions: ["v1"]
					operations: ["CREATE"]
					resources: ["pods"]
				}]
				failurePolicy: "Ignore"
				sideEffects:   "None"
				admissionReviewVersions: ["v1"]
				namespaceSelector: matchLabels: "istio-injection": "enabled"
				objectSelector: matchExpressions: [{
					key:      "sidecar.istio.io/inject"
					operator: "NotIn"
					values: ["false"]
				}]
				reinvocationPolicy: "Never"
				timeoutSeconds:     10
			}]
		}
	}
}

_testMutatingWebhooksTransformer: (#MutatingWebhookTransformer.#transform & {
	#component: _testMutatingWebhooksComponent
	#moduleInstance: {
		metadata: {
			name:      "test-instance"
			namespace: "istio-system"
			fqn:       "opmodel.dev/modules/test-instance@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

// Golden fixture — `cue vet -t fixtures` (task vet) fails on any drift, not just schema errors.
_testMutatingWebhooksTransformer: [
	{
		apiVersion: "admissionregistration.k8s.io/v1"
		kind:       "MutatingWebhookConfiguration"
		metadata: {
			name: "istio-sidecar-injector"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "webhooks"
				"app.kubernetes.io/name":           "webhooks"
				"module-instance.opmodel.dev/name": "test-instance"
			}
		}
		webhooks: [{
			name: "rev.namespace.sidecar-injector.istio.io"
			clientConfig: service: {
				name:      "istiod"
				namespace: "istio-system"
				path:      "/inject"
				port:      443
			}
			rules: [{
				apiGroups: [""]
				apiVersions: ["v1"]
				operations: ["CREATE"]
				resources: ["pods"]
			}]
			failurePolicy: "Ignore"
			sideEffects:   "None"
			admissionReviewVersions: ["v1"]
			namespaceSelector: matchLabels: "istio-injection": "enabled"
			objectSelector: matchExpressions: [{
				key:      "sidecar.istio.io/inject"
				operator: "NotIn"
				values: ["false"]
			}]
			reinvocationPolicy: "Never"
			timeoutSeconds:     10
		}]
	},
]
