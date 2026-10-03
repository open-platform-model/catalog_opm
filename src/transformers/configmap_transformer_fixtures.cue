@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// One component carrying both naming modes: `istio` is read by name from
// outside the module (istiod's mesh config), while `app-config` takes the
// default instance-scoped name.
_testConfigMapNamingComponent: res.#ConfigMaps & {
	metadata: name: "istiod"
	spec: configMaps: {
		istio: {
			exactName: true
			data: mesh: "defaultConfig: {}"
		}
		"app-config": {
			data: "log-level": "info"
		}
	}
}

_testConfigMapNamingTransformer: (#ConfigMapTransformer.#transform & {
	#component: _testConfigMapNamingComponent
	#moduleInstance: {
		metadata: {
			name:      "istio"
			namespace: "istio-system"
			fqn:       "opmodel.dev/modules/istio@0.1.0"
			uuid:      "00000000-0000-0000-0000-000000000000"
		}
		#moduleMetadata: version: "0.1.0"
	}
	#context: #runtimeName: "opm-test"
}).output

// Golden — exact name emitted verbatim; the default path keeps the
// {instance}-{component}-{name} prefix. Order follows declaration order.
_testConfigMapNamingTransformer: [
	{
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "istio"
			namespace: "istio-system"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "istiod"
				"app.kubernetes.io/name":           "istiod"
				"module-instance.opmodel.dev/name": "istio"
			}
		}
		data: mesh: "defaultConfig: {}"
	},
	{
		apiVersion: "v1"
		kind:       "ConfigMap"
		metadata: {
			name:      "istio-istiod-app-config"
			namespace: "istio-system"
			labels: {
				"app.kubernetes.io/managed-by":     "opm-test"
				"app.kubernetes.io/instance":       "istiod"
				"app.kubernetes.io/name":           "istiod"
				"module-instance.opmodel.dev/name": "istio"
			}
		}
		data: "log-level": "info"
	},
]
