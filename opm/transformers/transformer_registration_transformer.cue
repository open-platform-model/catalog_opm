package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
	tra "opmodel.dev/catalogs/opm/traits/v1alpha1"
)

// WHY the group, version and kind below are literals: they name a CRD that
// opm-operator owns (enhancement 0015 D3), so nothing in this catalog can
// derive them. The operator's TransformerRegistration CRD must match these
// three strings exactly — this file and that CRD are the two sides of one
// contract, and changing either alone breaks the other.
// WHY the group is the bare `opmodel.dev`, with no `opm.` or kind-specific
// prefix: enhancement 0002 D5 chose one flat group for every OPM CRD and
// rejected prefixed and per-kind groups, paying a full cluster migration for
// it. A prefixed group here would name a CRD no cluster installs, so the
// rendered claim could never be applied (measured: `opm` 4.3.0 shipped a
// dot-prefixed group here and was unappliable).

// TransformerRegistrationTransformer renders a provider module's claim as the
// cluster-scoped TransformerRegistration the operator accepts. The object's
// name and spec.providerRef come from the rendering instance alone, so a
// module cannot claim to be another provider (0015 D11, D12).
#TransformerRegistrationTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "transformer-registration-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/transformer-registration-transformer@\(id.Version)"
		description:    "Renders a provider module's contract claim as a cluster-scoped TransformerRegistration"

		labels: {
			"core.opmodel.dev/resource-category": "cluster"
			"core.opmodel.dev/resource-type":     "transformerregistration"
		}
	}

	requiredLabels: {}

	// The contract FQN alone selects this transformer; the resource declares
	// no matchLabels, so there is no label vocabulary to require.
	requiredResources: {
		(res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	}

	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	producesKinds: ["TransformerRegistration"]

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		_i: #context.#moduleInstanceMetadata
		_r: #component.spec.transformerRegistration

		// One claim per component carrying the contract, so output is a
		// struct (core's StructKind arm), never a list.
		output: {
			apiVersion: "opmodel.dev/v1alpha1"
			kind:       "TransformerRegistration"
			metadata: {
				// Cluster-scoped, dot-joined (0015 D12): a namespace cannot
				// contain a dot, so two instances of one provider module
				// produce two claims and the second is refused at acceptance
				// naming the claimant, rather than fighting over one object.
				name:   "\(_i.namespace).\(_i.name)"
				labels: #context.labels
			}
			spec: {
				catalog:  _r.catalog
				version:  _r.version
				provides: _r.provides

				// Stamped from the rendering instance, never authored: the
				// provider IS the instance that rendered the claim (0015 D11).
				providerRef: {name: _i.name, namespace: _i.namespace}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testTransformerRegistrationComponent: res.#TransformerRegistration & {
	metadata: name: "k8up"
	spec: transformerRegistration: {
		catalog: "opmodel.dev/catalogs/k8up@v1"
		version: "1.0.0"
		provides: ["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]
	}
}

// WHY this fixture supplies #moduleInstance and not
// #context.#moduleInstanceMetadata: since 0019 D12 that field is a PROJECTION
// computed at the #transform site, so filling it directly leaves
// #moduleInstance at `_` and the output never becomes concrete. `cue vet`
// stays green either way (the failure is incomplete-class), which is why the
// check that matters is `cue export`. See CLAUDE.md § Working Style.
_testTransformerRegistrationOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: {
		metadata: {
			name:      "k8up"
			namespace: "backup-system"
			fqn:       "opmodel.dev/modules/k8up@1.0.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "1.0.0"
	}
	#component: _testTransformerRegistrationComponent
	#context: #runtimeName: "opm-test"
}).output

// Golden fixture — cue vet fails on any drift, not just schema errors.
_testTransformerRegistrationOutput: {
	apiVersion: "opmodel.dev/v1alpha1"
	kind:       "TransformerRegistration"
	metadata: {
		name: "backup-system.k8up"
		labels: {
			"app.kubernetes.io/managed-by":     "opm-test"
			"app.kubernetes.io/name":           "k8up"
			"app.kubernetes.io/instance":       "k8up"
			"module-instance.opmodel.dev/name": "k8up"
		}
	}
	spec: {
		catalog: "opmodel.dev/catalogs/k8up@v1"
		version: "1.0.0"
		provides: ["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]
		providerRef: {name: "k8up", namespace: "backup-system"}
	}
}

// The rendered object carries exactly the four keys the context fold produces;
// a fifth would slip past the golden struct above, which unifies openly.
_testTransformerRegistrationLabelCount: (len(_testTransformerRegistrationOutput.metadata.labels) + 0) & 4

/////////////////////////////////////////////////////////////////
//// Test Data — #PreBoundRegistration
/////////////////////////////////////////////////////////////////

// WHY these fixtures build their own transformers: this catalog ships no
// transformer requiring a provider-fulfilled contract (a provider-fulfilled
// member ships none here, and never a stub), so the fold over opm's own
// #transformers is empty by rule and proves nothing. Each fixture supplies
// the map a real provider catalog would pass, and its golden asserts
// spec.provides alone — the rest of the object is pinned above.

_testPreBoundInstance: {
	metadata: {
		name:      "provider"
		namespace: "provider-system"
		fqn:       "opmodel.dev/modules/provider@1.0.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#moduleMetadata: version: "1.0.0"
}

_testPreBoundIdentity: {
	modulePath: "opmodel.dev/catalogs/k8up@v1"
	version:    "1.0.0"
}

// A required trait with fulfilment "provider" yields exactly its FQN.
_testPreBoundTraitComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: backup: requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
}

_testPreBoundTraitOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundTraitComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundTraitOutput: spec: {
	catalog: "opmodel.dev/catalogs/k8up@v1"
	version: "1.0.0"
	provides: ["opmodel.dev/catalogs/opm/traits/backup@v1alpha1"]
}

// requiredResources alone is enough; the value is synthetic because opm ships
// no provider-fulfilled RESOURCE and the fold reads fulfilment only.
_testPreBoundResourceComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: store: requiredResources: {
		"opmodel.dev/catalogs/k8up/resources/backup-store@v1alpha1": fulfilment: "provider"
	}
}

_testPreBoundResourceOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundResourceComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundResourceOutput: spec: provides: [
	"opmodel.dev/catalogs/k8up/resources/backup-store@v1alpha1",
]

// A transformer declaring neither demand map is tolerated, not an error: both
// maps are optional on core's #ComponentTransformer.
_testPreBoundNeitherComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: noop: {}
}

_testPreBoundNeitherOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundNeitherComponent
	#context: #runtimeName: "opm-test"
}).output

