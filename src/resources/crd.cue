package resources

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
)

/////////////////////////////////////////////////////////////////
//// CRDs Resource
/////////////////////////////////////////////////////////////////

#CRDsResource: c.#Resource & {
	metadata: {
		modulePath:  "\(id.ModulePath)/resources"
		version:     id.Version
		name:        "crds"
		description: "One or more CustomResourceDefinitions to deploy to the cluster"
		labels: {
			"resource.opmodel.dev/category": "extension"
		}
	}

	spec: crds: [name=string]: #CRDSchema
}

#CRDs: c.#Component & {
	#resources: (#CRDsResource.metadata.fqn): #CRDsResource
}

/////////////////////////////////////////////////////////////////
//// CRD Schemas
/////////////////////////////////////////////////////////////////

// A single version entry in a CRD.
#CRDVersionSchema: {
	name!:    string
	served!:  bool
	storage!: bool
	schema?: {
		openAPIV3Schema: {...}
	}
	subresources?: {...}
	additionalPrinterColumns?: [...{...}]

	// Fields the API server accepts in a `--field-selector` for this version.
	// Vendored operator CRDs increasingly declare these (cert-manager scopes
	// every issuerRef field), and a field selector on an undeclared field is
	// rejected — so dropping them changes cluster behaviour, not just fidelity.
	selectableFields?: [...{jsonPath!: string}]

	// Marks the version deprecated; deprecationWarning overrides the default
	// warning the API server returns to clients using it.
	deprecated?:         bool
	deprecationWarning?: string
}

// Kubernetes CustomResourceDefinition. Vendor operator CRDs alongside your module.
#CRDSchema: {
	group!: string
	names!: {
		kind!:   string
		plural!: string
		// Kind of the list type. The API server defaults it to "<kind>List",
		// which is what upstream CRDs nearly always spell out — set it only to
		// keep a vendored CRD byte-identical to its source manifest.
		listKind?: string
		singular?: string
		shortNames?: [...string]
		categories?: [...string]
	}
	scope!: "Namespaced" | "Cluster"
	versions!: [_, ...] & [...#CRDVersionSchema]
}

#CRDDefaults: #CRDSchema & {
	scope: "Namespaced"
}
