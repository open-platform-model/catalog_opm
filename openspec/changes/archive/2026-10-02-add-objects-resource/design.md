## Context

`opm` already depends on `cue.dev/x/k8s.io` v0.12.0 (`opm/cue.mod/module.cue`) and re-exports parts of it under `opm/schemas/kubernetes/`. Every top-level kind definition in that module carries concrete `"apiVersion"` and `"kind"` fields and is closed, because it is a CUE definition. The module ships no index from `apiVersion` + `kind` to definition, and it records no resource scope (namespaced or cluster).

Files this change adds, all in the `opm` module:

| File | Package | What |
| --- | --- | --- |
| `opm/resources/v1alpha1/objects.cue` | `v1alpha1` | `#ObjectsResource`, `#Objects`, `#ObjectSchema` |
| `opm/schemas/kinds/table.cue` | `kinds` | generated `#Table` |
| `opm/schemas/kinds/check.cue` | `kinds` | hand-written self-consistency assertion |
| `opm/transformers/objects_transformer.cue` | `transformers` | `#ObjectsTransformer` and its fixtures |
| `opm/catalog.cue` | `opm` | two listing entries |
| `tools/kindgen/` | Go module | the table generator |

No existing member changes, so no closedness, default or required-field set moves.

## Goals / Non-Goals

**Goals:**
- One resource that renders a map of Kubernetes objects one-to-one, as written.
- Validation of every built-in kind against its upstream definition, with no work from the module author.
- Custom resources pass through, with the author stating only their scope.

**Non-Goals:**
- Validating custom resources. An author MAY unify an entry with a schema they import themselves (`cue.dev/x/crd/cert-manager.io`); the catalog ships none.
- Validating values beyond structure and type. x/k8s.io carries no enums (`imagePullPolicy: "Sometimes"` passes) and types a quantity as `number | string`.
- A per-object opt-out of validation, and any Kubernetes newer than the one x/k8s.io v0.12.0 is generated from, 1.36 (owner decision, 2026-10-02, which named it 1.34; see Research & Decisions, "Which Kubernetes x/k8s.io v0.12.0 tracks").
- Platform control over which kinds a module may render. `#Platform` does not decide what may be deployed (owner decision, 2026-10-02).

## Decisions

### D1. One resource; each map value is the bare object

```cue
spec: objects: [Key=string]: #ObjectSchema & {metadata: name: string | *Key}
```

The value is the Kubernetes object itself, not a `{scope, object}` wrapper as in the k8s catalog's `#ObjectsResource`. The one OPM-only input, scope, is a definition field on the object (D3), which export never writes out. The `Key` alias MUST NOT be `name` (it would shadow the inner field; see `opm/resources/v1alpha1/namespace.cue`).

### D2. Dispatch on `apiVersion` + `kind`

```cue
#ObjectSchema: X={
	apiVersion!: string
	kind!:       string
	metadata: name: string
	#scope: "Namespaced" | "Cluster"
	...
	[
		if kinds.#Table[X.apiVersion][X.kind] != _|_ {
			let E = kinds.#Table[X.apiVersion][X.kind]
			[if E.schema != _|_ {E.schema}, {}][0]
			if E.scope != _|_ {#scope: E.scope}
		},
		if _builtinGroups[_group(X.apiVersion)] != _|_ {
			// refused: unknown kind in a built-in API group
		},
		{},
	][0]
}
```

- A kind in the table with a schema is closed by that definition. An unknown field fails as `field not allowed`, naming its path.
- A kind in the table without a schema (in the OpenAPI spec but not in x/k8s.io: none against v1.36.0) is open, with its scope known.
- A kind absent from the table whose group is a built-in group (any group the table names, `""` for `v1`) is refused. Without this, `apps/v2` would fall through to the open arm and skip validation silently.
- Anything else is open.

The refusal's spelling is settled in section 3 (Risks, "error() in a schema"). The list-index form (`[...][0]`) is the catalog's idiom for picking a concrete arm without a default (`docs/name-constraints.md`).

### D3. Scope: the table for built-in kinds, `#scope` for the rest

The generator reads scope from the Kubernetes v1.36.0 OpenAPI spec, the release x/k8s.io v0.12.0 is generated from: a kind served under a `/namespaces/{namespace}/` path is `Namespaced`, otherwise `Cluster` (97 kinds, 52 cluster-scoped). For a table kind, `#scope` is unified with the table's value, so a wrong `#scope` conflicts. For any other kind, `#scope` is required.