// An empty list golden DOES assert emptiness — lists unify by length, unlike
// the struct goldens above, which only assert presence.
_testPreBoundNeitherOutput: spec: provides: []

// Two transformers requiring the same contract contribute ONE entry; the
// struct keys of _providerSet are what deduplicate them.
_testPreBoundDedupComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: {
		backup: requiredTraits: (tra.#BackupTrait.metadata.fqn):  tra.#BackupTrait
		restore: requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
	}
}

_testPreBoundDedupOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundDedupComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundDedupOutput: spec: provides: [
	"opmodel.dev/catalogs/opm/traits/backup@v1alpha1",
]

// A catalog-fulfilled requirement is not a claim: the declaring catalog
// implements it itself, so it never reaches provides.
_testPreBoundNonProviderComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: reg: requiredResources: {
		(res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	}
}

_testPreBoundNonProviderOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundNonProviderComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundNonProviderOutput: spec: provides: []

// WHY this fixture pins ORDER and not only membership: the fold accumulates
// into a struct and reads it back with a comprehension, so provides comes out
// in INSERTION order — the declaration order of the catalog's #transformers
// map, then of each transformer's demand map — never sorted (measured, cue
// v0.17.1). Reordering that map is therefore a rendered-output change. It is
// not an acceptance risk: opm-operator sorts both lists before comparing.

// Two transformers requiring two DIFFERENT provider contracts: the case a real
// provider catalog hits, and the only one where order is observable.
_testPreBoundMultiComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: {
		backup: requiredTraits: (tra.#BackupTrait.metadata.fqn):         tra.#BackupTrait
		command: requiredTraits: (tra.#BackupCommandTrait.metadata.fqn): tra.#BackupCommandTrait
	}
}

_testPreBoundMultiOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundMultiComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundMultiOutput: spec: provides: [
	"opmodel.dev/catalogs/opm/traits/backup@v1alpha1",
	"opmodel.dev/catalogs/opm/traits/backup-command@v1alpha1",
]
