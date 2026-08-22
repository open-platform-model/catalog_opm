// Kubernetes apiregistration schemas for OPM native resource definitions.
package schemas

// #APIServiceSchema is an open schema for an aggregated APIService
// (apiregistration.k8s.io/v1). Cluster-scoped. Fields are passed through
// verbatim by the transformer, so the schema stays permissive.
#APIServiceSchema: {
	metadata?: {
		// APIService names are semantically fixed as "<version>.<group>"
		// (e.g. "v1beta1.metrics.k8s.io"); supply it concretely.
		name!: string
		labels?: [string]:      string
		annotations?: [string]: string
		...
	}
	spec: {
		group?:                string
		version?:              string
		groupPriorityMinimum!: int
		versionPriority!:      int
		service?: {
			name!:      string
			namespace!: string
			port?:      int
		}
		caBundle?:              string
		insecureSkipTLSVerify?: bool
		...
	}
	...
}