`#scope` is a definition field, not a hidden one (`_scope`), because hidden fields are package-scoped: the transformer, in another package, could not read a module's `_scope`.

### D4. Name, namespace, labels, annotations

| Field | Rendered |
| --- | --- |
| `metadata.name` | as written; defaults to the map key; never prefixed |
| `metadata.namespace` | as written when set; otherwise the instance namespace for a `Namespaced` object; refused for a `Cluster` object |
| `metadata.labels` | the render context's labels, then the object's (the object wins on a conflict) |
| `metadata.annotations` and every other field | as written |

Names are as written so references inside raw objects hold. The cost is that two instances of one module in one namespace collide unless the author puts the instance name into each name; the kernel's duplicate-identity refusal names the clash. This is the same carve-out `#NamespacesResource` makes for externally referenced names (AGENTS.md, Naming), and `#nameConstraint` stays top: the rendered names are the map entries, not the component's `resourceName`.

### D5. Transformer

`#ObjectsTransformer` requires only `objects@v1alpha1`, emits a list (one object per entry, ListKind), and copies every field except `metadata` by comprehension, so `#scope` (a definition) is never emitted. It declares no `producesKinds`: the kinds are the author's.

The resource MAY be attached to a component beside other resources (a `#Container` workload plus a ServiceMonitor). Its transformer matches on the resource alone and renders independently of the others.

### D6. Placement: `v1alpha1`

The member starts at `v1alpha1` (0010 D34): an x/k8s.io bump can add kinds to the table and so tighten validation of objects that passed open before. Alpha promises nothing, which is the honest promise for a member whose validation follows upstream.

### D7. The table is generated, and checked in CUE

`tools/kindgen` (Go, `cuelang.org/go` v0.17.1, its own `go.mod` like `tools/refgen`) loads every package of the pinned `cue.dev/x/k8s.io`, keeps each definition whose `apiVersion` and `kind` are concrete and whose kind does not end in `List`, joins the scope from the OpenAPI spec of the Kubernetes tag the x/k8s.io version tracks, and writes `opm/schemas/kinds/table.cue` sorted. It is a maintainer tool run on an x/k8s.io bump (`task generate:kinds`); CI does not run it, so CI needs no network beyond the registry; CI runs only its unit tests (`task test:kindgen`, offline), beside `tools/refgen`'s.

What CI does check, through `cue vet`, is `check.cue`: for every table entry with a schema, the schema's `apiVersion` and `kind` equal the entry's keys. A hand edit that files a definition under the wrong key fails vet.

## Research & Decisions

### Does x/k8s.io validate, and at what cost?
**Context**: The design rests on x/k8s.io definitions being closed, dispatchable and cheap.
**Explored**: Scratch module, cue v0.17.1, x/k8s.io v0.12.0. A map of 83 kinds and 120 objects (60 Deployments, 60 Services) vetted in 0.08 s and 45 MB. `replica`, `imagePullPolicyy` refused as `field not allowed`; `port: "eighty"` refused as a type conflict; `imagePullPolicy: "Sometimes"` accepted.
**Decision**: Dispatch to the upstream definitions (D2).
**Rationale**: Closed, concrete-keyed and cheap; values beyond type are out of reach and out of scope.

### Does it hold inside `core`'s `#Resource` and `#Component`?
**Context**: The catalog's definitions are closed and the transformer reads the component across packages.
**Explored**: A scratch copy of `opm/` with the resource, a 100-kind table (with scope) and the transformer (2026-10-02). `cue vet ./...` on the whole module: green, 0.4 s. A fixture rendered a Deployment (instance namespace, from the table), a ClusterRole (no namespace) and a ClusterIssuer (`#scope: "Cluster"`, no namespace), all named by their keys, `#scope` absent from the output. Refused: `spec.replica` (`field not allowed`), `apps/v2` Deployment (built-in group), an Issuer without `#scope` (`unresolved disjunction`), `#scope: "Cluster"` on a Deployment (conflict). Accepted, wrongly: a ClusterRole with `metadata.namespace` (D4 adds the refusal).
**Decision**: Keep the shape; fix the two messages and the missing refusal in section 3.
**Rationale**: Every behaviour D1 to D5 needs was measured; only the refusal wording is open.

