package v1beta1

import (
	id "opmodel.dev/catalogs/opm/identity"
	c "opmodel.dev/core@v2"
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

// Gateway API gRPC routing rules for a workload. Renders a GRPCRoute when the
// component also attaches the expose trait.
#GrpcRouteTrait: c.#Trait & {
	metadata: {
		modulePath:     "\(id.kindPrefix.traits)/v1beta1"
		name:           "grpc-route"
		apiVersion:     "v1beta1"
		catalogVersion: id.Version
		fqn:            "\(id.kindPrefix.traits)/grpc-route@v1beta1"
		description:    "Gateway API gRPC routing rules for a workload"
		labels: {
			"trait.opmodel.dev/category": "network"
		}
	}

	// Advisory posture (0010 D46): a workload without this trait still
	// renders; a module may narrow the default at the attachment site.
	optional: bool | *true

	appliesTo: [res.#ContainerResource]

	spec: grpcRoute: #GrpcRouteSchema
}

#GrpcRoute: c.#Component & {
	#traits: (#GrpcRouteTrait.metadata.fqn): #GrpcRouteTrait
}

#GrpcRouteMatchSchema: {
	service?: string
	method?:  string
	headers?: [...#RouteHeaderMatch]
}

#GrpcRouteRuleSchema: #RouteRuleBase & {
	matches?: [...#GrpcRouteMatchSchema]
}

#GrpcRouteSchema: #RouteAttachmentSchema & {
	hostnames?: [...string]
	rules: [#GrpcRouteRuleSchema, ...#GrpcRouteRuleSchema]
}
