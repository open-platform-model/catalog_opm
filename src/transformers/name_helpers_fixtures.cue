@if(fixtures)

package transformers

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

// Legacy shape: a component compiled against a build <= alpha.5, whose
// #ExposeSchema carried `name?: string` and whose wrapper set no default.
// Hand-built on purpose (embedding the current trait gives `name!`); #names
// is set as core would derive it.
_testServiceNameLegacy: (#ServiceName & {
	#comp: {
		#names: dns: short: "shop-web"
		spec: expose: {
			type: "ClusterIP"
			ports: http: {name: "http", targetPort: 8080, protocol: "TCP"}
			name?: string
		}
	}
}).out

_testServiceNameLegacyResolves: "\(_testServiceNameLegacy)" & "shop-web"

// Exact name wins over the component's own name.
_testServiceNameExact: (#ServiceName & {
	#comp: {
		#names: dns: short: "istio-istiod"
		spec: expose: {
			name: "istiod"
			type: "ClusterIP"
			ports: "https-dns": {name: "https-dns", targetPort: 15012, protocol: "TCP"}
		}
	}
}).out

_testServiceNameExactResolves: "\(_testServiceNameExact)" & "istiod"
