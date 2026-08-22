// Kubernetes network schemas for OPM native resource definitions.
package schemas

// #ServiceSchema accepts the full Kubernetes Service spec.
#ServiceSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		type?: *"ClusterIP" | "NodePort" | "LoadBalancer" | "ExternalName"
		selector?: {[string]: string}
		ports?: [...{
			name?:       string
			port!:       int & >=1 & <=65535
			targetPort?: int | string
			protocol?:   *"TCP" | "UDP" | "SCTP"
			nodePort?:   int & >=30000 & <=32767
			...
		}]
		clusterIP?: string
		externalIPs?: [...string]
		loadBalancerIP?:        string
		sessionAffinity?:       "None" | "ClientIP"
		externalTrafficPolicy?: "Cluster" | "Local"
		...
	}
	...
}

// #IngressSchema accepts the full Kubernetes Ingress spec.
#IngressSchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		ingressClassName?: string
		defaultBackend?: {
			service?: {
				name!: string
				port?: {
					number?: int
					name?:   string
					...
				}
				...
			}
			...
		}
		rules?: [...{
			host?: string
			http?: {
				paths?: [...{
					path?:     string
					pathType?: "Exact" | "Prefix" | "ImplementationSpecific"
					backend?: {
						service?: {
							name!: string
							port?: {
								number?: int
								name?:   string
								...
							}
							...
						}
						...
					}
					...
				}]
				...
			}
			...
		}]
		tls?: [...{
			hosts?: [...string]
			secretName?: string
			...
		}]
		...
	}
	...
}

// #IngressClassSchema accepts the full Kubernetes IngressClass spec.
#IngressClassSchema: {
	metadata?: {
		name?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		controller!: string
		parameters?: {
			apiGroup?:  string
			kind!:      string
			name!:      string
			namespace?: string
			scope?:     "Cluster" | "Namespace"
			...
		}
		...
	}
	...
}

// #NetworkPolicySchema accepts the full Kubernetes NetworkPolicy spec.
#NetworkPolicySchema: {
	metadata?: {
		name?:      string
		namespace?: string
		labels?: {[string]: string}
		annotations?: {[string]: string}
		...
	}
	spec?: {
		podSelector?: {
			matchLabels?: {[string]: string}
			...
		}
		policyTypes?: [...("Ingress" | "Egress")]
		ingress?: [...{...}]
		egress?: [...{...}]
		...
	}
	...
}
