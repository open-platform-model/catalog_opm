package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
)

// AdmissionPolicyTransformer converts ValidatingAdmissionPolicies resources to
// Kubernetes ValidatingAdmissionPolicy + ValidatingAdmissionPolicyBinding pairs.
//
// Two objects per entry, emitted together so the binding's `policyName` is
// always the policy that was actually rendered. Names are exact — both objects
// are cluster-scoped and the binding references the policy by name.
#AdmissionPolicyTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "admission-policy-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/admission-policy-transformer@\(id.Version)"
		description:    "Converts ValidatingAdmissionPolicies resources to CEL admission policies and their bindings"

		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "validatingadmissionpolicy"
		}
	}

	requiredLabels: {}

	requiredResources: {
		(res.#ValidatingAdmissionPoliciesResource.metadata.fqn): res.#ValidatingAdmissionPoliciesResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["ValidatingAdmissionPolicy", "ValidatingAdmissionPolicyBinding"]

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		output: [
			for _, p in #component.spec.validatingAdmissionPolicies
			let _userLabels = [if p.labels != _|_ {p.labels}, {}][0]
			let _labels = {
				for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
				for k, v in _userLabels {(k): v}
			}
			for _obj in [
				{
					apiVersion: p.apiVersion
					kind:       "ValidatingAdmissionPolicy"
					metadata: {
						name:   p.name // exact — bindings reference the policy by name
						labels: _labels
						if p.annotations != _|_ {
							annotations: p.annotations
						}
					}
					spec: {
						if p.failurePolicy != _|_ {
							failurePolicy: p.failurePolicy
						}
						matchConstraints: p.matchConstraints
						if p.variables != _|_ {
							variables: p.variables
						}
						validations: p.validations
					}
				},
				{
					apiVersion: p.apiVersion
					kind:       "ValidatingAdmissionPolicyBinding"
					metadata: {
						name:   p.binding.name // exact — authored binding identity
						labels: _labels
						if p.annotations != _|_ {
							annotations: p.annotations
						}
					}
					spec: {
						// Always the policy rendered directly above, so the two
						// cannot drift apart.
						policyName:        p.name
						validationActions: p.binding.validationActions
						if p.binding.matchResources != _|_ {
							matchResources: p.binding.matchResources
						}
					}
				},
			] {_obj},
		]
	}
}
