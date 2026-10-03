@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Mirrors istio's stable-channel policy at 1.30.3 under
// experimental.stableValidationPolicy.
_testVAPComponent: res.#ValidatingAdmissionPolicies & {
	metadata: name: "stable-validation-policy"
	spec: validatingAdmissionPolicies: "stable-channel-policy-istio-system.istio.io": {
		failurePolicy: "Fail"
		matchConstraints: {
			objectSelector: matchExpressions: [{
				key:      "istio.io/rev"
				operator: "In"
				values: ["default"]
			}]
			resourceRules: [{
				apiGroups: [
					"security.istio.io",
					"networking.istio.io",
					"telemetry.istio.io",
					"extensions.istio.io",
				]
				apiVersions: ["*"]
				operations: ["CREATE", "UPDATE"]
				resources: ["*"]
			}]
		}
		variables: [{
			name:       "isEnvoyFilter"
			expression: "object.kind == 'EnvoyFilter'"
		}]
		validations: [{
			expression: "!variables.isEnvoyFilter"
			message:    "EnvoyFilter is not supported in the stable channel"
		}]
		binding: name: "stable-channel-policy-binding-istio-system.istio.io"
	}
}

_testVAPTransformer: (#AdmissionPolicyTransformer.#transform & {
	#component: _testVAPComponent
	#moduleInstance: {
		metadata: {
			name:      "istio"
			namespace: "istio-system"
			fqn:       "opmodel.dev/modules/istio@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

// One entry must produce exactly two objects.
_testVAPCount: (len(_testVAPTransformer) + 0) & 2

_testVAPPolicyKind:  "\(_testVAPTransformer[0].kind)" & "ValidatingAdmissionPolicy"
_testVAPBindingKind: "\(_testVAPTransformer[1].kind)" & "ValidatingAdmissionPolicyBinding"

_testVAPPolicyName:  "\(_testVAPTransformer[0].metadata.name)" & "stable-channel-policy-istio-system.istio.io"
_testVAPBindingName: "\(_testVAPTransformer[1].metadata.name)" & "stable-channel-policy-binding-istio-system.istio.io"

// The binding must reference the policy actually rendered — compared against
// the sibling object rather than a literal, so the two cannot drift.
_testVAPBindingTargetsPolicy: "\(_testVAPTransformer[1].spec.policyName)" & "\(_testVAPTransformer[0].metadata.name)"

// apiVersion defaults to v1 and must be concrete on both objects; a regression
// leaving the disjunction unresolved would render an object the API rejects.
_testVAPApiVersion: "\(_testVAPTransformer[0].apiVersion)" & "admissionregistration.k8s.io/v1"

_testVAPBindingActions: [
	if _testVAPTransformer[1].spec.validationActions != _|_ {_testVAPTransformer[1].spec.validationActions[0]},
] & ["Deny"]
