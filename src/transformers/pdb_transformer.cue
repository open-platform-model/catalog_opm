package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	k8spolicyv1 "opmodel.dev/catalogs/opm/schemas/kubernetes/policy/v1"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	tr "opmodel.dev/catalogs/opm/traits/v1beta1"
)

// WHY: Like #ScalingTrait's `auto` block, #DisruptionBudgetSchema has existed since
// the catalog was written with nothing emitting it.
//
// Unlike the HPA this requires its own trait, so it only matches components that
// actually asked for a budget — no conditional-emission guard is needed. The
// trait is not composed by any blueprint, so it must be attached explicitly.
//
// The selector deliberately uses #context.componentLabels — the same value the
// workload transformers put in `spec.selector.matchLabels` — so the budget
// always covers exactly the workload's pods.

// PDBTransformer realizes #DisruptionBudgetTrait as a PodDisruptionBudget.
#PDBTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "pdb-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/pdb-transformer@\(id.Version)"
		description:    "Converts a workload's disruption budget to a Kubernetes PodDisruptionBudget"

		labels: {
			"core.opmodel.dev/resource-type": "poddisruptionbudget"
		}
	}

	requiredResources: {
		(res.#ContainerResource.metadata.fqn): res.#ContainerResource
	}

	requiredTraits: {
		(tr.#DisruptionBudgetTrait.metadata.fqn): tr.#DisruptionBudgetTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		_budget: #component.spec.disruptionBudget

		output: k8spolicyv1.#PodDisruptionBudget & {
			apiVersion: "policy/v1"
			kind:       "PodDisruptionBudget"
			metadata: {
				name:      #component.#names.resourceName
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				// #DisruptionBudgetSchema is a disjunction, so exactly one of
				// these is ever present.
				if _budget.minAvailable != _|_ {
					minAvailable: _budget.minAvailable
				}
				if _budget.maxUnavailable != _|_ {
					maxUnavailable: _budget.maxUnavailable
				}
				selector: matchLabels: #context.componentLabels
			}
		}
	}
}
