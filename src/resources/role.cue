package resources

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v1"
)

/////////////////////////////////////////////////////////////////
//// Role Resource
/////////////////////////////////////////////////////////////////

#RoleResource: c.#Resource & {
	metadata: {
		modulePath:  "\(id.ModulePath)/resources"
		version:     id.Version
		name:        "role"
		description: "An RBAC Role definition with rules and CUE-referenced subjects"
		labels: {
			"resource.opmodel.dev/category": "security"
		}
	}

	spec: role: #RoleSchema
}

#Role: c.#Component & {
	#resources: (#RoleResource.metadata.fqn): #RoleResource
}

/////////////////////////////////////////////////////////////////
//// Role Schemas
/////////////////////////////////////////////////////////////////

// Single RBAC permission rule — exactly one of the two k8s forms.
#PolicyRuleSchema: #ResourcePolicyRuleSchema | #NonResourcePolicyRuleSchema

#ResourcePolicyRuleSchema: {
	apiGroups!: [...string]
	resources!: [...string]
	verbs!: [...string]
	// Optional whitelist of object names within the resources above.
	// For `signers`, the apiserver special-cases "<domain>/*" wildcards
	// (e.g. "issuers.cert-manager.io/*") — passed through verbatim.
	resourceNames?: [...string]
}

// ClusterRole (scope: "cluster") only — enforced in review/docs, not schema.
#NonResourcePolicyRuleSchema: {
	nonResourceURLs!: [_, ...] & [...string]
	verbs!: [...string]
}

// Role subject — embeds an identity directly via CUE reference.
// References sibling primitives (#WorkloadIdentitySchema, #ServiceAccountSchema)
// in the same package.
#RoleSubjectSchema: {#WorkloadIdentitySchema | #ServiceAccountSchema}

#RoleSchema: {
	name!: string
	scope: "namespace" | "cluster"
	rules!: [...#PolicyRuleSchema] & [_, ...]
	subjects!: [...#RoleSubjectSchema] & [_, ...]
}

#RoleDefaults: #RoleSchema & {
	scope: "namespace"
}
