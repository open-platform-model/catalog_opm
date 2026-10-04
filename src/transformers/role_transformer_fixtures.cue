@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Test: namespace-scoped role
_testNsRoleComponent: res.#Role & {
	metadata: name: "ci-bot"
	spec: role: {
		name:  "pod-reader"
		scope: "namespace"
		rules: [{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get", "list", "watch"]
		}]
		subjects: [{
			name:           "ci-bot"
			automountToken: false
		}]
	}
}

_testNsRoleTransformer: (#RoleTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "ci-bot"
			namespace: "default"
			fqn:       "opmodel.dev/modules/ci-bot@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#component: _testNsRoleComponent
	#context: #runtimeName: "opm-test"
}).output

// Test: cluster-scoped role
_testClusterRoleComponent: res.#Role & {
	metadata: name: "admin-bot"
	spec: role: {
		name:  "cluster-reader"
		scope: "cluster"
		rules: [{
			apiGroups: [""]
			resources: ["namespaces"]
			verbs: ["get", "list"]
		}]
		subjects: [{
			name:           "admin-bot"
			automountToken: false
		}]
	}
}

_testClusterRoleTransformer: (#RoleTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "admin-bot"
			namespace: "kube-system"
			fqn:       "opmodel.dev/modules/admin-bot@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#component: _testClusterRoleComponent
	#context: #runtimeName: "opm-test"
}).output

// Test: cluster-scoped role exercising both extended #PolicyRuleSchema forms —
// resourceNames passthrough (cert-manager signer-approval shape), a
// nonResourceURLs rule, and a legacy 3-field rule for backward compatibility.
_testExtendedRulesComponent: res.#Role & {
	metadata: name: "cert-manager"
	spec: role: {
		name:  "cert-manager-controller-approve"
		scope: "cluster"
		rules: [{
			apiGroups: ["cert-manager.io"]
			resources: ["signers"]
			verbs: ["approve"]
			resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
		}, {
			nonResourceURLs: ["/metrics"]
			verbs: ["get"]
		}, {
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		}]
		subjects: [{
			name:           "cert-manager"
			automountToken: false
		}]
	}
}

_testExtendedRulesTransformer: (#RoleTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "cert-manager"
			namespace: "cert-manager"
			fqn:       "opmodel.dev/modules/cert-manager@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#component: _testExtendedRulesComponent
	#context: #runtimeName: "opm-test"
}).output

// Test: EMBEDDED authoring form ({res.#Role, ...}), the fleet's style. Unlike
// the conjunction form above, embedding does not apply closedness to the
// component's own fields, so this is the form that catches a #PolicyRuleSchema
// disjunction that only resolves via closedness. All three rule shapes.
_testEmbeddedRoleComponent: {
	metadata: name: "probe-bot"
	res.#Role
	spec: role: {
		name:  "embedded-probe"
		scope: "cluster"
		rules: [{
			apiGroups: [""]
			resources: ["pods"]
			verbs: ["get"]
		}, {
			apiGroups: ["cert-manager.io"]
			resources: ["signers"]
			verbs: ["approve"]
			resourceNames: ["issuers.cert-manager.io/*"]
		}, {
			nonResourceURLs: ["/metrics"]
			verbs: ["get"]
		}]
		subjects: [{
			name:           "probe-bot"
			automountToken: false
		}]
	}
}

_testEmbeddedRoleOutput: (#RoleTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "probe-bot"
			namespace: "probe"
			fqn:       "opmodel.dev/modules/probe-bot@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#component: _testEmbeddedRoleComponent
	#context: #runtimeName: "opm-test"
}).output

// Interpolation pins: each rendered rule field is forced concrete, so an
// unresolved disjunction or a dropped field errors. `task vet` (CI) evaluates
// these pins; `cue eval -c -t fixtures -e '_testEmbeddedRoleTransformer' ./transformers`
// additionally proves concreteness, which plain vet does not check.
_testEmbeddedRoleTransformer: {
	let R = _testEmbeddedRoleOutput[0].rules
	rule0: "\(R[0].apiGroups[0])|\(R[0].resources[0])|\(R[0].verbs[0])" & "|pods|get"
	rule1: "\(R[1].apiGroups[0])|\(R[1].resourceNames[0])|\(R[1].verbs[0])" & "cert-manager.io|issuers.cert-manager.io/*|approve"
	rule2: "\(R[2].nonResourceURLs[0])|\(R[2].verbs[0])" & "/metrics|get"
	// The nonResourceURLs rule must resolve to the non-resource arm: rendering
	// an apiGroups key on it would mean the disjunction picked the wrong arm.
	noAPIGroupsOnRule2: [
		if R[2].apiGroups != _|_ {"leaked"},
	] & []
}

// Negative: a rule mixing both forms contradicts BOTH arms (each refuses the
// other's fields), so the disjunction is empty and the rule is refused.
_testMixedRuleRefused: [
	if ({
		apiGroups: [""]
		resources: ["pods"]
		nonResourceURLs: ["/metrics"]
		verbs: ["get"]
	} & res.#PolicyRuleSchema) != _|_ {"accepted"},
] & []

// WHY the labels are spelled out: a golden literal unifies ONTO the rendered
// output, so an under-specified labels struct ADDS its keys instead of
// asserting them. This fixture previously claimed `app: "cert-manager"`, which
// the transformer never renders — it was an artifact of the old hand-filled
// #context.labels, and unification was quietly injecting it. The four keys
// below are what #context.labels actually folds.

// Golden fixture — resourceNames passed through verbatim, the
// nonResourceURLs rule rendered without apiGroups/resources keys, and the
// legacy rule rendered without any of the new keys.
_testExtendedRulesTransformer: [
	{
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			name: "cert-manager-controller-approve"
			labels: {
				"app.kubernetes.io/name":           "cert-manager"
				"app.kubernetes.io/instance":       "cert-manager"
				"app.kubernetes.io/managed-by":     "opm-test"
				"module-instance.opmodel.dev/name": "cert-manager"
			}
		}
		rules: [{
			apiGroups: ["cert-manager.io"]
			resources: ["signers"]
			verbs: ["approve"]
			resourceNames: ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*"]
		}, {
			nonResourceURLs: ["/metrics"]
			verbs: ["get"]
		}, {
			apiGroups: [""]
			resources: ["events"]
			verbs: ["create", "patch"]
		}]
	},
	{
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRoleBinding"
		metadata: {
			name: "cert-manager-controller-approve"
			labels: {
				"app.kubernetes.io/name":           "cert-manager"
				"app.kubernetes.io/instance":       "cert-manager"
				"app.kubernetes.io/managed-by":     "opm-test"
				"module-instance.opmodel.dev/name": "cert-manager"
			}
		}
		roleRef: {
			apiGroup: "rbac.authorization.k8s.io"
			kind:     "ClusterRole"
			name:     "cert-manager-controller-approve"
		}
		subjects: [{
			kind: "ServiceAccount"
			name: "cert-manager"
		}]
	},
]
