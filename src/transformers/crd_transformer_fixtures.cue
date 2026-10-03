@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
////
//// Golden mirrors a vendored cert-manager CRD: the fields an upstream
//// manifest actually carries, including listKind and the issuerRef
//// selectableFields (a field selector on an undeclared field is
//// rejected by the API server, so dropping them is a behaviour change).
/////////////////////////////////////////////////////////////////

_testCRDComponent: {
	res.#CRDs

	metadata: {
		name: "crds"
		labels: "core.opmodel.dev/workload-type": "stateless"
	}

	spec: crds: "orders.acme.cert-manager.io": {
		// A protected-group CRD would be REJECTED by the API server without
		// api-approved.kubernetes.io; this mirrors what an upstream Gateway API
		// manifest carries.
		annotations: {
			"api-approved.kubernetes.io":               "https://github.com/kubernetes-sigs/gateway-api/pull/4530"
			"gateway.networking.k8s.io/bundle-version": "v1.5.1"
		}
		group: "acme.cert-manager.io"
		names: {
			kind:     "Order"
			listKind: "OrderList"
			plural:   "orders"
			singular: "order"
			categories: ["cert-manager", "cert-manager-acme"]
		}
		scope: "Namespaced"
		versions: [{
			name:    "v1"
			served:  true
			storage: true
			schema: openAPIV3Schema: type: "object"
			subresources: status: {}
			selectableFields: [
				{jsonPath: ".spec.issuerRef.group"},
				{jsonPath: ".spec.issuerRef.kind"},
				{jsonPath: ".spec.issuerRef.name"},
			]
		}]
	}
}

_testCRDTransformer: (#CRDTransformer.#transform & {
	#component: _testCRDComponent
	#moduleInstance: {
		metadata: {
			name:      "cert-manager"
			namespace: "cert-manager"
			fqn:       "opmodel.dev/modules/cert-manager@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

_testCRDTransformer: [{
	apiVersion: "apiextensions.k8s.io/v1"
	kind:       "CustomResourceDefinition"
	metadata: name: "orders.acme.cert-manager.io"
	spec: {
		group: "acme.cert-manager.io"
		names: {
			kind:     "Order"
			plural:   "orders"
			singular: "order"
		}
		scope: "Namespaced"
	}
}]

// Presence guards for the two fields this change adds, kept OUT of the golden
// above on purpose: unification ADDS a field the output is missing rather than
// rejecting it, so a golden naming listKind would silently repair a
// transformer that dropped it.
//
// The comprehension form is what makes absence fail: an unset optional field
// is merely incomplete, so `"\(…listKind)" & "OrderList"` passes plain
// `cue vet` (only -c would catch it), whereas an empty list against a
// one-element list is a hard length conflict at every vet level.
_testCRDListKindPresent: [
	if _testCRDTransformer[0].spec.names.listKind != _|_ {_testCRDTransformer[0].spec.names.listKind},
] & ["OrderList"]

_testCRDSelectableFieldsPresent: [
	if _testCRDTransformer[0].spec.versions[0].selectableFields != _|_ {
		len(_testCRDTransformer[0].spec.versions[0].selectableFields)
	},
] & [3]

// Same presence idiom for the CRD's own annotations. Interpolating the value
// (rather than naming it in the golden) forces resolution, so a transformer
// that dropped the key cannot have it handed back by unification.
_testCRDAnnotationsPresent: [
	if _testCRDTransformer[0].metadata.annotations != _|_ {
		"\(_testCRDTransformer[0].metadata.annotations["api-approved.kubernetes.io"])"
	},
] & ["https://github.com/kubernetes-sigs/gateway-api/pull/4530"]

_testCRDAnnotationCount: [
	if _testCRDTransformer[0].metadata.annotations != _|_ {
		len(_testCRDTransformer[0].metadata.annotations)
	},
] & [2]

/////////////////////////////////////////////////////////////////
//// Absence case
////
//// A CRD carrying no annotations, with no componentAnnotations either, must
//// emit NO annotations key at all — an empty map would still be a diff against
//// the vendored source on every server-side apply.
/////////////////////////////////////////////////////////////////

_testCRDBareComponent: {
	res.#CRDs

	metadata: name: "crds"

	spec: crds: "widgets.example.com": {
		group: "example.com"
		names: {
			kind:   "Widget"
			plural: "widgets"
		}
		scope: "Cluster"
		versions: [{
			name:    "v1"
			served:  true
			storage: true
		}]
	}
}

_testCRDBareTransformer: (#CRDTransformer.#transform & {
	#component: _testCRDBareComponent
	#moduleInstance: {
		metadata: {
			name:      "example"
			namespace: "default"
			fqn:       "opmodel.dev/modules/example@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

_testCRDNoAnnotationLeak: [
	if _testCRDBareTransformer[0].metadata.annotations != _|_ {"leaked"},
] & []
