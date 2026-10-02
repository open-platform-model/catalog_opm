package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// ObjectsTransformer renders each entry of an objects resource as written.
// exact — the name is the entry's metadata.name (the map key by default),
// never prefixed: objects reference each other by name (roleRef.name, a
// backend's Service). Every field but metadata is copied by comprehension,
// so the #scope definition field is never emitted.
#ObjectsTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "objects-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/objects-transformer@\(id.Version)"
		description:    "Renders each Kubernetes object of an objects resource as written, in the instance namespace when namespaced"

		labels: {
			"core.opmodel.dev/resource-category": "extension"
			"core.opmodel.dev/resource-type":     "objects"
		}
	}

	requiredLabels: {}

	// Required resources - Objects resource MUST be present
	requiredResources: {
		(res.#ObjectsResource.metadata.fqn): res.#ObjectsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		// One object per entry. Labels: context labels the object does not
		// set, then the object's own (the object wins, no unify clash).
		output: [
			for _, o in #component.spec.objects
			let _userLabels = [if o.metadata.labels != _|_ {o.metadata.labels}, {}][0] {
				for k, v in o if k != "metadata" {(k): v}
				metadata: {
					for k, v in o.metadata if k != "labels" {(k): v}
					if o.#scope == "Namespaced" if o.metadata.namespace == _|_ {
						namespace: #context.#moduleInstanceMetadata.namespace
					}
					labels: {
						for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
						for k, v in _userLabels {(k): v}
					}
				}
			},
		]
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testObjectsModuleInstance: {
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testObjectsDeployment: {
	apiVersion: "apps/v1"
	kind:       "Deployment"
	spec: {
		selector: matchLabels: app: "web"
		template: {
			metadata: labels: app: "web"
			spec: containers: [{name: "web", image: "nginx:1.29"}]
		}
	}
}

// A built-in namespaced kind, a built-in cluster-scoped kind and a custom
// resource stating its scope.
_testObjectsComponent: res.#Objects & {
	metadata: name: "extras"
	spec: objects: {
		web: _testObjectsDeployment
		"web-reader": {
			apiVersion: "rbac.authorization.k8s.io/v1"
			kind:       "ClusterRole"
			metadata: labels: "app.kubernetes.io/name": "web"
			rules: [{apiGroups: [""], resources: ["pods"], verbs: ["get"]}]
		}
		selfsigned: {
			#scope:     "Cluster"
			apiVersion: "cert-manager.io/v1"
			kind:       "ClusterIssuer"
			metadata: annotations: "example.com/owner": "platform"
			spec: selfSigned: {}
		}
	}
}

_testObjectsTransformer: (#ObjectsTransformer.#transform & {
	#moduleInstance: _testObjectsModuleInstance
	#component:      _testObjectsComponent
	#context: #runtimeName: "opm-test"
}).output

// Golden fixture: names are the map keys, unprefixed; only the Deployment
// takes the instance namespace; the object's label wins over the context's.
_testObjectsTransformer: [
	{
		apiVersion: "apps/v1"
		kind:       "Deployment"
		metadata: {
			name:      "web"
			namespace: "apps"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "extras"
				"app.kubernetes.io/name":           "extras"
				"module-instance.opmodel.dev/name": "shop"
			}
		}
		spec: selector: matchLabels: app: "web"
	},
	{
		apiVersion: "rbac.authorization.k8s.io/v1"
		kind:       "ClusterRole"
		metadata: {
			name: "web-reader"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "extras"
				"app.kubernetes.io/name":           "web"
				"module-instance.opmodel.dev/name": "shop"
			}
		}
		rules: [{apiGroups: [""], resources: ["pods"], verbs: ["get"]}]
	},
	{
		apiVersion: "cert-manager.io/v1"
		kind:       "ClusterIssuer"
		metadata: {
			name: "selfsigned"
			annotations: "example.com/owner": "platform"
		}
		spec: selfSigned: {}
	},
]

// A golden literal asserts presence only: the cluster-scoped objects carry no
// namespace, and no object carries #scope.
_testObjectsNoNamespaceOnClusterObjects: [
	for i in [1, 2] if _testObjectsTransformer[i].metadata.namespace != _|_ {"leaked"},
] & []
_testObjectsNoScopeRendered: [
	for o in _testObjectsTransformer if o.#scope != _|_ {"leaked"},
] & []

