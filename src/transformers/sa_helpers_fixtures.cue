@if(fixtures)

package transformers

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testToK8sServiceAccount: (#ToK8sServiceAccount & {
	"in": {
		name:           "ci-bot"
		automountToken: false
	}
	context: {
		namespace: "ci"
		labels: app: "ci-bot"
		componentAnnotations: {}
	}
}).out
