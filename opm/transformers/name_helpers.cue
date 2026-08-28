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
