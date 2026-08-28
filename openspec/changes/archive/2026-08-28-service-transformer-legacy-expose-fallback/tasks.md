## 1. opm/transformers/service_transformer.cue

- [x] 1.1 Replace `name: _expose.name` with the list-index fallback (design D1) and rewrite the comment above it (design D4).
- [x] 1.2 Add `_testServiceLegacyExposeComponent` (≤ alpha.5 shape: `expose.name?: string` unset, `#names.dns.short` hand-set), `_testServiceLegacyExposeTransformer` and the resolution guard `_testServiceLegacyExposeResolves` (design D2, D3). Confirm the guard fails on the unmodified transformer before applying 1.1.
- [x] 1.3 Confirm the existing default-name, exact-name and UDP guards still resolve.

## 1b. One seam for every Service-name reader (design D5-D7)

- [x] 1b.1 `opm/transformers/name_helpers.cue`: add `#ServiceName` (`#comp!: _`, `out:` list-index of `#comp.spec.expose.name` else `#comp.#names.dns.short`) with a WHY block and a 6-line doc comment; add `_testServiceNameLegacy` (legacy stub, guard `"\(out)" & "shop-web"`) and `_testServiceNameExact` (`expose.name: "istiod"` wins).
- [x] 1b.2 `service_transformer.cue`: `metadata.name: (#ServiceName & {#comp: #component}).out`; keep the D4 comment, pointing at the helper. Existing and legacy guards still resolve.
- [x] 1b.3 `statefulset_transformer.cue:155-158`: `serviceName: [if #component.spec.expose != _|_ {(#ServiceName & {#comp: #component}).out}, #component.#names.dns.short][0]`; rewrite the WHY comment (D7). Add `_testSTSLegacyExposeComponent` / `Transformer` / `ServiceName` guard (`"shop-db"`). Confirm `_testSTSDefaultServiceName`, `_testSTSExactServiceName`, `_testSTSNoExposeServiceName` still resolve under `cue eval -c`.
- [x] 1b.4 `http_route_transformer.cue:47`, `grpc_route_transformer.cue:46`, `tcp_route_transformer.cue:46`, `tls_route_transformer.cue:46`: `_backendName: (#ServiceName & {#comp: #component}).out`. Add `_testHttpRouteLegacyExpose*` with the cross-reference guard against `#ServiceTransformer` output for the same stub. Confirm the four existing `*BackendResolves` guards still resolve.
- [x] 1b.5 Before 1b.1-1b.4, measure the refusal on the unmodified tree for the STS and http legacy stubs (`cue eval -c`), and record the verbatim error in the tasks note here.
  - 2026-08-28, unmodified tree: `_scratchSTSOut.spec.serviceName: invalid interpolation: cannot reference optional field: name` (`statefulset_transformer.cue:155:63`); `_scratchHttpOut.spec.rules.0.backendRefs.0.name: invalid interpolation: cannot reference optional field: name` (`http_route_transformer.cue:47:40`).

## 2. Durable decisions

- [x] 2.1 `docs/name-constraints.md`: add "Reading fields across builds" with the two rules from design.md § Durable decisions.
- [x] 2.2 `docs/name-constraints.md` § carve-out 3: cross-object references read the Service name through `#ServiceName` (third durable decision); mention the helper in the "Reading fields across builds" section.

## 3. Enhancement declaration

- [x] 3.1 Create `enhancement.yaml` declaring `implements: [{enhancement: "0010", decisions: [D27]}, {enhancement: "0019", decisions: [D22]}]`.

## 4. Verification

- [x] 4.1 `task check` (fmt, vet, layering, INDEX, doc-comment limit; `opm/INDEX.md` gains the one `#ServiceName` row from D5).
- [ ] 4.2 From the workspace: `opm module build cli/tests/integration/module-apply/testdata --name itest -n default --platform <platform pinned to a local -dev build of this branch>` renders a Service named `itest-web`; the same against alpha.7 still refuses (control).
  - 2026-08-28: not run as written; a `-dev` build needs a local-registry publish (Registry Policy rule 2, user-initiated only). Publish-free equivalent measured instead: the testdata `web` component as alpha.3 evaluates it (`expose.name?: string` unset, `protocol: "TCP"` defaulted), handed to this branch's `#transform` with `#names.dns.short: "itest-web"`, renders `metadata.name: "itest-web"`; the same input on the unmodified transformer refuses with `cannot reference optional field: name` (`cue eval -c`). Control against published alpha.7 is the proposal's own measurement.
- [x] 4.3 `opm catalog publish ./opm --dry-run`: only refusal is already-published.
