package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	k8sapiextv1 "opmodel.dev/catalogs/opm/schemas/kubernetes/apiextensions/v1"
)

// CRDTransformer converts CRDs resources to Kubernetes CustomResourceDefinitions
#CRDTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "crd-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/crd-transformer@\(id.Version)"
		description:    "Converts CRDs resources to Kubernetes CustomResourceDefinitions"

		labels: {
			"core.opmodel.dev/resource-category": "extension"
			"core.opmodel.dev/resource-type":     "crd"
		}
	}

	requiredLabels: {}

	// Required resources - CRDs MUST be present
	requiredResources: {
		(res.#CRDsResource.metadata.fqn): res.#CRDsResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_crds: #component.spec.crds

		// Emit one K8s CustomResourceDefinition per entry in the component's
		// crds map. Output is a list of resources; the renderer dispatches
		// on cue.Kind and produces one Compiled per list element.
		output: [
			for crdName, crd in _crds {
				// Plain unification, so a key set on both sides with different
				// values is a hard error rather than a silent win for either.
				let _annotations = {
					if len(#context.componentAnnotations) > 0 {#context.componentAnnotations}
					if crd.annotations != _|_ {crd.annotations}
				}

				k8sapiextv1.#CustomResourceDefinition & {
					apiVersion: "apiextensions.k8s.io/v1"
					kind:       "CustomResourceDefinition"
					metadata: {
						name:   crdName // exact — <plural>.<group> is the CRD identity
						labels: #context.labels
						if len(_annotations) > 0 {
							annotations: _annotations
						}
					}
					spec: {
						group: crd.group
						names: {
							kind:   crd.names.kind
							plural: crd.names.plural
							if crd.names.listKind != _|_ {
								listKind: crd.names.listKind
							}
							if crd.names.singular != _|_ {
								singular: crd.names.singular
							}
							if crd.names.shortNames != _|_ {
								shortNames: crd.names.shortNames
							}
							if crd.names.categories != _|_ {
								categories: crd.names.categories
							}
						}
						scope:    crd.scope
						versions: crd.versions
					}
				}
			},
		]
	}
}
