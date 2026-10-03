@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testHPAModuleInstance: {
	metadata: {
		name:      "istio"
		namespace: "istio-system"
		fqn:       "opmodel.dev/modules/istio@0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "0.1.0"
}

_testHPAContext: #runtimeName: "opm-test"

_testHPAContainer: {
	name: "discovery"
	image: {
		repository: "docker.io/istio/pilot"
		tag:        "1.30.3-distroless"
		digest:     ""
	}
}

// ---- No `auto`: the transformer MUST emit nothing -----------------------
// This is the load-bearing test. #StatelessWorkload composes #ScalingTrait, so
// this transformer matches every stateless workload in every module —
// cert-manager, jellyfin, all of them. If it emitted an HPA whenever it
// matched, every one of them would grow a spurious autoscaler.
_testHPACountOnlyComponent: {
	#instance: {name: "istio", namespace: "istio-system", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#Scaling

	metadata: {
		name: "istiod"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: _testHPAContainer
		scaling: count: 3
	}
}

_testHPACountOnlyTransformer: (#HPATransformer.#transform & {
	#moduleInstance: _testHPAModuleInstance
	#component:      _testHPACountOnlyComponent
	#context:        _testHPAContext
}).output

_testHPAEmitsNothing: (len(_testHPACountOnlyTransformer) + 0) & 0

// ...and the Deployment keeps its explicit replica count in that case.
_testHPADeployKeepsReplicas: [
	if (#DeploymentTransformer.#transform & {
		#moduleInstance: _testHPAModuleInstance
		#component:      _testHPACountOnlyComponent
		#context:        _testHPAContext
	}).output.spec.replicas != _|_ {
		(#DeploymentTransformer.#transform & {
			#moduleInstance: _testHPAModuleInstance
			#component:      _testHPACountOnlyComponent
			#context:        _testHPAContext
		}).output.spec.replicas
	},
] & [3]

// ---- With `auto`: one HPA, targeting the workload's exact name -------------
_testHPAAutoComponent: {
	#instance: {name: "istio", namespace: "istio-system", uuid: "00000000-0000-0000-0000-000000000000"}

	res.#Container
	tr.#Scaling

	metadata: {
		name:         "istiod"
		resourceName: "istiod"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: _testHPAContainer
		scaling: {
			count: 1
			auto: {
				min: 1
				max: 5
				metrics: [{
					type: "cpu"
					target: averageUtilization: 80
				}]
			}
		}
	}
}

_testHPAAutoTransformer: (#HPATransformer.#transform & {
	#moduleInstance: _testHPAModuleInstance
	#component:      _testHPAAutoComponent
	#context:        _testHPAContext
}).output

_testHPAEmitsOne: (len(_testHPAAutoTransformer) + 0) & 1

// Presence guard first (catches a dropped field, which arithmetic alone
// cannot), then the value guard (catches a wrong one, non-invertibly).
_testHPAMinPresent: [
	if _testHPAAutoTransformer[0].spec.minReplicas != _|_ {"present"},
] & ["present"]

_testHPAMin: (_testHPAAutoTransformer[0].spec.minReplicas + 0) & 1
_testHPAMax: (_testHPAAutoTransformer[0].spec.maxReplicas + 0) & 5

_testHPAMetricsPresent: (len(_testHPAAutoTransformer[0].spec.metrics) + 0) & 1

_testHPAMetricType:  "\(_testHPAAutoTransformer[0].spec.metrics[0].type)" & "Resource"
_testHPAMetricName:  "\(_testHPAAutoTransformer[0].spec.metrics[0].resource.name)" & "cpu"
_testHPATargetType:  "\(_testHPAAutoTransformer[0].spec.metrics[0].resource.target.type)" & "Utilization"
_testHPATargetValue: (_testHPAAutoTransformer[0].spec.metrics[0].resource.target.averageUtilization + 0) & 80

_testHPAScaleKind: "\(_testHPAAutoTransformer[0].spec.scaleTargetRef.kind)" & "Deployment"

// Cross-transformer consistency: the HPA's target name must equal the name the
// Deployment transformer actually rendered for the SAME component. One
// expression, so the two can never drift apart silently.
_testHPATargetMatchesDeployment: "\(_testHPAAutoTransformer[0].spec.scaleTargetRef.name)" &
	"\((#DeploymentTransformer.#transform & {
		#moduleInstance: _testHPAModuleInstance
		#component:      _testHPAAutoComponent
		#context:        _testHPAContext
	}).output.metadata.name)"

// ...and the Deployment must NOT emit replicas when the HPA owns them.
// Absent-field territory: a golden cannot express this.
_testHPADeployOmitsReplicas: [
	if (#DeploymentTransformer.#transform & {
		#moduleInstance: _testHPAModuleInstance
		#component:      _testHPAAutoComponent
		#context:        _testHPAContext
	}).output.spec.replicas != _|_ {"leaked"},
] & []

// Default naming: no metadata.resourceName, so the target is the component's
// instance-scoped resourceName, the same name the Deployment renders.
_testHPADefaultNameComponent: {
	res.#Container
	tr.#Scaling

	#instance: {name: "istio", namespace: "istio-system", uuid: "00000000-0000-0000-0000-000000000000"}

	metadata: {
		name: "istiod"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: {
		container: _testHPAContainer
		scaling: {
			count: 1
			auto: {
				min: 1
				max: 5
				metrics: [{
					type: "cpu"
					target: averageUtilization: 80
				}]
			}
		}
	}
}

_testHPADefaultNameTransformer: (#HPATransformer.#transform & {
	#moduleInstance: _testHPAModuleInstance
	#component:      _testHPADefaultNameComponent
	#context:        _testHPAContext
}).output

_testHPADefaultNameResolves:   "\(_testHPADefaultNameTransformer[0].metadata.name)" & "istio-istiod"
_testHPADefaultTargetResolves: "\(_testHPADefaultNameTransformer[0].spec.scaleTargetRef.name)" & "istio-istiod"
