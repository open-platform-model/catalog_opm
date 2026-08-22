package transformers

import (
	id "opmodel.dev/catalogs/k8s/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/k8s/resources/v1"
)

// #ObjectTransformer passes arbitrary Kubernetes objects — including Custom
// Resource instances — through with OPM context applied (name prefix, namespace
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

		_objects:  #component.spec.objects
		_instName: #context.#moduleInstanceMetadata.name
		_compName: #context.#componentMetadata.name

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
						name: "\(_instName)-\(_compName)-\(_userName)"
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
