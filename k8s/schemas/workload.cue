// Kubernetes workload schemas for OPM native resource definitions.
// Schemas are intentionally open (using ...) to accept any valid Kubernetes
// workload configuration without reimplementing the full K8s spec.
package schemas

// #DeploymentSchema accepts the full Kubernetes Deployment spec.
// Fields are open to allow any valid Kubernetes Deployment configuration.
#DeploymentSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		replicas?: int & >=0
		selector?: {
			matchLabels?: {[string]: string}
			...
		}
		template?: {
			metadata?: {
				labels?: {[string]: string}
				annotations?: {[string]: string}
				...
			}
			spec?: {
				containers?: [...{
					name!:  string
					image!: string
					...
				}]
				...
			}
			...
		}
		strategy?: {...}
		...
	}
	...
}

// #StatefulSetSchema accepts the full Kubernetes StatefulSet spec.
// Fields are open to allow any valid Kubernetes StatefulSet configuration.
#StatefulSetSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		replicas?:    int & >=0
		serviceName!: string
		selector?: {
			matchLabels?: {[string]: string}
			...
		}
		template?: {
			metadata?: {
				labels?: {[string]: string}
				annotations?: {[string]: string}
				...
			}
			spec?: {
				containers?: [...{
					name!:  string
					image!: string
					...
				}]
				...
			}
			...
		}
		volumeClaimTemplates?: [...{...}]
		...
	}
	...
}

// #DaemonSetSchema accepts the full Kubernetes DaemonSet spec.
// Fields are open to allow any valid Kubernetes DaemonSet configuration.
#DaemonSetSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		selector?: {
			matchLabels?: {[string]: string}
			...
		}
		template?: {
			metadata?: {
				labels?: {[string]: string}
				annotations?: {[string]: string}
				...
			}
			spec?: {
				containers?: [...{
					name!:  string
					image!: string
					...
				}]
				...
			}
			...
		}
		updateStrategy?: {...}
		...
	}
	...
}

// #JobSchema accepts the full Kubernetes Job spec.
// Fields are open to allow any valid Kubernetes Job configuration.
#JobSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		completions?:  int & >=1
		parallelism?:  int & >=0
		backoffLimit?: int & >=0
		template?: {
			metadata?: {
				labels?: {[string]: string}
				annotations?: {[string]: string}
				...
			}
			spec?: {
				containers?: [...{
					name!:  string
					image!: string
					...
				}]
				restartPolicy?: "Never" | "OnFailure"
				...
			}
			...
		}
		...
	}
	...
}

// #CronJobSchema accepts the full Kubernetes CronJob spec.
// Fields are open to allow any valid Kubernetes CronJob configuration.
#CronJobSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		schedule!:          string
		concurrencyPolicy?: "Allow" | "Forbid" | "Replace"
		suspend?:           bool
		jobTemplate?: {
			metadata?: {...}
			spec?: #JobSchema.spec & {...}
			...
		}
		...
	}
	...
}

// #PodSchema accepts the full Kubernetes Pod spec.
// Fields are open to allow any valid Kubernetes Pod configuration.
#PodSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		containers?: [...{
			name!:  string
			image!: string
			...
		}]
		restartPolicy?: "Always" | "OnFailure" | "Never"
		...
	}
	...
}
