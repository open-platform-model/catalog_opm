package v1alpha1

import (
	"strings"

	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	kinds "opmodel.dev/catalogs/opm/schemas/kinds"
)

/////////////////////////////////////////////////////////////////
//// Objects Resource
/////////////////////////////////////////////////////////////////

// Kubernetes objects rendered as written, one output object per map entry.
// A built-in kind validates against its closed Kubernetes 1.36 definition,
// with no per-object opt-out; any other kind passes open and states #scope.
// Names are never prefixed: two instances of one module in one namespace
// collide unless each name carries the instance name.
// See docs/name-constraints.md.
#ObjectsResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1alpha1"
		name:           "objects"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/objects@v1alpha1"
		description:    "Kubernetes objects rendered as written, one output object per map entry"
		labels: {
			"resource.opmodel.dev/category": "extension"
		}
	}

	// WHY the alias is `Key`, never `name`: the inner field would shadow it
	// and the default would refer to itself (see namespace.cue).

	// Keyed by object name: metadata.name defaults to the key.
	spec: objects: [Key=string]: #ObjectSchema & {metadata: name: string | *Key}
}

#Objects: c.#Component & {
	#resources: (#ObjectsResource.metadata.fqn): #ObjectsResource
}

/////////////////////////////////////////////////////////////////
//// Object Schema
/////////////////////////////////////////////////////////////////

// WHY the dispatch is a list index (docs/name-constraints.md): it picks the
// first arm whose guard holds with no default arm to win over it. Every
// error() sits behind a guard that holds only once apiVersion and kind are
// concrete (`x != _|_` is false for a non-concrete x), so the bare
// definition, which a platform build evaluates with no component, never
// fires one (measured, change add-objects-resource, section 1). The
// namespace refusal is an optional field holding the error, not a test of
// `X.metadata.namespace != _|_`: that test made every valid cluster-scoped
// built-in object read as bottom to a `!= _|_` check (measured, cue v0.17.1).
// Embedding a closed schema into a struct that has `...` reopens it, at the
// top level and in metadata alike, so `...` appears only in the open arms.

// One Kubernetes object, written as the API server takes it.
// A built-in kind (kinds.#Table) is closed by its cue.dev/x/k8s.io schema and
// takes its scope from the table; an unknown kind of a built-in API group is
// refused. Any other kind is open and must set #scope, which is never rendered.
// metadata.namespace defaults to the instance namespace on a Namespaced
// object and is refused on a Cluster one; labels merge over the context's.
#ObjectSchema: X={
	apiVersion!: string
	kind!:       string
	metadata: {
		name:       string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
	}
	#scope?: "Namespaced" | "Cluster"

	let group = [if strings.Contains(X.apiVersion, "/") {strings.Split(X.apiVersion, "/")[0]}, ""][0]
	let unscoped = "\(X.apiVersion) \(X.kind) is not a Kubernetes 1.36 object kind: set #scope to \"Namespaced\" or \"Cluster\""
	let namespaced = "\(X.apiVersion) \(X.kind) is cluster-scoped: remove metadata.namespace"
	[
		if kinds.#Table[X.apiVersion][X.kind] != _|_ {
			let E = kinds.#Table[X.apiVersion][X.kind]
			[if E.schema != _|_ {E.schema}, {metadata: {...}, ...}][0]
			if E.scope != _|_ {
				#scope: E.scope
				if E.scope == "Cluster" {metadata: namespace?: error(namespaced)}
			}
			if E.scope == _|_ {
				if X.#scope == _|_ {error(unscoped)}
				if X.#scope != _|_ if X.#scope == "Cluster" {metadata: namespace?: error(namespaced)}
			}
		},
		if _builtinGroups[group] != _|_ if X.kind != _|_ {
			error("\(X.apiVersion) \(X.kind) is not a Kubernetes 1.36 kind, and its API group is built in: check apiVersion and kind")
		},
		{
			metadata: {...}
			...
			if X.apiVersion != _|_ if X.kind != _|_ {
				if X.#scope == _|_ {error(unscoped)}
				if X.#scope != _|_ if X.#scope == "Cluster" {metadata: namespace?: error(namespaced)}
			}
		},
	][0]
}

// Every API group the kind table names ("" for the core group, "v1"). An
// apiVersion in one of these groups must name a kind the table holds.
_builtinGroups: {
	for av, _ in kinds.#Table {
		([if strings.Contains(av, "/") {strings.Split(av, "/")[0]}, ""][0]): true
	}
}
