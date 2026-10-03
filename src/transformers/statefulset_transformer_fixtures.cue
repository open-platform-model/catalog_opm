@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testSTSModuleInstance: {
	metadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/modules/shop@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testSTSContext: #runtimeName: "opm-test"

_testSTSContainer: {
	name: "db"
	image: {
		repository: "postgres"
		tag:        "17"
		digest:     ""
	}
}

// Default: no resourceName, no expose.name — both names stay instance-scoped.
_testSTSDefaultComponent: {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#Expose

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		expose: {
			type:      "ClusterIP"
			clusterIP: "None"
			ports: pg: {
				targetPort: 5432
			}
		}
	}
}

_testSTSDefaultTransformer: (#StatefulsetTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSDefaultComponent
	#context:        _testSTSContext
}).output

_testSTSDefaultName:        "\(_testSTSDefaultTransformer.metadata.name)" & "shop-db"
_testSTSDefaultServiceName: "\(_testSTSDefaultTransformer.spec.serviceName)" & "shop-db"

// serviceName names the GOVERNING SERVICE, so it follows expose.name through
// #ServiceName, the seam the Service transformer renders through (0019 D22).
//
// resourceName and expose.name are set to DIFFERENT values on purpose.
// metadata.resourceName moves #names.dns.short along with the object name,
// so the Expose wrapper would default the Service to "database" as well; the
// explicit expose.name wins over that default, and the StatefulSet must point
// at the Service that actually renders, not at its own name. If serviceName
// ever collapses onto metadata.name, the second assertion fails.
_testSTSExactComponent: {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#Expose

	metadata: {
		name:         "db"
		resourceName: "database"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		expose: {
			type:      "ClusterIP"
			clusterIP: "None"
			name:      "database-headless"
			ports: pg: {
				targetPort: 5432
			}
		}
	}
}

_testSTSExactTransformer: (#StatefulsetTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSExactComponent
	#context:        _testSTSContext
}).output

_testSTSExactName:        "\(_testSTSExactTransformer.metadata.name)" & "database"
_testSTSExactServiceName: "\(_testSTSExactTransformer.spec.serviceName)" & "database-headless"

// ---- Update strategy: declared value must reach spec.updateStrategy ---------
//
// Regression guard for the same alpha.8 bug fixed in this file and in
// deployment_transformer.cue: `_updateStrategy: *null | { if ... }` always
// resolved to its marked default, so the field was omitted from every
// StatefulSet. jellystat's bundled Postgres asks for OnDelete-style handling
// via Recreate and had been silently rolling instead.
//
// OnDelete rather than RollingUpdate on purpose: RollingUpdate is also the
// Kubernetes default, so a test using it would pass against the broken code.
_testSTSStrategyComponent: {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#UpdateStrategy

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		updateStrategy: type: "OnDelete"
	}
}

_testSTSStrategyTransformer: (#StatefulsetTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSStrategyComponent
	#context:        _testSTSContext
}).output

// One-element-list form, NOT interpolation. The failure mode is an ABSENT
// field, and `"\(x.spec.updateStrategy.type)" & "OnDelete"` does not catch that
// — an absent field is merely incomplete and plain `cue vet` accepts it
// (verified by reintroducing the bug). A list-length conflict fails at every
// vet level.
_testSTSStrategyPresent: [
	if _testSTSStrategyTransformer.spec.updateStrategy != _|_ {
		_testSTSStrategyTransformer.spec.updateStrategy.type
	},
] & ["OnDelete"]

// A component declaring no strategy must not grow one.
_testSTSNoStrategyLeak: [
	if _testSTSExactTransformer.spec.updateStrategy != _|_ {"leaked"},
] & []

// ---- Update strategy: omitted rollingUpdate params must not fail ------------
//
// Same regression family as deployment_transformer.cue: the extraction
// dereferenced `spec.updateStrategy.rollingUpdate` unguarded whenever type was
// RollingUpdate, but #UpdateStrategySchema leaves the substruct optional — a
// schema-legal `updateStrategy: type: "RollingUpdate"` with no partition/surge
// parameters failed the whole transform with an empty disjunction.
_testSTSRollingDefaultsComponent: {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#UpdateStrategy

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		updateStrategy: type: "RollingUpdate"
	}
}

_testSTSRollingDefaultsTransformer: (#StatefulsetTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSRollingDefaultsComponent
	#context:        _testSTSContext
}).output

// The strategy is emitted with its type...
_testSTSRollingDefaultsPresent: [
	if _testSTSRollingDefaultsTransformer.spec.updateStrategy != _|_ {
		_testSTSRollingDefaultsTransformer.spec.updateStrategy.type
	},
] & ["RollingUpdate"]

// ...and no rollingUpdate block is invented for the omitted substruct.
_testSTSRollingDefaultsNoParams: [
	if _testSTSRollingDefaultsTransformer.spec.updateStrategy.rollingUpdate != _|_ {"leaked"},
] & []

// Cross-transformer consistency: serviceName names the governing Service, so
// it must equal the name the Service transformer rendered for the SAME stub.
_testStatefulSetServiceNameMatchesService: "\(_testSTSDefaultTransformer.spec.serviceName)" &
	"\((#ServiceTransformer.#transform & {
		#moduleInstance: _testSTSModuleInstance
		#component:      _testSTSDefaultComponent
		#context:        _testSTSContext
	}).output.metadata.name)"

// Without #Expose the fallback arm is a read of the component's own short DNS
// name, the value a default-named headless Service would carry.
_testSTSNoExposeServiceName: "\(_testSTSStrategyTransformer.spec.serviceName)" & "\(_testSTSStrategyComponent.#names.dns.short)" & "shop-db"

// Legacy shape: a stateful component compiled against a build <= alpha.5,
// whose expose carries `name?: string` unset (the wrapper set no default).
// expose is hand-written on purpose: embedding tr.#Expose gives `name!`.
// Container and #instance are current: their shapes did not move.
_testSTSLegacyExposeComponent: {
	res.#Container

	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		expose: {
			type:      "ClusterIP"
			clusterIP: "None"
			ports: pg: {name: "pg", targetPort: 5432, protocol: "TCP"}
			name?: string
		}
	}
}

_testSTSLegacyExposeTransformer: (#StatefulsetTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSLegacyExposeComponent
	#context:        _testSTSContext
}).output

// serviceName must be the name the #ServiceTransformer renders for the same
// legacy stub: the instance-scoped default the >= alpha.6 wrapper would have set.
_testSTSLegacyExposeServiceName: "\(_testSTSLegacyExposeTransformer.spec.serviceName)" & "\((#ServiceTransformer.#transform & {
	#moduleInstance: _testSTSModuleInstance
	#component:      _testSTSLegacyExposeComponent
	#context:        _testSTSContext
}).output.metadata.name)" & "shop-db"
