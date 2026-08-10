package v1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
)

/////////////////////////////////////////////////////////////////
//// Objects Resource Definition
/////////////////////////////////////////////////////////////////

// #K8sObjectsResource renders arbitrary Kubernetes objects — built-in kinds OR
// Custom Resource instances (Issuer, Gateway, MongoDBCommunity,
// VolumeSnapshotClass, …). It is the catalog's escape hatch for any GVK the
// typed resources do not model.
//
// Each entry carries an OPM-only `scope` discriminator (a sibling of the object
// body, never rendered) telling the transformer whether to stamp a namespace.
#K8sObjectsResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1"
		name:           "k8s-objects"
		apiVersion:     "v1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/k8s-objects@v1"
		description:    "Arbitrary Kubernetes objects, including Custom Resource instances"
		labels: {
			"resource.opmodel.dev/category": "generic"
		}
	}

	spec: k8sObjects: [objName=string]: #K8sObjectEntrySchema
}

#K8sObjects: c.#Component & {
	#resources: {(#K8sObjectsResource.metadata.fqn): #K8sObjectsResource}
}

/////////////////////////////////////////////////////////////////
//// Object Entry Schema
/////////////////////////////////////////////////////////////////

// A single arbitrary object plus its scope discriminator.
#K8sObjectEntrySchema: {
	// Whether the rendered object is namespaced (gets metadata.namespace) or
	// cluster-scoped (none). OPM-only — never appears in the rendered object.
	scope: *"Namespaced" | "Cluster"

	// The full native object. apiVersion + kind are required; everything else
	// is open so any spec/data/webhooks/etc. passes through unchanged.
	object!: {
		apiVersion!: string
		kind!:       string
		metadata?: {
			name?: string
			labels?: {[string]: string}
			annotations?: [string]: string
			...
		}
		...
	}
}
