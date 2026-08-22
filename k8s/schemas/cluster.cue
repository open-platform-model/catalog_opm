// Kubernetes cluster resource schemas for OPM native resource definitions.
package schemas

// #NamespaceSchema accepts the full Kubernetes Namespace spec.
#NamespaceSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		finalizers?: [...string]
		...
	}
	...
}
