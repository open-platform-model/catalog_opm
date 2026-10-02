package main

import (
	"encoding/json"
	"strings"
)

// Scopes, as the table and the objects resource spell them.
const (
	scopeNamespaced = "Namespaced"
	scopeCluster    = "Cluster"
)

// gvk names a kind the way an object does: apiVersion ("v1" for the core
// group, "<group>/<version>" otherwise) and kind.
type gvk struct{ apiVersion, kind string }

// swaggerDoc is the part of a Kubernetes OpenAPI v2 spec scopes reads.
type swaggerDoc struct {
	Paths map[string]map[string]json.RawMessage `json:"paths"`
}

type swaggerOp struct {
	Action string `json:"x-kubernetes-action"`
	GVK    *struct {
		Group   string `json:"group"`
		Version string `json:"version"`
		Kind    string `json:"kind"`
	} `json:"x-kubernetes-group-version-kind"`
}

// scopes reads every kind the spec serves and its scope. A kind is
// Namespaced when any operation on a path containing /namespaces/{namespace}/
// carries it, and Cluster otherwise: a namespaced kind is also listed
// cluster-wide (/apis/apps/v1/deployments), so the namespaced path wins.
// Operations on /status and /scale subresources are ignored, because the
// latter carry the autoscaling/v1 Scale kind under every scalable resource,
// and so are connect operations (exec, attach, proxy), whose *Options kinds
// are request parameters. A kind ending in List is not an object either.
func scopes(spec []byte) (map[gvk]string, error) {
	var doc swaggerDoc
	if err := json.Unmarshal(spec, &doc); err != nil {
		return nil, err
	}
	out := map[gvk]string{}
	for path, item := range doc.Paths {
		if strings.HasSuffix(path, "/status") || strings.HasSuffix(path, "/scale") {
			continue
		}
		namespaced := strings.Contains(path, "/namespaces/{namespace}/")
		for _, raw := range item {
			var op swaggerOp
			// Path items also hold "parameters", an array: not an operation.
			if json.Unmarshal(raw, &op) != nil || op.GVK == nil || op.Action == "connect" {
				continue
			}
			if strings.HasSuffix(op.GVK.Kind, "List") {
				continue
			}
			k := gvk{apiVersion: op.GVK.Version, kind: op.GVK.Kind}
			if op.GVK.Group != "" {
				k.apiVersion = op.GVK.Group + "/" + op.GVK.Version
			}
			if namespaced {
				out[k] = scopeNamespaced
			} else if _, seen := out[k]; !seen {
				out[k] = scopeCluster
			}
		}
	}
	return out, nil
}