### Scope source
**Context**: x/k8s.io records no scope.
**Explored**: `api/openapi-spec/swagger.json` at Kubernetes `v1.34.0`: 90 kinds with a GroupVersionKind on a create, get or replace operation; 49 cluster-scoped. Four of them are missing from x/k8s.io v0.12.0 (`CertificateSigningRequest`, `PodCertificateRequest`, `VolumeAttributesClass` at `v1alpha1`, `StorageVersionMigration`); 14 x/k8s.io kinds (alpha APIs) are missing from the spec.
**Decision**: Table = union of both. A kind with no scope in the spec requires `#scope` from the author.
**Rationale**: The served paths are the authority on scope; the union keeps a valid built-in kind from tripping the built-in-group refusal.

### Which Kubernetes x/k8s.io v0.12.0 tracks (section 2)
**Context**: The Scope source measurement above joined the v1.34.0 spec, assuming x/k8s.io v0.12.0 tracks 1.34. Its four "missing" kinds and fourteen one-sided alpha kinds suggested otherwise.
**Explored**: `tools/kindgen` (Go loader, not the earlier regex script, which missed `CertificateSigningRequest` because of the aligned `"kind":` spacing) against the v1.34.0, v1.35.0, v1.36.0 and v1.37.0 specs. x/k8s.io v0.12.0 carries `admissionregistration.k8s.io/v1` MutatingAdmissionPolicy, `scheduling.k8s.io/v1alpha2` Workload and PodGroup and `storagemigration.k8s.io/v1beta1`, which v1.34.0 does not serve, and lacks the v1.37.0 additions (`scheduling.k8s.io/v1beta1`, `storagemigration.k8s.io/v1`). Against v1.36.0 the join is exact: every object kind has both a schema and a scope; only `autoscaling/v1` Scale, `v1` APIGroup, APIVersions and Status (not served as objects) have no scope, and no served kind lacks a definition. Connect operations (`pods/{name}/exec` and the like) carry `*Options` request kinds; kindgen ignores them, as it ignores `/status` and `/scale`.
**Decision**: Join the v1.36.0 spec (`KUBERNETES_VERSION` in `Taskfile.yml`). The table holds 101 kinds over 36 group-versions, 97 with a scope (52 `Cluster`). The validation ceiling is therefore Kubernetes 1.36, not 1.34: the owner decision fixed x/k8s.io v0.12.0 as the validator, and 1.34 was a mislabel of it.
**Rationale**: D7 already names the spec "of the Kubernetes tag the x/k8s.io version tracks"; the one-sided sets kindgen prints are the evidence for the tag, and they are empty only at v1.36.0.

### Does the kernel carry `#scope`, and does a platform build stay green? (section 1 spike)
**Context**: Two Risks below: the render might drop the definition field `#scope` before the transformer reads it, and the built-in-group refusal (an `error()` in the schema) might fire when a platform is built with no objects component.
**Explored**: 2026-10-02, the cli at `db4f9fd` (CUE v0.17.1) built from source; a scratch copy of `opm/` at `e446980` with the resource, the transformer and a two-kind table (Deployment, ClusterRole), served to a scratch module through `cue.mod/local-module.cue`. `opm module build -n apps` (no `--platform`, so against the generated module-deps platform) rendered the scratch module's `#Objects` component beside a `#StatelessWorkload`: the Deployment (scope from the table) and an Issuer with `#scope: "Namespaced"` carried `namespace: apps`; a ClusterIssuer with `#scope: "Cluster"` carried none; no output carried `scope`. Refusals through the same build: `spec.replica` as `field not allowed` naming `values.#components.extras.spec.objects.web.spec.replica`; `apps/v2` Deployment as the `error()` message; an Issuer without `#scope` only at transform time, as `output is not concrete: ... unresolved disjunction "Namespaced" | "Cluster"`. With the objects component removed, the same build rendered the workload alone, and `opm platform check` on the generated platform directory exited 0, listing `objects@v1alpha1` as implemented by `objects-transformer`.
**Decision**: Keep D2 and D3 as designed; neither fallback is needed.
**Rationale**: The kernel hands the transformer the component's definition fields, and the `error()` sits in a pattern constraint that is never instantiated without a concrete entry. The missing-`#scope` message is the one section 3 must improve.

