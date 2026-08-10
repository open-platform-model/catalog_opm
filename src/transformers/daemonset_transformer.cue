package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	"list"
	k8sappsv1 "opmodel.dev/catalogs/opm/schemas/kubernetes/apps/v1"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources"
	tr "opmodel.dev/catalogs/opm/traits"
)

// DaemonSetTransformer converts daemon workload components to Kubernetes DaemonSets
#DaemonSetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:     id.kindPrefix.transformers
		name:           "daemonset-transformer"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.transformers)/daemonset-transformer@\(id.Version)"
		description:    "Converts daemon workload components to Kubernetes DaemonSets"

		labels: {
			"core.opmodel.dev/workload-type": "daemon"
			"core.opmodel.dev/resource-type": "daemonset"
		}
	}

	// Required label to match daemon workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "daemon"
	}

	// Required resources - Container MUST be present
	requiredResources: {
		(res.#ContainerResource.metadata.fqn): res.#ContainerResource
	}

	// Optional resources
	optionalResources: {
		(res.#VolumesResource.metadata.fqn): res.#VolumesResource
	}

	// No required traits
	requiredTraits: {}

	// Optional traits that enhance daemonset behavior
	// Note: NO Scaling trait - DaemonSets run one pod per node
	optionalTraits: {
		(tr.#RestartPolicyTrait.metadata.fqn):     tr.#RestartPolicyTrait
		(tr.#UpdateStrategyTrait.metadata.fqn):    tr.#UpdateStrategyTrait
		(tr.#SidecarContainersTrait.metadata.fqn): tr.#SidecarContainersTrait
		(tr.#InitContainersTrait.metadata.fqn):    tr.#InitContainersTrait
		(tr.#SecurityContextTrait.metadata.fqn):   tr.#SecurityContextTrait
		(tr.#RuntimeClassTrait.metadata.fqn):      tr.#RuntimeClassTrait
		(tr.#WorkloadIdentityTrait.metadata.fqn):  tr.#WorkloadIdentityTrait
		(tr.#ImagePullSecretsTrait.metadata.fqn):  tr.#ImagePullSecretsTrait
		(tr.#HostPIDTrait.metadata.fqn):           tr.#HostPIDTrait
		(tr.#HostIPCTrait.metadata.fqn):           tr.#HostIPCTrait
		(tr.#HostNetworkTrait.metadata.fqn):       tr.#HostNetworkTrait
		(tr.#GracefulShutdownTrait.metadata.fqn):  tr.#GracefulShutdownTrait
		(tr.#ResourceNameTrait.metadata.fqn):      tr.#ResourceNameTrait
		(tr.#PodSchedulingTrait.metadata.fqn):     tr.#PodSchedulingTrait
		(tr.#PodMetadataTrait.metadata.fqn):       tr.#PodMetadataTrait
		(tr.#NetworkPolicyTrait.metadata.fqn):     tr.#NetworkPolicyTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Apply defaults for optional traits (defaults inlined post-014).
		_restartPolicy: string | *"Always"
		if #component.spec.restartPolicy != _|_ {
			_restartPolicy: #component.spec.restartPolicy
		}

		// Extract update strategy with defaults
		_updateStrategy: *null | {
			if #component.spec.updateStrategy != _|_ {
				type: #component.spec.updateStrategy.type
				if #component.spec.updateStrategy.type == "RollingUpdate" {
					rollingUpdate: #component.spec.updateStrategy.rollingUpdate
				}
			}
		}

		// Build main container: base conversion via helper, unified with trait fields
		_mainContainer: (#ToK8sContainer & {"in": _container, #instancePrefix: #context.#moduleInstanceMetadata.name}).out

		// Build container list (main container + optional sidecars)
		_sidecarContainers: [...] | *[]
		if #component.spec.sidecarContainers != _|_ {
			_sidecarContainers: #component.spec.sidecarContainers
		}

		// Extract init containers with defaults
		_initContainers: [...]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		// Build DaemonSet resource
		output: k8sappsv1.#DaemonSet & {
			apiVersion: "apps/v1"
			kind:       "DaemonSet"
			metadata: {
				name: (#WorkloadName & {
					#comp:     #component
					#instance: #context.#moduleInstanceMetadata.name
				}).out
				namespace: #context.#moduleInstanceMetadata.namespace
				labels:    #context.labels
				// Include component annotations if present
				if len(#context.componentAnnotations) > 0 {
					annotations: #context.componentAnnotations
				}
			}
			spec: {
				selector: matchLabels: #context.componentLabels
				template: {
					metadata: (#PodTemplateMetadata & {
						#comp:   #component
						#labels: #context.componentLabels
					}).out
					spec: {
						(#PodSchedulingFields & {#comp: #component}).out

						_convertedSidecars: (#ToK8sContainers & {"in": _sidecarContainers, #instancePrefix: #context.#moduleInstanceMetadata.name}).out
						containers: list.Concat([[_mainContainer], _convertedSidecars])

						if len(_initContainers) > 0 {
							initContainers: (#ToK8sContainers & {"in": _initContainers, #instancePrefix: #context.#moduleInstanceMetadata.name}).out
						}

						restartPolicy: _restartPolicy

						// The named RuntimeClass must already exist in the cluster;
						// this only references it.
						if #component.spec.runtimeClass != _|_ {
							runtimeClassName: #component.spec.runtimeClass
						}

						if #component.spec.hostNetwork != _|_ {
							hostNetwork: #component.spec.hostNetwork
						}

						if #component.spec.hostPid != _|_ {
							hostPID: #component.spec.hostPid
						}

						if #component.spec.hostIpc != _|_ {
							hostIPC: #component.spec.hostIpc
						}

						if #component.spec.securityContext != _|_ {
							let _sc = #component.spec.securityContext
							if _sc.runAsNonRoot != _|_ || _sc.runAsUser != _|_ || _sc.runAsGroup != _|_ || _sc.fsGroup != _|_ || _sc.supplementalGroups != _|_ {
								securityContext: {
									if _sc.runAsNonRoot != _|_ {
										runAsNonRoot: _sc.runAsNonRoot
									}
									if _sc.runAsUser != _|_ {
										runAsUser: _sc.runAsUser
									}
									if _sc.runAsGroup != _|_ {
										runAsGroup: _sc.runAsGroup
									}
									if _sc.fsGroup != _|_ {
										fsGroup: _sc.fsGroup
									}
									if _sc.supplementalGroups != _|_ {
										supplementalGroups: _sc.supplementalGroups
									}
								}
							}
						}

						if #component.spec.workloadIdentity != _|_ {
							serviceAccountName: #component.spec.workloadIdentity.name
						}

						// Image pull secrets: pod-level registry credentials
						if #component.spec.imagePullSecrets != _|_ {
							imagePullSecrets: #component.spec.imagePullSecrets
						}

						// Volumes: convert OPM volume specs to Kubernetes volume specs
						if #component.spec.volumes != _|_ {
							volumes: (#ToK8sVolumes & {"in": #component.spec.volumes, #instancePrefix: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"}).out
						}

						// Graceful shutdown: pod-level termination grace period
						if #component.spec.gracefulShutdown != _|_ {
							terminationGracePeriodSeconds: #component.spec.gracefulShutdown.terminationGracePeriodSeconds
						}
					}
				}

				if _updateStrategy != null {
					updateStrategy: _updateStrategy
				}
			}
		}
	}
}

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Mirrors the live istio-cni-node DaemonSet on an ambient mesh. Two things are
// load-bearing and both are asserted below:
//
//   1. The rendered name must be exactly `istio-cni-node`. The CNI plugin
//      recognises its own agent pod by that name prefix
//      (cni/pkg/plugin/plugin.go isCNIPod) and uses the check to let its
//      replacement pod through when it cannot reach the API server. A
//      prefixed name means the plugin blocks its own replacement.
//   2. Exactly ONE mount carries mountPropagation: HostToContainer. The netns
//      directory is bind-mounted by the runtime after the agent starts, so
//      without propagation the agent never sees pods created later — and it
//      presents as a network fault, not a config error.
_testDSCNIComponent: {
	res.#Container
	res.#Volumes
	tr.#ResourceName

	metadata: {
		name: "istio-cni"
		labels: "core.opmodel.dev/workload-type": "daemon"
	}

	spec: {
		resourceName: "istio-cni-node"

		volumes: {
			"cni-net-dir": {
				name:     "cni-net-dir"
				readOnly: false
				hostPath: path: "/etc/cni/net.d"
			}
			"cni-netns-dir": {
				name:     "cni-netns-dir"
				readOnly: false
				hostPath: {
					path: "/var/run/netns"
					type: "DirectoryOrCreate"
				}
			}
		}

		container: {
			name: "install-cni"
			image: {
				repository: "docker.io/istio/install-cni"
				tag:        "1.30.3-distroless"
				digest:     ""
			}
			volumeMounts: {
				"cni-net-dir": spec.volumes."cni-net-dir" & {
					mountPath: "/host/etc/cni/net.d"
				}
				"cni-netns-dir": spec.volumes."cni-netns-dir" & {
					mountPath:        "/host/var/run/netns"
					mountPropagation: "HostToContainer"
				}
			}
		}
	}
}

_testDSCNITransformer: (#DaemonSetTransformer.#transform & {
	#component: _testDSCNIComponent
	#context: {
		#moduleInstanceMetadata: {
			name:      "istio"
			namespace: "istio-system"
			fqn:       "opmodel.dev/catalogs/opm/istio@0.1.0"
			version:   "0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#componentMetadata: name: "istio-cni"
		#runtimeName: "opm-test"
		componentAnnotations: {}
	}
}).output

// Interpolation forces resolution, so a regression to a defaulted disjunction
// cannot be repaired by the assertion.
_testDSCNINameResolves: "\(_testDSCNITransformer.metadata.name)" & "istio-cni-node"

_testDSMounts: _testDSCNITransformer.spec.template.spec.containers[0].volumeMounts

// Present on the netns mount...
_testDSPropagationPresent: [
	if _testDSMounts[1].mountPropagation != _|_ {_testDSMounts[1].mountPropagation},
] & ["HostToContainer"]

// ...and on NOTHING else. This is the guard that catches an unguarded
// passthrough that stamps a value onto every mount.
_testDSPropagationNotLeaked: [
	if _testDSMounts[0].mountPropagation != _|_ {"leaked"},
] & []

/////////////////////////////////////////////////////////////////
//// RuntimeClass
/////////////////////////////////////////////////////////////////

_testDSRuntimeClassComponent: {
	res.#Container
	tr.#RuntimeClass

	metadata: {
		name: "nvidia-device-plugin"
		labels: "core.opmodel.dev/workload-type": "daemon"
	}

	spec: {
		runtimeClass: "nvidia"

		container: {
			name: "nvidia-device-plugin-ctr"
			image: {
				repository: "nvcr.io/nvidia/k8s-device-plugin"
				tag:        "v0.17.4"
				digest:     ""
			}
		}
	}
}

_testDSRuntimeClassTransformer: (#DaemonSetTransformer.#transform & {
	#component: _testDSRuntimeClassComponent
	#context: {
		#moduleInstanceMetadata: {
			name:      "nvidia-device-plugin"
			namespace: "kube-system"
			fqn:       "opmodel.dev/catalogs/opm/test-instance@0.1.0"
			version:   "0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#componentMetadata: name: "nvidia-device-plugin"
		#runtimeName: "opm-test"
		componentAnnotations: {}
	}
}).output

// The trait reaches the rendered pod spec as runtimeClassName.
_testDSRuntimeClassPresent: [
	if _testDSRuntimeClassTransformer.spec.template.spec.runtimeClassName != _|_ {
		_testDSRuntimeClassTransformer.spec.template.spec.runtimeClassName
	},
] & ["nvidia"]

// ...and is absent when the trait is not applied. Without the `!= _|_` guard
// this would render as an incomplete value rather than being omitted, which
// Kubernetes rejects.
_testDSRuntimeClassNotLeaked: [
	if _testDSCNITransformer.spec.template.spec.runtimeClassName != _|_ {"leaked"},
] & []
