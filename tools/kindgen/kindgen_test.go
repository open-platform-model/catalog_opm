package main

import (
	"strings"
	"testing"
)

// A trimmed spec: the paths and operations scopes reads, nothing else.
const testSpec = `{
  "paths": {
    "/apis/apps/v1/deployments": {
      "get": {"x-kubernetes-group-version-kind": {"group": "apps", "version": "v1", "kind": "Deployment"}}
    },
    "/apis/apps/v1/namespaces/{namespace}/deployments": {
      "parameters": [{"name": "namespace"}],
      "post": {"x-kubernetes-group-version-kind": {"group": "apps", "version": "v1", "kind": "Deployment"}}
    },
    "/apis/apps/v1/namespaces/{namespace}/deployments/{name}/scale": {
      "get": {"x-kubernetes-group-version-kind": {"group": "autoscaling", "version": "v1", "kind": "Scale"}}
    },
    "/apis/apps/v1/namespaces/{namespace}/deployments/{name}/status": {
      "get": {"x-kubernetes-group-version-kind": {"group": "apps", "version": "v1", "kind": "Deployment"}}
    },
    "/api/v1/namespaces/{name}/status": {
      "get": {"x-kubernetes-group-version-kind": {"group": "", "version": "v1", "kind": "Namespace"}}
    },
    "/api/v1/namespaces": {
      "post": {"x-kubernetes-group-version-kind": {"group": "", "version": "v1", "kind": "Namespace"}}
    },
    "/apis/rbac.authorization.k8s.io/v1/clusterroles": {
      "get": {"x-kubernetes-group-version-kind": {"group": "rbac.authorization.k8s.io", "version": "v1", "kind": "ClusterRoleList"}},
      "post": {"x-kubernetes-group-version-kind": {"group": "rbac.authorization.k8s.io", "version": "v1", "kind": "ClusterRole"}}
    },
    "/api/v1/namespaces/{namespace}/pods/{name}/exec": {
      "post": {"x-kubernetes-action": "connect", "x-kubernetes-group-version-kind": {"group": "", "version": "v1", "kind": "PodExecOptions"}}
    },
    "/apis/coordination.k8s.io/v1/leases": {
      "get": {"x-kubernetes-group-version-kind": {"group": "coordination.k8s.io", "version": "v1", "kind": "Lease"}}
    }
  }
}`

func TestScopes(t *testing.T) {
	got, err := scopes([]byte(testSpec))
	if err != nil {
		t.Fatal(err)
	}
	want := map[gvk]string{
		// The cluster-wide list path does not make it Cluster.
		{"apps/v1", "Deployment"}: scopeNamespaced,
		// Served under /namespaces/{name}, not /namespaces/{namespace}/.
		{"v1", "Namespace"}:                             scopeCluster,
		{"rbac.authorization.k8s.io/v1", "ClusterRole"}: scopeCluster,
		// Only a cluster-wide list path in this spec: Cluster.
		{"coordination.k8s.io/v1", "Lease"}: scopeCluster,
	}
	if len(got) != len(want) {
		t.Errorf("got %d kinds %v, want %d", len(got), got, len(want))
	}
	for k, w := range want {
		if got[k] != w {
			t.Errorf("%s %s: got %q, want %q", k.apiVersion, k.kind, got[k], w)
		}
	}
	// Only a /scale subresource serves Scale, and only a connect operation
	// PodExecOptions; both are ignored.
	for _, k := range []gvk{{"autoscaling/v1", "Scale"}, {"v1", "PodExecOptions"}} {
		if s, ok := got[k]; ok {
			t.Errorf("%s %s: got %q, want it absent", k.apiVersion, k.kind, s)
		}
	}
}

func TestScopesPathOrderIndependent(t *testing.T) {
	// Map iteration order varies; the namespaced path must win every time.
	for range 20 {
		got, err := scopes([]byte(testSpec))
		if err != nil {
			t.Fatal(err)
		}
		if got[gvk{"apps/v1", "Deployment"}] != scopeNamespaced {
			t.Fatalf("apps/v1 Deployment: got %q", got[gvk{"apps/v1", "Deployment"}])
		}
	}
}

func TestRender(t *testing.T) {
	defs := map[gvk]def{
		{"apps/v1", "Deployment"}: {importPath: "cue.dev/x/k8s.io/api/apps/v1", name: "#Deployment"},
		{"v1", "Status"}:          {importPath: "cue.dev/x/k8s.io/apimachinery/pkg/apis/meta/v1", name: "#Status"},
	}
	scope := map[gvk]string{
		{"apps/v1", "Deployment"}:                               scopeNamespaced,
		{"certificates.k8s.io/v1", "CertificateSigningRequest"}: scopeCluster,
	}
	src, err := render(join(defs, scope), "v0.12.0", "v1.36.0")
	if err != nil {
		t.Fatal(err)
	}
	s := string(src)
	for _, want := range []string{
		"cue.dev/x/k8s.io v0.12.0",
		"Kubernetes v1.36.0",
		`apps_v1 "cue.dev/x/k8s.io/api/apps/v1"`,
		`meta_v1 "cue.dev/x/k8s.io/apimachinery/pkg/apis/meta/v1"`,
		`Deployment: {schema: apps_v1.#Deployment, scope: "Namespaced"}`,
		`CertificateSigningRequest: {scope: "Cluster"}`,
		`Status: {schema: meta_v1.#Status}`,
	} {
		if !strings.Contains(s, want) {
			t.Errorf("table lacks %q:\n%s", want, s)
		}
	}
	// Sorted by apiVersion: the core group "v1" sorts last.
	if a, c := strings.Index(s, `"apps/v1"`), strings.Index(s, `"v1": {`); a < 0 || c < a {
		t.Errorf("group-versions out of order:\n%s", s)
	}
}

func TestAliasCollision(t *testing.T) {
	defs := map[gvk]def{
		{"a/v1", "A"}: {importPath: "cue.dev/x/k8s.io/api/x/v1", name: "#A"},
		{"b/v1", "B"}: {importPath: "cue.dev/x/k8s.io/other/x/v1", name: "#B"},
	}
	if _, err := render(join(defs, nil), "v0.12.0", "v1.36.0"); err == nil || !strings.Contains(err.Error(), "import alias x_v1") {
		t.Fatalf("err = %v, want an alias collision", err)
	}
}
