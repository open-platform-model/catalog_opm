package transformers

import (
	id "opmodel.dev/catalogs/opm/identity"
	"list"
	k8sappsv1 "opmodel.dev/catalogs/opm/schemas/kubernetes/apps/v1"
	c "opmodel.dev/core@v1"
	res "opmodel.dev/catalogs/opm/resources"
	tr "opmodel.dev/catalogs/opm/traits"
)

// StatefulsetTransformer converts stateful workload components to Kubernetes StatefulSets
#StatefulsetTransformer: c.#ComponentTransformer & {
	metadata: {
		modulePath:  "\(id.ModulePath)/transformers"
		version:     id.Version
		name:        "statefulset-transformer"
		description: "Converts stateful workload components to Kubernetes StatefulSets"

		labels: {
			"core.opmodel.dev/workload-type": "stateful"
			"core.opmodel.dev/resource-type": "statefulset"
		}
	}

	// Required label to match stateful workloads
	requiredLabels: {
		"core.opmodel.dev/workload-type": "stateful"
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

	// Optional traits that enhance statefulset behavior
	optionalTraits: {
		(tr.#ScalingTrait.metadata.fqn):           tr.#ScalingTrait
		(tr.#RestartPolicyTrait.metadata.fqn):     tr.#RestartPolicyTrait
		(tr.#UpdateStrategyTrait.metadata.fqn):    tr.#UpdateStrategyTrait
		(tr.#SidecarContainersTrait.metadata.fqn): tr.#SidecarContainersTrait
		(tr.#InitContainersTrait.metadata.fqn):    tr.#InitContainersTrait
		(tr.#HostNetworkTrait.metadata.fqn):       tr.#HostNetworkTrait
		(tr.#SecurityContextTrait.metadata.fqn):   tr.#SecurityContextTrait
		(tr.#WorkloadIdentityTrait.metadata.fqn):  tr.#WorkloadIdentityTrait
		(tr.#ImagePullSecretsTrait.metadata.fqn):  tr.#ImagePullSecretsTrait
		(tr.#HostPIDTrait.metadata.fqn):           tr.#HostPIDTrait
		(tr.#HostIPCTrait.metadata.fqn):           tr.#HostIPCTrait
		(tr.#GracefulShutdownTrait.metadata.fqn):  tr.#GracefulShutdownTrait
		(tr.#ResourceNameTrait.metadata.fqn):      tr.#ResourceNameTrait
		(tr.#PodSchedulingTrait.metadata.fqn):     tr.#PodSchedulingTrait
		(tr.#PodMetadataTrait.metadata.fqn):       tr.#PodMetadataTrait
		(tr.#ExposeTrait.metadata.fqn):            tr.#ExposeTrait
	}

	#transform: {
		#component: _ // Unconstrained; validated by matching, not by transform signature
		#context:   c.#TransformerContext

		// Extract required Container resource
		_container: #component.spec.container

		// Apply defaults for optional traits (defaults inlined post-014).
		// When `auto` is set the HPA owns the replica count. Emitting
		// `replicas` too would put this transformer and the autoscaler in a
		// permanent server-side-apply tug-of-war on every reconcile, so the
		// field is omitted entirely (see _hasAuto below).
		_hasAuto: #component.spec.scaling != _|_ && #component.spec.scaling.auto != _|_

		_scalingCount: int | *1
		if #component.spec.scaling != _|_ if #component.spec.scaling.auto == _|_ {
			_scalingCount: #component.spec.scaling.count
		}

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
		_initContainers: [...] | *[]
		if #component.spec.initContainers != _|_ {
			_initContainers: #component.spec.initContainers
		}

		// Build StatefulSet resource
		output: k8sappsv1.#StatefulSet & {
			apiVersion: "apps/v1"
			kind:       "StatefulSet"
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
				// This is the governing Service's name, so it follows the
				// SERVICE naming rule, not the workload one:
				// service_transformer.cue honours `expose.name` and this did
				// not, so any StatefulSet with an exact-name Service pointed
				// its serviceName at a Service that does not exist.
				//
				// Deliberately NOT #ResourceNameTrait — that renames the
				// StatefulSet object, not the Service it is governed by.
				serviceName: [
					if #component.spec.expose != _|_ if #component.spec.expose.name != _|_ {#component.spec.expose.name},
					"\(#context.#moduleInstanceMetadata.name)-\(#component.metadata.name)",
				][0]
				if !_hasAuto {
					replicas: _scalingCount
				}
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

_testSTSContext: {
	#moduleInstanceMetadata: {
		name:      "shop"
		namespace: "apps"
		fqn:       "opmodel.dev/catalogs/opm/shop@0.1.0"
		version:   "0.1.0"
		uuid:      "00000000-0000-0000-0000-000000000000"
	}
	#componentMetadata: name: "db"
	#runtimeName: "opm-test"
	componentAnnotations: {}
}

_testSTSContainer: {
	name: "db"
	image: {
		repository: "postgres"
		tag:        "17"
		digest:     ""
	}
}

// Default: neither trait attached — both names stay instance-scoped.
_testSTSDefaultComponent: {
	res.#Container
	tr.#Expose

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container: _testSTSContainer
		expose: {
			type:      "ClusterIP"
			clusterIP: "None"
			ports: pg: {
				targetPort: 5432
			}
		}
	}
}

_testSTSDefaultTransformer: (#StatefulsetTransformer.#transform & {
	#component: _testSTSDefaultComponent
	#context:   _testSTSContext
}).output

_testSTSDefaultName:        "\(_testSTSDefaultTransformer.metadata.name)" & "shop-db"
_testSTSDefaultServiceName: "\(_testSTSDefaultTransformer.spec.serviceName)" & "shop-db"

// The regression this fixes: serviceName names the GOVERNING SERVICE, so it
// must follow expose.name — which service_transformer.cue honours and this
// transformer previously did not, leaving every exact-name-Service StatefulSet
// pointing at a Service that does not exist.
//
// #ResourceNameTrait is set to a DIFFERENT value on purpose: it renames the
// StatefulSet object only. If the two ever collapse onto one name, one of
// these two assertions fails.
_testSTSExactComponent: {
	res.#Container
	tr.#Expose
	tr.#ResourceName

	metadata: {
		name: "db"
		labels: "core.opmodel.dev/workload-type": "stateful"
	}

	spec: {
		container:    _testSTSContainer
		resourceName: "database"
		expose: {
			type:      "ClusterIP"
			clusterIP: "None"
			name:      "database-headless"
			ports: pg: {
				targetPort: 5432
			}
		}
	}
}

_testSTSExactTransformer: (#StatefulsetTransformer.#transform & {
	#component: _testSTSExactComponent
	#context:   _testSTSContext
}).output

_testSTSExactName:        "\(_testSTSExactTransformer.metadata.name)" & "database"
_testSTSExactServiceName: "\(_testSTSExactTransformer.spec.serviceName)" & "database-headless"
