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

// ---- Pod-level seccomp profile alone ----------------------------------------
// The trait sets ONLY a seccomp profile, no other pod-level field, so the
// pod-level presence guard itself is under test: if it does not name
// seccompProfile, no pod securityContext renders at all.
_testCronJobSeccompComponent: {
	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#SecurityContext
	tr.#CronJobConfig

	metadata: {
		name: "sync"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}

	spec: {
		container: _testCronJobContainer
		securityContext: seccompProfile: type: "RuntimeDefault"
		cronJobConfig: scheduleCron: "0 * * * *"
	}
}

_testCronJobSeccompTransformer: (#CronJobTransformer.#transform & {
	#moduleInstance: _testCronJobModuleInstance
	#component:      _testCronJobSeccompComponent
	#context:        _testCronJobContext
}).output

_testCronJobSeccompPodProfile: [
	if _testCronJobSeccompTransformer.spec.jobTemplate.spec.template.spec.securityContext.seccompProfile != _|_ {
		_testCronJobSeccompTransformer.spec.jobTemplate.spec.template.spec.securityContext.seccompProfile.type
	},
] & ["RuntimeDefault"]

_testCronJobSeccompPodNoLocalhostProfile: [
	if _testCronJobSeccompTransformer.spec.jobTemplate.spec.template.spec.securityContext.seccompProfile.localhostProfile != _|_ {"leaked"},
] & []

// ---- Pod-level security context without a seccomp profile ----------------
// The pod securityContext renders (runAsNonRoot is set), so the absence check
// below is not vacuous: a seccompProfile rendered unconditionally fails it.
_testCronJobNoSeccompComponent: {
	#instance: {name: "batch", namespace: "jobs", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#SecurityContext
	tr.#CronJobConfig

	metadata: {
		name: "sync"
		labels: "core.opmodel.dev/workload-type": "scheduled-task"
	}

	spec: {
		container: _testCronJobContainer
		securityContext: runAsNonRoot: true
		cronJobConfig: scheduleCron:   "0 * * * *"
	}
}

_testCronJobNoSeccompTransformer: (#CronJobTransformer.#transform & {
	#moduleInstance: _testCronJobModuleInstance
	#component:      _testCronJobNoSeccompComponent
	#context:        _testCronJobContext
}).output

_testCronJobNoSeccompPodRunAsNonRoot: [
	if _testCronJobNoSeccompTransformer.spec.jobTemplate.spec.template.spec.securityContext.runAsNonRoot != _|_ {"rendered"},
] & ["rendered"]

_testCronJobNoSeccompPodProfileAbsent: [
	if _testCronJobNoSeccompTransformer.spec.jobTemplate.spec.template.spec.securityContext.seccompProfile != _|_ {"leaked"},
] & []
