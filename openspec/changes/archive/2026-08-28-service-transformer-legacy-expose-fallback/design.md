## Context

See proposal.md. File touched: `opm/transformers/service_transformer.cue` (transformer, no apiVersion segment). `#transform` takes `#component: _`, so a fixture may hand it a shape no current schema produces, which is exactly what a ≤ alpha.5 component is at render time: the kernel fills `#component` with the module's own evaluated value (library `compile/execute.go`, 0019 D1), and that value's `expose` came from the wrapper of the build the module pinned. `#names` is core's (`core/src/component.cue`, since core alpha.4), derived from `metadata.resourceName` and `#instance`, so it is present on every core-v2 component regardless of the catalog build. The existing `#WorkloadName` helper (`name_helpers.cue`) already uses the list-index "explicit else `#names`" form and documents why.

## Goals / Non-Goals

**Goals:** a ≤ alpha.5 component renders its Service with the name a ≥ alpha.6 build would have defaulted; nothing else in the output changes.
**Non-Goals:** reopening `name!` on the schema; supporting components compiled against core < alpha.4 (no `#names`); the compat gate (library `compat-field-made-required`) and its prerelease exemption (cli).

## Decisions

**D1. Fallback in the transformer, list-index form.**
```cue
name: [
	if _expose.name != _|_ {_expose.name},
	#component.#names.dns.short,
][0]
```
Alternatives: (a) `_expose.name | *#component.#names.dns.short`: rejected, the default arm wins over a concrete value (the bug documented at lines 61-68 of this file and in `name_helpers.cue`). (b) `*_expose.name | #names.dns.short`: rejected, `_expose.name` is bottom-ish (optional, unset) on the legacy shape and a bottom default arm does not fall through cleanly on cue v0.17.1. (c) Move `#ExposeSchema.name` back to optional: rejected, it reverts 0019 D22 and the vet-time refusal of unnamed Services for new builds.

Closedness, defaults and the required-field set of every member are unchanged; only the transformer's read changes.

**D2. Legacy fixture is hand-built, not schema-derived.** Embedding `tr.#Expose` or `tr.#ExposeTrait` would give `name!` and cannot express "optional and unset" in the current package. The fixture writes `expose: {…, name?: string}` and `#names: dns: short:` directly; the transformer sees exactly what the kernel would hand it for an alpha.3-pinned module (measured: `cue def -e '#components.web.spec.expose'` on `cli/tests/integration/module-apply/testdata` shows `name?: string`).

**D3. Resolution guard, not a golden.** Same reasoning as the UDP/port guards at lines 320-333: a golden unifies and would repair a wrong value; `"\(name)" & "shop-web"` fails loudly. Also assert the default-name and exact-name fixtures still resolve (they do; unchanged path).

**D4. Correct the "No fallback: there is no path on which the field is unset" comment.** It is true for the wrapper and false for the render path; the replacement comment names the D27 reason.

**D5. One seam, `#ServiceName` in `name_helpers.cue`.** Same shape and rationale as `#WorkloadName`: `(#ServiceName & {#comp: #component}).out`, list-index form, `#comp.spec.expose.name` when set else `#comp.#names.dns.short`. The Service transformer's D1 expression moves into it. Six call sites: `service_transformer.cue` (`metadata.name`), `statefulset_transformer.cue` (`serviceName`, keeping its outer `if #component.spec.expose != _|_` arm since a stateful component may have no Expose), and `_backendName` in the four route transformers. Alternative: five inline copies of D1. Rejected: the StatefulSet `serviceName` and each `backendRef` are cross-object references to the Service (0019 D22, `docs/name-constraints.md` § carve-out 3) and must be byte-identical to what the Service transformer emits; two copies are two chances to drift, and the failure (a headless Service or backend that does not exist) is silent. The helper is also where the next posture change gets its fallback, once.

**D6. Fixture coverage per file, not per reader.** A legacy fixture where a file has its own rendered value to pin: `_testServiceNameLegacy` on the helper (the seam), `_testSTSLegacyExpose*` in the StatefulSet file (guard on `spec.serviceName`), `_testHttpRouteLegacyExpose*` in the http route file with the existing cross-reference guard shape (`backendRefs[0].name` against `#ServiceTransformer` output for the same stub). grpc/tcp/tls call the same helper through an identical `_backendName` line and are covered by the helper guard; a fixture each would be three copies asserting one expression. The StatefulSet legacy stub mirrors alpha.5's `#StatefulWorkload` shape: `expose` with `name?: string` unset, `#names: {dns: short:, resourceName:}` hand-set, `workload-type: stateful` label.

**D7. The StatefulSet WHY comment (lines 144-149) is rewritten.** "expose.name is required on the schema (0019 D22), so no inner guard" is the same false statement D4 removes from the Service transformer; the helper carries the guard now.

## Research & Decisions

### Where the "optional" comes from
**Context**: the error names an optional field no current schema declares.
**Explored**: 2026-08-28: the published artifacts alpha.2 … alpha.5 all carry `#ExposeSchema.name?: string` (git tags differ from what was published); alpha.6+ carry `name!`. The kernel fills `#component` with the module's own value, so an alpha.3-pinned module hands the alpha.7 transformer `name?: string`. Same module re-pinned to alpha.7 renders on alpha.7; on an alpha.3 platform the alpha.3 transformer (which had the fallback) renders it too.
**Decision**: restore the fallback in the transformer.
**Rationale**: it is the D27-conformant fix, one expression, and `#names.dns.short` is by construction the value the wrapper would have defaulted.

### Why `#names.dns.short` and not `<instance>-<component>` string interpolation (the alpha.5 fallback)
**Context**: alpha.5 interpolated `#moduleInstanceMetadata.name` and `#component.metadata.name`.
**Explored**: `#names.dns.short` = `metadata.resourceName`, which core defaults to the instance-scoped name and which honours a `resourceName` override; the interpolation ignores the override.
**Decision**: `#names.dns.short`.
**Rationale**: identical to the wrapper's default, so new and legacy components agree.

## Risks / Trade-offs

- [A legacy component whose core is < alpha.4 has no `#names`; the fallback is then bottom] → same failure as today, one field later; out of D27's promise (core is a separate contract) and no such module exists in the workspace.
- [The comment at lines 92-97 is copied by the next transformer author] → D4 rewrites it; the docs rule covers the pattern.

## Durable decisions

- "A transformer that reads a field whose posture changed within an `apiVersion` (optional → required, or a moved default) MUST keep a fallback for components compiled against earlier builds of that `apiVersion`, and MUST pin it with a `_test*Legacy*` fixture carrying the earlier shape (0010 D27)" → `docs/name-constraints.md`, new section "Reading fields across builds".
- "Legacy-shape fixtures are hand-built structs handed to `#transform` directly; they never embed the current trait" → same section.
- "A cross-object reference to the Service (StatefulSet `serviceName`, route `backendRefs`) reads the name through `#ServiceName`, never through its own `expose.name` read" → `docs/name-constraints.md` § carve-out 3 (the `#WorkloadName` sentence gets a sibling).
