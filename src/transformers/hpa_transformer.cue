package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	k8sautoscalingv2 "opmodel.dev/catalogs/opm/schemas/kubernetes/autoscaling/v2"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

// WHY: The schema (#AutoscalingSpec: min/max/metrics/behavior) has existed since the
// catalog was written and was only ever read as a replica count by the
// Deployment and StatefulSet transformers. This emits the object it always
// described.
//
// Matching is deliberately broad — Container + Scaling, which is every stateless
// and stateful workload in every module (both blueprints compose #ScalingTrait,
// daemon/task/scheduled-task do not). Emitting nothing unless `auto` is set is
// therefore not an optimisation, it is the correctness condition: `output` is a
// list with a comprehension guard, and an empty list yields zero resources.

// HPATransformer realizes #ScalingTrait's `auto` block as a HorizontalPodAutoscaler.
#HPATransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "hpa-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/hpa-transformer@\(id.Version)"
		description:    "Converts a workload's autoscaling spec to a Kubernetes HorizontalPodAutoscaler"

		labels: {
			"core.opmodel.dev/resource-type": "horizontalpodautoscaler"
		}
	}

	// No requiredLabels: this matches both stateless and stateful workloads,
	// which carry different workload-type labels.
	requiredResources: {
		(res.#ContainerResource.metadata.fqn): res.#ContainerResource
	}

	requiredTraits: {
		(tr.#ScalingTrait.metadata.fqn): tr.#ScalingTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		// The scaled object's kind follows the workload type. Read from the
		// component rather than #context.componentLabels so it does not depend
		// on which labels the context happens to project.
		_workloadType: #component.metadata.labels["core.opmodel.dev/workload-type"]

		_kind: [
			if _workloadType == "stateful" {"StatefulSet"},
			"Deployment",
		][0]

		// MUST be byte-identical to the name the Deployment/StatefulSet
		// transformer rendered, or the HPA silently targets nothing.
		_targetName: #component.#names.resourceName

		output: [
			if #component.spec.scaling != _|_ if #component.spec.scaling.auto != _|_ {
				let _auto = #component.spec.scaling.auto

				k8sautoscalingv2.#HorizontalPodAutoscaler & {
					apiVersion: "autoscaling/v2"
					kind:       "HorizontalPodAutoscaler"
					metadata: {
						name:      _targetName
						namespace: #context.#moduleInstanceMetadata.namespace
						labels:    #context.labels
						if len(#context.componentAnnotations) > 0 {
							annotations: #context.componentAnnotations
						}
					}
					spec: {
						scaleTargetRef: {
							apiVersion: "apps/v1"
							kind:       _kind
							name:       _targetName
						}
						minReplicas: _auto.min
						maxReplicas: _auto.max

						metrics: [for _m in _auto.metrics {
							// "cpu"/"memory" are the two built-in per-pod
							// resource metrics; anything else is a custom
							// per-pod metric addressed by name.
							if _m.type != "custom" {
								type: "Resource"
								resource: {
									name: _m.type
									target: (#ToK8sMetricTarget & {#target: _m.target}).out
								}
							}
							if _m.type == "custom" {
								type: "Pods"
								pods: {
									metric: name: _m.metricName
									target: (#ToK8sMetricTarget & {#target: _m.target}).out
								}
							}
						}]

						if _auto.behavior != _|_ {
							behavior: {
								if _auto.behavior.scaleUp != _|_ {
									scaleUp: _auto.behavior.scaleUp
								}
								if _auto.behavior.scaleDown != _|_ {
									scaleDown: _auto.behavior.scaleDown
								}
							}
						}
					}
				}
			},
		]
	}
}

// #ToK8sMetricTarget maps OPM's #MetricTargetSpec to a Kubernetes MetricTarget.
// The K8s `type` discriminator is implied by which field the author set, so it
// is derived rather than asked for twice.
#ToK8sMetricTarget: {
	#target!: tr.#MetricTargetSpec

	out: {
		if #target.averageUtilization != _|_ {
			type:               "Utilization"
			averageUtilization: #target.averageUtilization
		}
		if #target.averageUtilization == _|_ if #target.averageValue != _|_ {
			type:         "AverageValue"
			averageValue: #target.averageValue
		}
	}
}