### Refusal spellings and closedness (section 3)
**Context**: Task 3.2: refuse `metadata.namespace` on a `Cluster` object, and pick the clearest spelling for the built-in-group refusal and a missing `#scope` that still holds under a platform build.
**Explored**: 2026-10-02, cue v0.17.1, each case unified with `#ObjectsResource.spec.objects` and exported, then rendered through `opm module build` against a local replacement of the worktree. Findings:
- The prototype's top-level `...` reopened the embedded closed schema: a Deployment with `specc: {}` was accepted. Embedding a closed definition into a struct that has `...` reopens it, at the top level and in `metadata` alike. `...` now appears only in the open arms (custom kinds, and a table kind with no schema), so `specc` and `metadata.labelz` on a built-in kind are refused as `field not allowed`.
- A missing `#scope` as the prototype's bare disjunction surfaced only at transform time (`output is not concrete ... unresolved disjunction`). An `error()` in the arm reads `cert-manager.io/v1 Issuer is not a Kubernetes 1.36 object kind: set #scope to "Namespaced" or "Cluster"`, at the entry's path. The guard must hold only for a concrete `apiVersion` and `kind` (`x != _|_` is false for a non-concrete `x`); unguarded, the open arm, which the bare definition selects, fired at `cue vet`.
- Namespace refusal: a comprehension testing `X.metadata.namespace != _|_` worked at export but made every valid cluster-scoped built-in object read as bottom to a `!= _|_` test. An optional field holding the error, `metadata: namespace?: error(...)`, does not, and names the field: `...metadata.namespace: rbac.authorization.k8s.io/v1 ClusterRole is cluster-scoped: remove metadata.namespace`.
- A table-scope `#scope` embedded through a nested list index was silently dropped (a wrong `#scope` on a Deployment passed); a plain `if` comprehension in the arm keeps it, and the conflict reads `#scope: conflicting values "Namespaced" and "Cluster"`.
- The built-in-group refusal keeps the `error()` form: `apps/v2 Deployment is not a Kubernetes 1.36 kind, and its API group is built in: check apiVersion and kind`.
**Decision**: The spellings above, pinned by `_testObjectsRefused` and its valid twins `_testObjectsAccepted` in `objects_transformer.cue`. Re-measured through the kernel: every message reaches the render error at `values.#components.<c>.spec.objects.<key>`; with no objects component the render and `opm platform check` stay green.
**Rationale**: Each refusal names the entry and says what to change; the missing required `apiVersion` or `kind` falls through to CUE's own `field is required but not present`.

## Risks / Trade-offs

- [The kernel does not carry the definition field `#scope` through to the transformer] → Section 1 renders a fixture module through `opm module build` against a local replacement of this catalog before any member lands. If `#scope` is lost, the fallback is a regular field the transformer strips, decided before section 2.
- [`error()` in a schema fires at platform build] → `docs/transformer-authoring.md` §3 forbids `error()` in a transformer, because a transformer is evaluated with no component. The refusal here sits in a pattern constraint that applies only to a concrete entry; section 1 also builds a platform carrying the catalog with no objects component and asserts it stays green. If it does not, the refusal becomes a unification on a named field.
- [An x/k8s.io bump tightens validation] → Accepted at `v1alpha1` (D6). The bump's PR names the kinds the regenerated table adds.
- [x/k8s.io is experimental (`cue.dev/x/`)] → The catalog already depends on it; a breaking upstream change shows up as a vet failure on the bump PR, not in a module.
- [Refusal messages are hard to read] → An Issuer without `#scope` reads `unresolved disjunction "Namespaced" | "Cluster"`. Section 3 measures alternatives and pins the clearest in a fixture.
- [Name collisions between instances] → The author's responsibility (D4); the doc comment and the authoring page say so.

## Durable decisions

- Names as written, the carve-out from `#component.#names.resourceName` for this resource: lands in `docs/name-constraints.md` beside the `#NamespacesResource` row, and in the AGENTS.md Naming bullet's list of carve-outs.
- Regenerating the kind table on an x/k8s.io bump (`task generate:kinds`, which Kubernetes tag, what the PR must name): lands in AGENTS.md under Dependencies.
- A definition field (`#scope`), not a hidden one, for OPM-only input a transformer in another package must read: lands in `docs/transformer-authoring.md` as a new section.
