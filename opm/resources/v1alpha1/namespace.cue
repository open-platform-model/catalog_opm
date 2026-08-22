package v1alpha1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
)

/////////////////////////////////////////////////////////////////
//// Namespaces Resource
/////////////////////////////////////////////////////////////////

#NamespacesResource: c.#Resource & {
	metadata: {
		modulePath:     "\(id.kindPrefix.resources)/v1alpha1"
		name:           "namespaces"
		apiVersion:     "v1alpha1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.resources)/namespaces@v1alpha1"
		description:    "Cluster namespaces owned by this module, emitted with exact names"
		labels: {
			"resource.opmodel.dev/category": "cluster"
		}
	}

	// Alias must not be `name` — the inner field would shadow it and the
	// default becomes self-referential (cf. catalog_opm configmap.cue).
	spec: namespaces: [KeyName=string]: #NamespaceSchema & {name: string | *KeyName}
}

#Namespaces: c.#Component & {
	#resources: (#NamespacesResource.metadata.fqn): #NamespacesResource
}

/////////////////////////////////////////////////////////////////
//// Namespace Schema
/////////////////////////////////////////////////////////////////

// Kubernetes Namespace, emitted with its exact name. Namespaces are
// externally-referenced identities (ModuleInstances, RBAC subjects, webhook
// clientConfigs address them by name), so — like the stable catalog's
// #Role/#ServiceAccount/#CRDs — no prefixing is applied.
// `name` is auto-populated from the map key in the resource spec.
#NamespaceSchema: {
	name: string
	// Merged over context labels (user wins on conflict). This is how
	// Pod-Security labels reach clusters enforcing a baseline PSS, e.g.
	//   labels: "pod-security.kubernetes.io/enforce": "privileged"
	labels?: {[string]: string}
	annotations?: {[string]: string}
}
