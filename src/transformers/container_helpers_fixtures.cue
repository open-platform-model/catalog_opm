@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// Non-immutable secret: K8s name = {prefix}-{secret.name}, no hash suffix.
_testToK8sVolumesSecret: {
	in: {
		auth: {
			name: "auth"
			secret: {
				from: {
					name:      "zot-htpasswd"
					immutable: false
					data: {
						htpasswd: "admin:hashed"
					}
				}
				items: [{
					key:  "htpasswd"
					path: "auth/htpasswd"
					mode: 256
				}]
				defaultMode: 420
			}
		}
	}

	out: (#ToK8sVolumes & {
		"in":            in
		#instancePrefix: "registry"
	}).out

	out: [{
		name: "auth"
		secret: {
			secretName:  "registry-zot-htpasswd"
			defaultMode: 420
			items: [{
				key:  "htpasswd"
				path: "auth/htpasswd"
				mode: 256
			}]
		}
	}]
}

// Immutable secret: K8s name = {prefix}-{secret.name}-{contenthash}.
_testToK8sVolumesSecretImmutable: {
	in: {
		config: {
			name: "config"
			secret: {
				from: {
					name:      "my-config"
					immutable: true
					data: {
						"config.json": "hello"
					}
				}
				items: [{key: "config.json", path: "config.json"}]
			}
		}
	}

	out: (#ToK8sVolumes & {
		"in":            in
		#instancePrefix: "myapp-mycomponent"
	}).out

	out: [{
		name: "config"
		secret: {
			secretName: (res.#ImmutableName & {
				baseName: "myapp-mycomponent-my-config"
				data: {"config.json": "hello"}
				immutable: true
			}).out
			items: [{key: "config.json", path: "config.json"}]
		}
	}]
}

// Exact-name configMap: K8s name = the authored name, no instance prefix and
// no content hash (istiod reads mesh config from the ConfigMap named `istio`).
_testToK8sVolumesConfigMapExactName: {
	in: {
		config: {
			name: "config"
			configMap: {
				name:      "istio"
				exactName: true
				data: mesh: "defaultConfig: {}"
			}
		}
	}

	out: (#ToK8sVolumes & {
		"in":            in
		#instancePrefix: "istio-instance-istiod"
	}).out

	out: [{
		name: "config"
		configMap: name: "istio"
	}]
}

// External/exact-name volume sources + a projected serviceAccountToken.
// Golden values transcribed from the live ztunnel DaemonSet on a running
// ambient mesh (istio 1.28.10): the CA-root ConfigMap is created by istiod at
// runtime, so it can only be referenced by exact name, and the token is
// audience-bound to istio-ca.
_testToK8sVolumesExternalAndProjected: {
	in: {
		"istio-token": {
			name: "istio-token"
			projected: {
				defaultMode: 420
				sources: [{
					serviceAccountToken: {
						audience:          "istio-ca"
						expirationSeconds: 43200
						path:              "istio-token"
					}
				}]
			}
		}
		"istiod-ca-cert": {
			name: "istiod-ca-cert"
			configMapRef: {
				name:        "istio-ca-root-cert"
				defaultMode: 420
			}
		}
		cacerts: {
			name: "cacerts"
			secretRef: {
				name:        "cacerts"
				defaultMode: 420
				optional:    true
			}
		}
	}

	out: (#ToK8sVolumes & {
		"in":            in
		#instancePrefix: "istio-instance-istiod"
	}).out

	// Order follows the authored map's declaration order.
	out: [
		{
			name: "istio-token"
			projected: {
				defaultMode: 420
				sources: [{
					serviceAccountToken: {
						audience:          "istio-ca"
						path:              "istio-token"
						expirationSeconds: 43200
					}
				}]
			}
		},
		{
			name: "istiod-ca-cert"
			configMap: {
				name:        "istio-ca-root-cert"
				defaultMode: 420
			}
		},
		{
			name: "cacerts"
			secret: {
				secretName:  "cacerts"
				defaultMode: 420
				optional:    true
			}
		},
	]
}

// Projected volume combining a token with configMap/secret projections —
// both use `name` (K8s projection types are LocalObjectReference-based) and
// carry no per-source defaultMode.
_testToK8sVolumesProjectedMultiSource: {
	in: {
		bundle: {
			name: "bundle"
			projected: sources: [
				{serviceAccountToken: {audience: "vault", path: "token"}},
				{configMap: {name: "trust-bundle", items: [{key: "ca.crt", path: "ca.crt", mode: 292}]}},
				{secret: {name: "client-cert", optional: true}},
			]
		}
	}

	out: (#ToK8sVolumes & {"in": in}).out

	out: [{
		name: "bundle"
		projected: sources: [
			{serviceAccountToken: {audience: "vault", path: "token"}},
			{configMap: {name: "trust-bundle", items: [{key: "ca.crt", path: "ca.crt", mode: 292}]}},
			{secret: {name: "client-cert", optional: true}},
		]
	}]
}

// Immutable configMap: K8s name = {configmap.name}-{contenthash}.
_testToK8sVolumesConfigMapImmutable: {
	in: {
		config: {
			name: "config"
			configMap: {
				name:      "wolf-config-toml"
				immutable: true
				data: {
					"wolf.toml": "[wolf]\nenabled = true"
				}
			}
		}
	}

	out: (#ToK8sVolumes & {
		"in":            in
		#instancePrefix: "wolf-instance-wolf"
	}).out

	out: [{
		name: "config"
		configMap: name: (res.#ImmutableName & {
			baseName: "wolf-instance-wolf-wolf-config-toml"
			data: {"wolf.toml": "[wolf]\nenabled = true"}
			immutable: true
		}).out
	}]
}

_testToK8sContainer: {
	// Example input container
	in: {
		name: "example-container"
		image: {
			repository: "example-image"
			tag:        "latest"
			digest:     ""
		}
		command: ["/bin/example"]
		args: ["--example-arg"]
		ports: {
			http: {
				name:       "http"
				targetPort: 8080
				protocol:   "TCP"
			}
		}
		env: {
			EXAMPLE_ENV_VAR: {
				name:  "EXAMPLE_ENV_VAR"
				value: "example-value"
			}
		}
		resources: {
			requests: {
				cpu:    "100m"
				memory: "128Mi"
			}
			limits: {
				cpu:    "200m"
				memory: "256Mi"
			}
		}
		volumeMounts: {
			exampleVolumeMount: {
				name:      "example-volume"
				mountPath: "/data/example"
			}
		}
	}

	out: (#ToK8sContainer & {"in": in}).out
}

_testToK8sContainers: {
	// Example list of input containers
	in: [
		{
			name: "example-container-1"
			image: {
				repository: "example-image-1"
				tag:        "latest"
				digest:     ""
			}
		},
		{
			name: "example-container-2"
			image: {
				repository: "example-image-2"
				tag:        "latest"
				digest:     ""
			}
		},
	]

	out: (#ToK8sContainers & {"in": in}).out
}

// Test: preStopCommand produces lifecycle.preStop.exec.command
_testToK8sContainerPreStop: {
	in: {
		name: "graceful"
		image: {
			repository: "app"
			tag:        "v1"
			digest:     ""
		}
		preStopCommand: ["/bin/sh", "-c", "sleep 5"]
	}

	out: (#ToK8sContainer & {"in": in}).out

	out: {
		name:  "graceful"
		image: "app:v1"
		lifecycle: preStop: exec: command: ["/bin/sh", "-c", "sleep 5"]
	}
}
