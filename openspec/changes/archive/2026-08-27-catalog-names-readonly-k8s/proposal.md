## Why

Every passthrough transformer in `k8s/` declares the same line: `_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"`, and honours no override. Enhancement 0019 D19 extends the D15 read-only rule to this catalog: the principle is catalog-independent and the first downstream consumer of `k8s/` (an `openebs_zfs` storage module) needs override-honouring names on `StorageClass` and verbatim names on `CSIDriver`. This slice does the rewrite; the two missing kinds are `catalog-k8s-csi-resources`.

## What Changes

- 25 transformers replace the `_name` formula with `_name: #component.#names.resourceName`: `cluster_role`, `cluster_role_binding`, `configmap`, `cronjob`, `daemonset`, `deployment`, `hpa`, `ingress`, `ingressclass`, `job`, `mutating_webhook`, `namespace`, `networkpolicy`, `pdb`, `pod`, `pv`, `pvc`, `role`, `role_binding`, `secret`, `service`, `serviceaccount`, `statefulset`, `storageclass`, `validating_webhook`.
- Exact-name carve-outs re-enumerated for this catalog (D19) and left verbatim: `apiservice` (`<version>.<group>`), `object` (user-supplied segment; its `<instance>-<component>` prefix becomes `#names.resourceName`, and the now-dead `_instName`/`_compName` go), and, once it exists, `csidriver`. Unlike `opm/`, the raw `Namespace` kind renders the prefixed name today and stays in the sweep: it is not an exact kind in this catalog.
- `k8s/` has no in-file fixtures at all today. This change adds the first ones, scoped to what it asserts: a default-named uniform kind (deployment), storageclass default and override, apiservice override-ignored, and object; each with `#instance` on the component stub and interpolation-pinned names, modelled on `opm/transformers/service_transformer.cue`.
- 24 transformer doc comments say "with OPM context applied (name prefix, ...)"; they change to name the override-honouring read, and `INDEX.md` is regenerated.
- The `k8s/` catalog now honours `metadata.resourceName` for every non-exact kind, which is what the storage module needs and what the abstraction catalog already does.

No member schema changes; no `apiVersion` segment moves. `k8s/` never imports `opm/` (layering unchanged).

## Before / After

**Before**

```cue
// every k8s/transformers/*_transformer.cue except apiservice and object
#transform: {
	#component: _
	#context:   c.#TransformerContext
	_name: "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)"
	output: metadata: name: _name
}

// object_transformer.cue
name: "\(_instName)-\(_compName)-\(_userName)"
```

**After**

```cue
#transform: {
	#component: _
	#context:   c.#TransformerContext
	_name: #component.#names.resourceName // 0019 D15/D19: read, never derived
	output: metadata: name: _name
}

// object_transformer.cue
name: "\(#component.#names.resourceName)-\(_userName)"
```

## Impact

- **Rendered output:** byte-identical for default-named components (D16). A component with an explicit `metadata.resourceName` is now honoured by every non-exact kind; today it is silently ignored. Intended; no fleet module on `k8s@v1` sets it.
- **Kernel floor:** same as the `opm/` slices, `library` >= v1.0.0-alpha.14, because `#names` requires the component fill.
- **Release class:** `feat!:` on the `k8s` module (kernel floor is a contract change; advances the v1 alpha counter, no major crossing).
- **`modules` fleet (`v1` line consumers of `k8s@v1`), subscribing platforms, `cli` fixtures:** no authoring change; they pick up the kernel floor with the release.
- Relies on the alpha line of `catalogs/k8s@v1`: yes.

## Enhancement

`enhancements/0019` D19 (sweep extends to `catalogs/k8s`, carve-outs re-enumerated: apiservice, object, csidriver) and D15. `enhancement.yaml` declares D15 and D19. The `CSIDriver` and `VolumeSnapshotClass` members D19 adds are `catalog-k8s-csi-resources`.
