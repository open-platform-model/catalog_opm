@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Transformer fixtures never pass through #Module, so #instance is set by hand
// on the component stub; without it the resourceName default is incomplete and
// an interpolation guard passes vacuously under plain cue vet (see
// docs/name-constraints.md). cue eval -c on the guards is the gate.
_testJobModuleInstance: {
	metadata: {
		name:      "batch"
		namespace: "jobs"
		fqn:       "opmodel.dev/modules/batch@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testJobContext: #runtimeName: "opm-test"

_testJobContainer: {
	name: "sync"
	image: {
		repository: "alpine"
		tag:        "3.20"
		digest:     ""
	}
}

// Default naming: <instance>-<component>, read from #names.resourceName.
_testJobDefaultNameComponent: {
	res.#Container
	tr.#JobConfig

	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "sync"
		labels: "core.opmodel.dev/workload-type": "task"
	}

	spec: {
		container: _testJobContainer
		jobConfig: backoffLimit: 3
	}
}

_testJobDefaultNameTransformer: (#JobTransformer.#transform & {
	#moduleInstance: _testJobModuleInstance
	#component:      _testJobDefaultNameComponent
	#context:        _testJobContext
}).output

_testJobDefaultNameResolves: "\(_testJobDefaultNameTransformer.metadata.name)" & "batch-sync"

// Exact naming: metadata.resourceName renders verbatim.
_testJobExactNameComponent: {
	res.#Container
	tr.#JobConfig

	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name:         "sync"
		resourceName: "nightly-sync"
		labels: "core.opmodel.dev/workload-type": "task"
	}

	spec: {
		container: _testJobContainer
		jobConfig: backoffLimit: 3
	}
}

_testJobExactNameTransformer: (#JobTransformer.#transform & {
	#moduleInstance: _testJobModuleInstance
	#component:      _testJobExactNameComponent
	#context:        _testJobContext
}).output

_testJobExactNameResolves: "\(_testJobExactNameTransformer.metadata.name)" & "nightly-sync"

// ---- Pod-level seccomp profile alone ----------------------------------------
// The trait sets ONLY a seccomp profile, no other pod-level field, so the
// pod-level presence guard itself is under test: if it does not name
// seccompProfile, no pod securityContext renders at all.
_testJobSeccompComponent: {
	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#SecurityContext
	tr.#JobConfig

	metadata: {
		name: "sync"
		labels: "core.opmodel.dev/workload-type": "task"
	}

	spec: {
		container: _testJobContainer
		securityContext: seccompProfile: type: "RuntimeDefault"
		jobConfig: backoffLimit: 3
	}
}

_testJobSeccompTransformer: (#JobTransformer.#transform & {
	#moduleInstance: _testJobModuleInstance
	#component:      _testJobSeccompComponent
	#context:        _testJobContext
}).output

_testJobSeccompPodProfile: [
	if _testJobSeccompTransformer.spec.template.spec.securityContext.seccompProfile != _|_ {
		_testJobSeccompTransformer.spec.template.spec.securityContext.seccompProfile.type
	},
] & ["RuntimeDefault"]

_testJobSeccompPodNoLocalhostProfile: [
	if _testJobSeccompTransformer.spec.template.spec.securityContext.seccompProfile.localhostProfile != _|_ {"leaked"},
] & []
