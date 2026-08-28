package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// RoleTransformer converts OPM Role resources to Kubernetes RBAC objects.
// Generates both the role and its binding from a single OPM resource:
//   scope: "namespace" → k8s Role + RoleBinding
//   scope: "cluster"   → k8s ClusterRole + ClusterRoleBinding
#RoleTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "role-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/role-transformer@\(id.Version)"
		description:    "Converts Role resources to Kubernetes RBAC Role/ClusterRole and RoleBinding/ClusterRoleBinding"

		labels: {
			"core.opmodel.dev/resource-category": "security"
			"core.opmodel.dev/resource-type":     "role"
		}
	}

	requiredLabels: {}

	// Required resources - Role resource MUST be present
	requiredResources: {
		(res.#RoleResource.metadata.fqn): res.#RoleResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// exact — every RBAC object below renders _role.name verbatim: RoleBindings
		// and ClusterRoleBindings reference the role by name, never prefixed.
		_role: #component.spec.role

		// Build k8s-shaped rules from OPM PolicyRules. Conditional passthrough
		// dispatches on the two #PolicyRuleSchema forms (resource rules vs
		// nonResourceURLs rules).
		_k8sRules: [for r in _role.rules {
			if r.apiGroups != _|_ {
				apiGroups: r.apiGroups
				resources: r.resources
			}
			if r.resourceNames != _|_ {resourceNames: r.resourceNames}
			if r.nonResourceURLs != _|_ {nonResourceURLs: r.nonResourceURLs}
			verbs: r.verbs
		}]

		// Build k8s-shaped subjects from CUE-referenced identities
		_k8sSubjects: [for s in _role.subjects {
			kind:      "ServiceAccount"
			name:      s.name
			namespace: #context.#moduleInstanceMetadata.namespace
		}]

		// Common metadata for both objects
		_commonLabels: #context.labels
		_commonAnnotations: {
			if len(#context.componentAnnotations) > 0 {
				#context.componentAnnotations
			}
		}

		// Emit the (Role|ClusterRole) + (RoleBinding|ClusterRoleBinding) pair
		// based on scope. Output is a list of resources; the renderer
		// dispatches on cue.Kind and produces one Compiled per list element.
		output: [
			if _role.scope == "namespace" {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "Role"
				metadata: {
					name:      _role.name
					namespace: #context.#moduleInstanceMetadata.namespace
					labels:    _commonLabels
					if len(_commonAnnotations) > 0 {
						annotations: _commonAnnotations
					}
				}
				rules: _k8sRules
			},
			if _role.scope == "namespace" {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "RoleBinding"
				metadata: {
					name:      _role.name
					namespace: #context.#moduleInstanceMetadata.namespace
					labels:    _commonLabels
					if len(_commonAnnotations) > 0 {
						annotations: _commonAnnotations
					}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "Role"
					name:     _role.name
				}
				subjects: _k8sSubjects
			},
			if _role.scope == "cluster" {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRole"
				metadata: {
					name:   _role.name
					labels: _commonLabels
					if len(_commonAnnotations) > 0 {
						annotations: _commonAnnotations
					}
				}
				rules: _k8sRules
			},
			if _role.scope == "cluster" {
				apiVersion: "rbac.authorization.k8s.io/v1"
				kind:       "ClusterRoleBinding"
				metadata: {
					name:   _role.name
					labels: _commonLabels
					if len(_commonAnnotations) > 0 {
						annotations: _commonAnnotations
					}
				}
				roleRef: {
					apiGroup: "rbac.authorization.k8s.io"
					kind:     "ClusterRole"
					name:     _role.name
				}
				subjects: _k8sSubjects
			},
		]
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Test: namespace-scoped role
_testNsRoleComponent: res.#Role & {
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
	#component: _testNsRoleComponent
	#context: {
		namespace: "default"
		labels: app: "ci-bot"
		componentAnnotations: {}
	}
}).output

// Test: cluster-scoped role
_testClusterRoleComponent: res.#Role & {
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
	#component: _testClusterRoleComponent
	#context: {
		namespace: "kube-system"
		labels: app: "admin-bot"
		componentAnnotations: {}
	}
}).output

// Test: cluster-scoped role exercising both extended #PolicyRuleSchema forms —
// resourceNames passthrough (cert-manager signer-approval shape), a
// nonResourceURLs rule, and a legacy 3-field rule for backward compatibility.
_testExtendedRulesComponent: res.#Role & {
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
	#component: _testExtendedRulesComponent
	#context: {
		namespace: "cert-manager"
		labels: app: "cert-manager"
		componentAnnotations: {}
	}
}).output

// Golden fixture — resourceNames passed through verbatim, the
// nonResourceURLs rule rendered without apiGroups/resources keys, and the
// legacy rule rendered without any of the new keys.
_testExtendedRulesTransformer: [
	{
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			name: "cert-manager-controller-approve"
			labels: app: "cert-manager"
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
			labels: app: "cert-manager"
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
