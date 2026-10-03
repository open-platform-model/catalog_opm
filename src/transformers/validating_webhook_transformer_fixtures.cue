@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testValidatingWebhooksComponent: res.#ValidatingWebhooks & {
	metadata: name: "webhooks"
	spec: validatingWebhooks: {
		// istiod patches this config's caBundle by exact name at runtime.
		"istio-validator-istio-system": {
			webhooks: [{
				name: "rev.validation.istio.io"
				clientConfig: service: {
					name:      "istiod"
					namespace: "istio-system"
					path:      "/validate"
					port:      443
				}
				rules: [{
					apiGroups: ["security.istio.io", "networking.istio.io", "telemetry.istio.io", "extensions.istio.io"]
					apiVersions: ["*"]
					operations: ["CREATE", "UPDATE"]
					resources: ["*"]
				}]
				failurePolicy: "Ignore"
				sideEffects:   "None"
				admissionReviewVersions: ["v1"]
				timeoutSeconds: 10
			}]
		}
		// cert-manager keeps upstream labels + the cainjector annotation.
		"cert-manager-webhook": {
			labels: {
				app:                           "webhook"
				"app.kubernetes.io/name":      "webhook"
				"app.kubernetes.io/instance":  "cert-manager"
				"app.kubernetes.io/component": "webhook"
				"app.kubernetes.io/version":   "v1.21.0"
			}
			annotations: {
				"cert-manager.io/inject-ca-from-secret": "cert-manager/cert-manager-webhook-ca"
			}
			webhooks: [{
				name: "webhook.cert-manager.io"
				clientConfig: service: {
					name:      "cert-manager-webhook"
					namespace: "cert-manager"
					path:      "/validate"
				}
				rules: [{
					apiGroups: ["cert-manager.io", "acme.cert-manager.io"]
					apiVersions: ["v1"]
					operations: ["CREATE", "UPDATE"]
					resources: ["*/*"]
				}]
				failurePolicy: "Fail"
				matchPolicy:   "Equivalent"
				sideEffects:   "None"
				admissionReviewVersions: ["v1"]
				namespaceSelector: matchExpressions: [{
					key:      "cert-manager.io/disable-validation"
					operator: "NotIn"
					values: ["true"]
				}]
				timeoutSeconds: 30
			}]
		}
	}
}

_testValidatingWebhooksTransformer: (#ValidatingWebhookTransformer.#transform & {
	#component: _testValidatingWebhooksComponent
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

// Golden fixtures — `cue vet -t fixtures` (task vet) fails on any drift, not just schema errors.
_testValidatingWebhooksTransformer: [
	{
		apiVersion: "admissionregistration.k8s.io/v1"
		kind:       "ValidatingWebhookConfiguration"
		metadata: {
			name: "istio-validator-istio-system"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "webhooks"
				"app.kubernetes.io/name":           "webhooks"
				"module-instance.opmodel.dev/name": "test-instance"
			}
		}
		webhooks: [{
			name: "rev.validation.istio.io"
			clientConfig: service: {
				name:      "istiod"
				namespace: "istio-system"
				path:      "/validate"
				port:      443
			}
			rules: [{
				apiGroups: ["security.istio.io", "networking.istio.io", "telemetry.istio.io", "extensions.istio.io"]
				apiVersions: ["*"]
				operations: ["CREATE", "UPDATE"]
				resources: ["*"]
			}]
			failurePolicy: "Ignore"
			sideEffects:   "None"
			admissionReviewVersions: ["v1"]
			timeoutSeconds: 10
		}]
	},
	{
		apiVersion: "admissionregistration.k8s.io/v1"
		kind:       "ValidatingWebhookConfiguration"
		metadata: {
			name: "cert-manager-webhook"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"module-instance.opmodel.dev/name": "test-instance"
				// User-supplied labels win over the context's component-derived
				// name/instance values.
				app:                           "webhook"
				"app.kubernetes.io/name":      "webhook"
				"app.kubernetes.io/instance":  "cert-manager"
				"app.kubernetes.io/component": "webhook"
				"app.kubernetes.io/version":   "v1.21.0"
			}
			annotations: {
				"cert-manager.io/inject-ca-from-secret": "cert-manager/cert-manager-webhook-ca"
			}
		}
		webhooks: [{
			name: "webhook.cert-manager.io"
			clientConfig: service: {
				name:      "cert-manager-webhook"
				namespace: "cert-manager"
				path:      "/validate"
			}
			rules: [{
				apiGroups: ["cert-manager.io", "acme.cert-manager.io"]
				apiVersions: ["v1"]
				operations: ["CREATE", "UPDATE"]
				resources: ["*/*"]
			}]
			failurePolicy: "Fail"
			matchPolicy:   "Equivalent"
			sideEffects:   "None"
			admissionReviewVersions: ["v1"]
			namespaceSelector: matchExpressions: [{
				key:      "cert-manager.io/disable-validation"
				operator: "NotIn"
				values: ["true"]
			}]
			timeoutSeconds: 30
		}]
	},
]
