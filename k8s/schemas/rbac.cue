// Kubernetes RBAC schemas for OPM native resource definitions.
package schemas

// #ServiceAccountSchema accepts the full Kubernetes ServiceAccount spec.
#ServiceAccountSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	automountServiceAccountToken?: bool
	imagePullSecrets?: [...{name?: string, ...}]
	secrets?: [...{name?: string, ...}]
	...
}

// #RoleSchema accepts the full Kubernetes Role spec.
#RoleSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	rules?: [...{
		apiGroups?: [...string]
		resources?: [...string]
		verbs!: [...string]
		resourceNames?: [...string]
		nonResourceURLs?: [...string]
		...
	}]
	...
}

// #ClusterRoleSchema accepts the full Kubernetes ClusterRole spec.
#ClusterRoleSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	rules?: [...{
		apiGroups?: [...string]
		resources?: [...string]
		verbs!: [...string]
		resourceNames?: [...string]
		nonResourceURLs?: [...string]
		...
	}]
	aggregationRule?: {
		clusterRoleSelectors?: [...{
			matchLabels?: {[string]: string}
			...
		}]
		...
	}
	...
}

// #RoleBindingSchema accepts the full Kubernetes RoleBinding spec.
#RoleBindingSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	subjects?: [...{
		kind!:      "User" | "Group" | "ServiceAccount"
		name!:      string
		namespace?: string
		apiGroup?:  string
		...
	}]
	roleRef?: {
		apiGroup!: string
		kind!:     "Role" | "ClusterRole"
		name!:     string
		...
	}
	...
}

// #ClusterRoleBindingSchema accepts the full Kubernetes ClusterRoleBinding spec.
#ClusterRoleBindingSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	subjects?: [...{
		kind!:      "User" | "Group" | "ServiceAccount"
		name!:      string
		namespace?: string
		apiGroup?:  string
		...
	}]
	roleRef?: {
		apiGroup!: string
		kind!:     "ClusterRole"
		name!:     string
		...
	}
	...
}
