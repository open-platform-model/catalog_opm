// Kubernetes policy schemas for OPM native resource definitions.
package schemas

// #HorizontalPodAutoscalerSchema accepts the full Kubernetes HPA v2 spec.
#HorizontalPodAutoscalerSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		scaleTargetRef?: {
			apiVersion?: string
			kind!:       string
			name!:       string
			...
		}
		minReplicas?: int & >=1
		maxReplicas!: int & >=1
		metrics?: [...{...}]
		behavior?: {...}
		...
	}
	...
}

// #PodDisruptionBudgetSchema accepts the full Kubernetes PodDisruptionBudget spec.
#PodDisruptionBudgetSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		minAvailable?:   int | string
		maxUnavailable?: int | string
		selector?: {
			matchLabels?: {[string]: string}
			...
		}
		unhealthyPodEvictionPolicy?: "IfHealthyBudget" | "AlwaysAllow"
		...
	}
	...
}
