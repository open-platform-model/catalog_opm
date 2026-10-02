package kinds

// WHY: #Table is generated (tools/kindgen) but committed, so a hand edit
// could file a definition under another kind's key, and the objects
// resource would validate that kind against the wrong schema. This
// assertion makes `cue vet` refuse such a table: every entry's schema
// carries its own keys as its concrete apiVersion and kind, and every
// scope is one of the two the objects resource reads.
_tableEntriesConform: {
	for av, kinds in #Table for k, e in kinds {
		"\(av) \(k)": e & {
			schema?: {apiVersion: av, kind: k, ...}
			scope?: "Namespaced" | "Cluster"
		}
	}
}
