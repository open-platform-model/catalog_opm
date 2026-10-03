@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testPDBComponent: {
	#instance: {name: "istio", namespace: "istio-system", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#DisruptionBudget

	metadata: {
		name:         "istiod"
		resourceName: "istiod"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: {
			name: "discovery"
			image: {
				repository: "docker.io/istio/pilot"
				tag:        "1.30.3-distroless"
				digest:     ""
			}
		}
		disruptionBudget: minAvailable: 1
	}
}

_testPDBModuleInstance: {
	metadata: {
		name:      "istio"
		namespace: "istio-system"
		fqn:       "opmodel.dev/modules/istio@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testPDBContext: #runtimeName: "opm-test"

_testPDBTransformer: (#PDBTransformer.#transform & {
	#moduleInstance: _testPDBModuleInstance
	#component:      _testPDBComponent
	#context:        _testPDBContext
}).output

_testPDBName: "\(_testPDBTransformer.metadata.name)" & "istiod"
// Two guards, because one cannot do the job: the empty-comprehension form
// catches the field being DROPPED (an absent optional is merely incomplete,
// which plain `cue vet` accepts), and the arithmetic form catches a WRONG
// value non-invertibly. Verified by deleting the minAvailable passthrough and
// by removing matchN from the schema — with only the arithmetic guard, both
// regressions passed silently.
_testPDBMinAvailablePresent: [
	if _testPDBTransformer.spec.minAvailable != _|_ {"present"},
] & ["present"]

_testPDBMinAvailableValue: (_testPDBTransformer.spec.minAvailable + 0) & 1

// The disjunction means exactly one of the two fields is ever emitted; a
// transformer that stamped both would produce an object the API server rejects.
_testPDBNoMaxUnavailable: [
	if _testPDBTransformer.spec.maxUnavailable != _|_ {"leaked"},
] & []

// The budget must select exactly the workload's pods, so its selector has to be
// the same value the Deployment transformer used. Compared by length
// (non-invertible) plus a per-key presence check.
_testPDBSelectorSize: (len(_testPDBTransformer.spec.selector.matchLabels) + 0) & 3

_testPDBSelectorMatchesDeployment: [
	for k, v in (#DeploymentTransformer.#transform & {
		#moduleInstance: _testPDBModuleInstance
		#component:      _testPDBComponent
		#context:        _testPDBContext
	}).output.spec.selector.matchLabels if _testPDBTransformer.spec.selector.matchLabels[k] == v {k},
] & [_, _, _]

// Default naming: no metadata.resourceName, so the budget carries the component's
// instance-scoped resourceName, byte-identical to the Deployment's name.
_testPDBDefaultNameComponent: {
	res.#Container
	tr.#DisruptionBudget

	#instance: {name: "istio", namespace: "istio-system", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "istiod"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: {
			name: "discovery"
			image: {
				repository: "docker.io/istio/pilot"
				tag:        "1.30.3-distroless"
				digest:     ""
			}
		}
		disruptionBudget: minAvailable: 1
	}
}

_testPDBDefaultNameTransformer: (#PDBTransformer.#transform & {
	#moduleInstance: _testPDBModuleInstance
	#component:      _testPDBDefaultNameComponent
	#context:        _testPDBContext
}).output

_testPDBDefaultNameResolves: "\(_testPDBDefaultNameTransformer.metadata.name)" & "istio-istiod"

// Cross-transformer consistency: the PDB's name must equal the name the
// Deployment transformer rendered for the SAME component (same shape as
// _testHPATargetMatchesDeployment).
_testPDBNameMatchesDeployment: "\(_testPDBDefaultNameTransformer.metadata.name)" &
	"\((#DeploymentTransformer.#transform & {
		#moduleInstance: _testPDBModuleInstance
		#component:      _testPDBDefaultNameComponent
		#context:        _testPDBContext
	}).output.metadata.name)"
