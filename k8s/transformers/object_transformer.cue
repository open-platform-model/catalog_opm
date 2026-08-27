package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ObjectTransformer passes arbitrary Kubernetes objects — including Custom
// Resource instances — through with OPM context applied (name from the component's `#names`, namespace
// for namespaced scope, merged labels/annotations). The object body is rendered
// verbatim except for the managed metadata surface; the OPM-only `scope` field
// is never emitted.
#ObjectTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "object-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/object-transformer@\(id.Version)"
		description:    "Passes arbitrary Kubernetes objects (including Custom Resource instances) through with OPM context applied"
		labels: {
			"core.opmodel.dev/resource-category": "generic"
			"core.opmodel.dev/resource-type":     "object"
		}
	}

	requiredLabels: {}
	requiredResources: {
		(res.#ObjectsResource.metadata.fqn): res.#ObjectsResource
	}
	optionalResources: {}
	requiredTraits: {}
	optionalTraits: {}

	#transform: {
		#component: _
		#context:   c.#TransformerContext

		_objects: #component.spec.objects

		// One rendered object per map entry. List output → one resource each.
		output: [
			for objName, o in _objects
			let _userName = [if o.object.metadata != _|_ if o.object.metadata.name != _|_ {o.object.metadata.name}, objName][0]
			let _userMeta = [if o.object.metadata != _|_ {o.object.metadata}, {}][0]
			let _userLabels = [if _userMeta.labels != _|_ {_userMeta.labels}, {}][0]
			let _userAnnos = [if _userMeta.annotations != _|_ {_userMeta.annotations}, {}][0] {
				{
					// Pass through every top-level field except metadata.
					for k, v in o.object if k != "metadata" {(k): v}
					metadata: {
						// Prefix is the component's resourceName (override-honouring); the
						// user segment is exact.
						name: "\(#component.#names.resourceName)-\(_userName)"
						if o.scope == "Namespaced" {
							namespace: #context.#moduleInstanceMetadata.namespace
						}

						// Merge labels: context labels the user did not set, then
						// user labels (user wins on conflict, no unify clash).
						labels: {
							for k, v in #context.labels if _userLabels[k] == _|_ {(k): v}
							for k, v in _userLabels {(k): v}
						}
						if len(_userAnnos) > 0 {
							annotations: _userAnnos
						}
					}
				}
			},
		]
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testObjectContext: {
	#moduleInstanceMetadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/catalogs/k8s/shop@0.1.0"
		version:   "0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: name: "extras"
	#runtimeName: "opm-test"
	componentAnnotations: {}
}

// Default naming: the instance-prefixed resourceName prefixes the user segment.
_testObjectDefaultNameComponent: res.#Objects & {
	#instance: {name: "shop", namespace: "apps", uuid: "00000000-0000-0000-0000-000000000000"}
	metadata: name: "extras"
	spec: objects: issuer: object: {
		apiVersion: "cert-manager.io/v1"
		kind:       "Issuer"
		spec: selfSigned: {}
	}
}

_testObjectDefaultNameTransformer: (#ObjectTransformer.#transform & {
	#component: _testObjectDefaultNameComponent
	#context:   _testObjectContext
}).output

_testObjectDefaultNameResolves: "\(_testObjectDefaultNameTransformer[0].metadata.name)" & "shop-extras-issuer"
