package transformers

/////////////////////////////////////////////////////////////////
//// Workload naming
////
//// Every workload transformer renders `{instance}-{component}` unless the
//// component opts into an exact name via #ResourceNameTrait. Centralised here
//// for one reason above all: the HPA and PDB transformers must target the
//// workload by a name that is byte-identical to the one the Deployment /
//// StatefulSet / DaemonSet transformer emitted. Two copies of this expression
//// would be two chances to drift, and the failure — an autoscaler pointed at a
//// workload that does not exist — is silent.
/////////////////////////////////////////////////////////////////

// #WorkloadName resolves a workload's rendered object name: the exact name from
// #ResourceNameTrait when set, otherwise the instance-scoped default.
//
// Usage:
//   (#WorkloadName & {
//       #comp:     #component
//       #instance: #context.#moduleInstanceMetadata.name
//   }).out
//
// The list-index form is load-bearing. The obvious spelling,
// `#comp.spec.resourceName | *"\(#instance)-\(...)"`, reads as "the
// override, defaulting to the prefixed name" and means the opposite: in CUE a
// default arm wins over a concrete one, so the override would be silently
// discarded. Same trap that put cert-manager's webhook Service on the wrong
// port (see service_transformer.cue).
#WorkloadName: {
	#comp!:     _
	#instance!: string

	out: [
		if #comp.spec.resourceName != _|_ {#comp.spec.resourceName},
		"\(#instance)-\(#comp.metadata.name)",
	][0]
}
