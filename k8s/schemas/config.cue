// Kubernetes configuration schemas for OPM native resource definitions.
package schemas

// #ConfigMapSchema accepts the full Kubernetes ConfigMap spec.
#ConfigMapSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	data?: {[string]: string}
	binaryData?: {[string]: bytes}
	immutable?: bool
	...
}

// #SecretSchema accepts the full Kubernetes Secret spec.
#SecretSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	type?: *"Opaque" | "kubernetes.io/service-account-token" | "kubernetes.io/dockerconfigjson" | "kubernetes.io/tls" | string
	data?: {[string]: bytes}
	stringData?: {[string]: string}
	immutable?: bool
	...
}
