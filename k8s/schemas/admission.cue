// Kubernetes admission control schemas for OPM native resource definitions.
package schemas

// #ValidatingWebhookConfigurationSchema accepts the full Kubernetes
// ValidatingWebhookConfiguration spec.
#ValidatingWebhookConfigurationSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	webhooks?: [...{
		name!: string
		admissionReviewVersions!: [...string]
		clientConfig?: {
			url?: string
			service?: {
				name!:      string
				namespace!: string
				path?:      string
				port?:      int
				...
			}
			caBundle?: bytes
			...
		}
		rules?: [...{
			apiGroups?: [...string]
			apiVersions?: [...string]
			operations?: [...string]
			resources?: [...string]
			scope?: string
			...
		}]
		failurePolicy?: "Ignore" | "Fail"
		matchPolicy?:   "Exact" | "Equivalent"
		namespaceSelector?: {...}
		objectSelector?: {...}
		sideEffects!:    "None" | "NoneOnDryRun" | "Some" | "Unknown"
		timeoutSeconds?: int & >=1 & <=30
		...
	}]
	...
}

// #MutatingWebhookConfigurationSchema accepts the full Kubernetes
// MutatingWebhookConfiguration spec.
#MutatingWebhookConfigurationSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	webhooks?: [...{
		name!: string
		admissionReviewVersions!: [...string]
		clientConfig?: {
			url?: string
			service?: {
				name!:      string
				namespace!: string
				path?:      string
				port?:      int
				...
			}
			caBundle?: bytes
			...
		}
		rules?: [...{
			apiGroups?: [...string]
			apiVersions?: [...string]
			operations?: [...string]
			resources?: [...string]
			scope?: string
			...
		}]
		failurePolicy?: "Ignore" | "Fail"
		matchPolicy?:   "Exact" | "Equivalent"
		namespaceSelector?: {...}
		objectSelector?: {...}
		sideEffects!:        "None" | "NoneOnDryRun" | "Some" | "Unknown"
		timeoutSeconds?:     int & >=1 & <=30
		reinvocationPolicy?: "Never" | "IfNeeded"
		...
	}]
	...
}
