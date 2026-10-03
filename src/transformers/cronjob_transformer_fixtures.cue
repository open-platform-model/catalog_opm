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
_testCronJobModuleInstance: {
	metadata: {
		name:      "batch"
		namespace: "jobs"
		fqn:       "opmodel.dev/modules/batch@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testCronJobContext: #runtimeName: "opm-test"

_testCronJobContainer: {
	name: "sync"
	image: {
		repository: "alpine"
		tag:        "3.20"
		digest:     ""
	}
}

// Default naming: <instance>-<component>, read from #names.resourceName.
_testCronJobDefaultNameComponent: {
	res.#Container
	tr.#CronJobConfig

	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "sync"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}

	spec: {
		container: _testCronJobContainer
		cronJobConfig: scheduleCron: "0 * * * *"
	}
}

_testCronJobDefaultNameTransformer: (#CronJobTransformer.#transform & {
	#moduleInstance: _testCronJobModuleInstance
	#component:      _testCronJobDefaultNameComponent
	#context:        _testCronJobContext
}).output

_testCronJobDefaultNameResolves: "\(_testCronJobDefaultNameTransformer.metadata.name)" & "batch-sync"

// Exact naming: metadata.resourceName renders verbatim.
_testCronJobExactNameComponent: {
	res.#Container
	tr.#CronJobConfig

	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name:         "sync"
		resourceName: "nightly-sync"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}

	spec: {
		container: _testCronJobContainer
		cronJobConfig: scheduleCron: "0 * * * *"
	}
}

_testCronJobExactNameTransformer: (#CronJobTransformer.#transform & {
	#moduleInstance: _testCronJobModuleInstance
	#component:      _testCronJobExactNameComponent
	#context:        _testCronJobContext
}).output

_testCronJobExactNameResolves: "\(_testCronJobExactNameTransformer.metadata.name)" & "nightly-sync"