// An author-set namespace is kept, on a built-in kind and on a custom one.
_testObjectsOwnNamespaceComponent: res.#Objects & {
	metadata: name: "extras"
	spec: objects: {
		web: _testObjectsDeployment & {metadata: namespace: "edge"}
		ca: {
			#scope:     "Namespaced"
			apiVersion: "cert-manager.io/v1"
			kind:       "Issuer"
			metadata: namespace: "cert-manager"
			spec: ca: secretName: "root-ca"
		}
	}
}

_testObjectsOwnNamespaceTransformer: (#ObjectsTransformer.#transform & {
	#moduleInstance: _testObjectsModuleInstance
	#component:      _testObjectsOwnNamespaceComponent
	#context: #runtimeName: "opm-test"
}).output

_testObjectsOwnNamespaceTransformer: [
	{kind: "Deployment", metadata: {name: "web", namespace: "edge"}},
	{kind: "Issuer", metadata: {name: "ca", namespace: "cert-manager"}},
]

// Embedded form (AGENTS.md, Struct disjunctions): the wrapper embedded rather
// than unified, with a custom resource taking the instance namespace.
_testObjectsEmbeddedComponent: {
	res.#Objects
	metadata: name: "monitoring"
	spec: objects: "web-metrics": {
		#scope:     "Namespaced"
		apiVersion: "monitoring.coreos.com/v1"
		kind:       "ServiceMonitor"
		spec: endpoints: [{port: "http"}]
	}
}

_testObjectsEmbeddedTransformer: (#ObjectsTransformer.#transform & {
	#moduleInstance: _testObjectsModuleInstance
	#component:      _testObjectsEmbeddedComponent
	#context: #runtimeName: "opm-test"
}).output

_testObjectsEmbeddedTransformer: [{
	apiVersion: "monitoring.coreos.com/v1"
	kind:       "ServiceMonitor"
	metadata: {
		name:      "web-metrics"
		namespace: "apps"
		labels: "app.kubernetes.io/instance": "monitoring"
	}
	spec: endpoints: [{port: "http"}]
}]

// Refusals. Each case is unified with the resource's map value; the guard
// lists the cases that do NOT evaluate to an error, and must stay empty. A
// valid twin per arm keeps the guard from passing on a merely incomplete case.
_testObjectsEntry: res.#ObjectsResource.spec.objects & {x: _}
_testObjectsAccepted: [
	for n, o in {
		deployment: _testObjectsDeployment
		clusterRole: {apiVersion: "rbac.authorization.k8s.io/v1", kind: "ClusterRole"}
		customCluster: {#scope: "Cluster", apiVersion: "cert-manager.io/v1", kind: "ClusterIssuer"}
		statusScoped: {#scope: "Namespaced", apiVersion: "v1", kind: "Status"}
	} if (_testObjectsEntry & {x: o}).x != _|_ {n},
] & ["deployment", "clusterRole", "customCluster", "statusScoped"]
_testObjectsRefused: [
	for n, o in {
		// spec.replica: field not allowed
		unknownField: _testObjectsDeployment & {spec: replica: 2}
		// specc: field not allowed
		unknownTopLevelField: _testObjectsDeployment & {specc: {}}
		// metadata.labelz: field not allowed
		unknownMetadataField: _testObjectsDeployment & {metadata: labelz: {}}
		// apps/v2 Deployment is not a Kubernetes 1.36 kind, and its API group is built in
		builtinGroup: {apiVersion: "apps/v2", kind: "Deployment"}
		builtinCoreGroup: {apiVersion: "v1", kind: "Pods"}
		// cert-manager.io/v1 Issuer is not a Kubernetes 1.36 object kind: set #scope
		missingScope: {apiVersion: "cert-manager.io/v1", kind: "Issuer"}
		// v1 Status is not a Kubernetes 1.36 object kind: set #scope
		unservedKindMissingScope: {apiVersion: "v1", kind: "Status"}
		// #scope: conflicting values "Namespaced" and "Cluster"
		wrongScope: _testObjectsDeployment & {#scope: "Cluster"}
		// rbac.authorization.k8s.io/v1 ClusterRole is cluster-scoped: remove metadata.namespace
		clusterNamespace: {apiVersion: "rbac.authorization.k8s.io/v1", kind: "ClusterRole", metadata: namespace: "apps"}
		customClusterNamespace: {#scope: "Cluster", apiVersion: "cert-manager.io/v1", kind: "ClusterIssuer", metadata: namespace: "apps"}
	} if (_testObjectsEntry & {x: o}).x != _|_ {n},
] & []
