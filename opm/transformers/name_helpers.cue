package transformers

/////////////////////////////////////////////////////////////////
//// Workload naming
////
//// Core computes every component's rendered name once
//// (`metadata.resourceName`, surfaced as `#names.resourceName`), and a
//// transformer reads it, never derives it (enhancement 0019 D15). During the
//// #ResourceNameTrait deprecation window two authorities coexist: the trait's
//// exact name and the core field. This helper is the single seam that orders
//// them, so the HPA and PDB transformers target the workload by a name that
//// is byte-identical to the one the Deployment / StatefulSet / DaemonSet
//// transformer emitted. Two copies would be two chances to drift, and the
//// failure (an autoscaler pointed at a workload that does not exist) is
//// silent. When the trait is deleted the helper collapses to a direct read.
/////////////////////////////////////////////////////////////////

// WHY: Usage: (#WorkloadName & {#comp: #component}).out
//
// The list-index form is load-bearing. The obvious spelling,
// `#comp.spec.resourceName | *#comp.#names.resourceName`, reads as "the
// override, defaulting to the core name" and means the opposite: in CUE a
// default arm wins over a concrete one, so the override would be silently
// discarded. Same trap that put cert-manager's webhook Service on the wrong
// port (see service_transformer.cue). `#names` is only concrete once
// `#instance` is set, which #Module does at render and fixtures do by hand.

// #WorkloadName resolves a workload's rendered object name during the
// #ResourceNameTrait deprecation window: the trait's exact name when set,
// otherwise the component's own #names.resourceName (0019 D15).
// See docs/name-constraints.md.
#WorkloadName: {
	#comp!: _

	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		#comp.#names.resourceName,
	][0]
}

/////////////////////////////////////////////////////////////////
//// Service naming
/////////////////////////////////////////////////////////////////

// WHY: Usage: (#ServiceName & {#comp: #component}).out
//
// Six readers name the Service: the Service transformer itself, the
// StatefulSet's serviceName and the four route transformers' backendRefs.
// The last five are cross-object references (0019 D22, carve-out 3) and must
// be byte-identical to what the Service transformer emits, or a headless
// Service or backend is silently pointed at nothing. The fallback arm is what
// keeps a component compiled against a build <= alpha.5 (expose.name?:
// string, unset) rendering (0010 D27); alpha.6 dropped it from every reader.
// List-index form for the same reason as #WorkloadName.

// #ServiceName resolves the name of the Service an Expose component renders:
// expose.name when the component set or defaulted it (every build >= alpha.6
// attaches through the #Expose wrapper), otherwise the component's own
// #names.dns.short, the value that wrapper defaults to.
// See docs/name-constraints.md.
#ServiceName: {
	#comp!: _

	out: [
		if #comp.spec.expose.name != _|_ {#comp.spec.expose.name},
		#comp.#names.dns.short,
	][0]
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Legacy shape: a component compiled against a build <= alpha.5, whose
// #ExposeSchema carried `name?: string` and whose wrapper set no default.
// Hand-built on purpose (embedding the current trait gives `name!`); #names
// is set as core would derive it.
_testServiceNameLegacy: (#ServiceName & {
	#comp: {
		#names: dns: short: "shop-web"
		spec: expose: {
			type: "ClusterIP"
			ports: http: {name: "http", targetPort: 8080, protocol: "TCP"}
			name?: string
		}
	}
}).out

_testServiceNameLegacyResolves: "\(_testServiceNameLegacy)" & "shop-web"

// Exact name wins over the component's own name.
_testServiceNameExact: (#ServiceName & {
	#comp: {
		#names: dns: short: "istio-istiod"
		spec: expose: {
			name: "istiod"
			type: "ClusterIP"
			ports: "https-dns": {name: "https-dns", targetPort: 15012, protocol: "TCP"}
		}
	}
}).out

_testServiceNameExactResolves: "\(_testServiceNameExact)" & "istiod"
