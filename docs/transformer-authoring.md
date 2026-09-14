# Authoring rules for transformers and provider adapters

**Status:** Permanent authoring rules, measured 2026-09-13 against CUE `v0.17.1` and the
shipped kernel during the `enhancements/0015` backup experiments
(`02-policy-and-command`). Every rule below cost a failed render or a failed platform
build before it was written down.

These apply to any `#ComponentTransformer`, in this catalog or in a provider catalog that
implements one of this catalog's `fulfilment: "provider"` contracts.

## 1. The per-volume selection key is `volume.opmodel.dev/name`

`#PVCTransformer` stamps every rendered PersistentVolumeClaim with

```cue
labels: #context.labels & {"volume.opmodel.dev/name": volumeName}
```

where `volumeName` is the component's **volume map key** — exactly what
`backup@v1alpha1`'s `volumes` field names.

**An adapter that backs up, snapshots or otherwise selects one of a component's volumes
MUST match on this label.** There is no other stable way to tell one of a component's PVCs
from another: the object name is `<instance>-<component>-<volume>`, which is a rendering
detail, not a contract.

## 2. Build label maps by comprehension; add keys to `labels`, never to `componentLabels`

`#context.componentLabels` is a **closed** struct. Unifying an extra key into it fails:

```cue
// WRONG — "field not allowed", surfaced only as an opaque transformer error at render
labels: #context.componentLabels & {"volume.opmodel.dev/name": volumeName}
```

`#context.labels` is open (it ends in `...`) and accepts an extra key by unification, which
is the form rule 1 uses. When you need to reshape a label map rather than add to it, build a
new struct by comprehension over the source map instead of unifying into it.

## 3. Validation inside a transformer is a unification, never `error()`

A transformer definition is evaluated **once at platform build time, with no component in
scope**. An `error()` fallback intended to reject a bad component therefore fires during that
evaluation and refuses *every platform that carries the catalog* — the catalog becomes
unusable, and the message names the platform, not the offending module.

```cue
// WRONG — fires at platform build, with no component present
_port: #component.spec.expose.port | error("expose.port is required")
```

Express the requirement as a constraint the value must satisfy, and let unification produce
the bottom at render time with the field named:

```cue
// RIGHT — bottom only when a real component fails the constraint
_port: #component.spec.expose.port & int & >0
```

## 4. Guard every field computed from the component on presence

The same single evaluation with no component means any field derived from `#component`
must tolerate its absence. An unguarded computation over component data fails the platform
build even when no module would ever hit it:

```cue
// WRONG — list.Max over an absent struct fails at platform build
_longest: list.Max([for _, v in #component.spec.backup.retention {v}])

// RIGHT — computed only when the source is actually there
if #component.spec.backup.retention != _|_ {
    _longest: list.Max([for _, v in #component.spec.backup.retention {v}])
}
```

This is the transformer-side counterpart of the blueprint rule in
`cue-guard-closedness-workaround.md`: there the guard must be hoisted out of `spec`, here
the guard must exist at all.

## 5. Quoting a module's shell line is the adapter's job

`backup-command@v1alpha1`'s `command` is "a shell line", with no restriction on which
characters it contains. An engine that wraps it in its own shell invocation (k8up's
`sh -c '...'`) must escape the line or use an exec form. The contract deliberately carries
no quote ban: banning one character in the contract only moves the breakage to the next one
and makes every module pay for one engine's wrapper.
