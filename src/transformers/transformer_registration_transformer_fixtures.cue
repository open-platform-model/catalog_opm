@if(fixtures)

package transformers

import (
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1alpha1"
	tra "opmodel.dev/catalogs/opm/traits/v1alpha1"
)

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

// Golden fixture — `cue vet -t fixtures` (task vet) fails on any drift, not just schema errors.
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
// member ships none here, and never a stub), so the provider set of opm's own
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

// WHY each synthetic transformer embeds c.#ComponentTransformer and is keyed by
// its fqn: the helper reads provides from a c.#Catalog built over the map, and
// #Catalog closes #transformers to #ImplFQNType keys and #ComponentTransformer
// values, so a bare `{requiredTraits: …}` is refused with "field not allowed".
// WHY catalogVersion and modulePath are authored: a real provider catalog's map
// arrives already stamped by its own #Catalog, so the helper's _catalog must
// agree with that stamp. Authoring them here pins the 0015:D11 agreement: an
// _catalog whose version or path drifts from #identity fails every
// _testPreBound fixture with a metadata conflict.
_testPreBoundTransformer: c.#ComponentTransformer & {
	#name: c.#NameType
	metadata: {
		name:           #name
		fqn:            "opmodel.dev/catalogs/k8up/transformers/\(#name)@1.0.0"
		modulePath:     "opmodel.dev/catalogs/k8up/transformers"
		catalogVersion: "1.0.0"
		description:    "Synthetic provider transformer"
	}
}

// A required trait with fulfilment "provider" yields exactly its FQN.
_testPreBoundTraitComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: "opmodel.dev/catalogs/k8up/transformers/backup@1.0.0": _testPreBoundTransformer & {
		#name: "backup"
		requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
	}
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

// requiredResources alone is enough; the resource is synthetic because opm
// ships no provider-fulfilled RESOURCE, and core's fold reads fulfilment only.
_testPreBoundResourceComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: "opmodel.dev/catalogs/k8up/transformers/store@1.0.0": _testPreBoundTransformer & {
		#name: "store"
		requiredResources: "opmodel.dev/catalogs/k8up/resources/backup-store@v1alpha1": c.#Resource & {
			fulfilment: "provider"
		}
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
	#transformers: "opmodel.dev/catalogs/k8up/transformers/noop@1.0.0": _testPreBoundTransformer & {
		#name: "noop"
	}
}

_testPreBoundNeitherOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundNeitherComponent
	#context: #runtimeName: "opm-test"
}).output

// An empty list golden DOES assert emptiness — lists unify by length, unlike
// the struct goldens above, which only assert presence.
_testPreBoundNeitherOutput: spec: provides: []

// Two transformers requiring the same contract contribute ONE entry; core's
// #Catalog.provides deduplicates them.
_testPreBoundDedupComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: {
		"opmodel.dev/catalogs/k8up/transformers/backup@1.0.0": _testPreBoundTransformer & {
			#name: "backup"
			requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
		}
		"opmodel.dev/catalogs/k8up/transformers/restore@1.0.0": _testPreBoundTransformer & {
			#name: "restore"
			requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
		}
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
	#transformers: "opmodel.dev/catalogs/k8up/transformers/reg@1.0.0": _testPreBoundTransformer & {
		#name: "reg"
		requiredResources: (res.#TransformerRegistrationResource.metadata.fqn): res.#TransformerRegistrationResource
	}
}

_testPreBoundNonProviderOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundNonProviderComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundNonProviderOutput: spec: provides: []

// WHY this fixture pins ORDER and not only membership: provides is core's
// #Catalog.provides, which sorts ascending, so the declaration order of the
// #transformers map no longer reaches the output. '-' sorts before '@', so
// backup-command comes first. Insertion order coming back (a local fold)
// fails this golden. opm-operator sorts both lists before comparing anyway.

// Two transformers requiring two DIFFERENT provider contracts: the case a real
// provider catalog hits, and the only one where order is observable.
_testPreBoundMultiComponent: res.#PreBoundRegistration & {
	metadata: name: "provider"
	#identity: _testPreBoundIdentity
	#transformers: {
		"opmodel.dev/catalogs/k8up/transformers/backup@1.0.0": _testPreBoundTransformer & {
			#name: "backup"
			requiredTraits: (tra.#BackupTrait.metadata.fqn): tra.#BackupTrait
		}
		"opmodel.dev/catalogs/k8up/transformers/command@1.0.0": _testPreBoundTransformer & {
			#name: "command"
			requiredTraits: (tra.#BackupCommandTrait.metadata.fqn): tra.#BackupCommandTrait
		}
	}
}

_testPreBoundMultiOutput: (#TransformerRegistrationTransformer.#transform & {
	#moduleInstance: _testPreBoundInstance
	#component:      _testPreBoundMultiComponent
	#context: #runtimeName: "opm-test"
}).output

_testPreBoundMultiOutput: spec: provides: [
	"opmodel.dev/catalogs/opm/traits/backup-command@v1alpha1",
	"opmodel.dev/catalogs/opm/traits/backup@v1alpha1",
]
