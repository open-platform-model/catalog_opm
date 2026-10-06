## Why

The Kubernetes controller `opm-operator` is renamed `opm-controller` (repo, image, namespace, CUE module,
CLI noun; enhancement 0032, "The Operator Becomes the Controller", 0032:D1). The
owner decided there is no migration and no trace of the old name: every live reference follows. This
catalog names the controller in six places, all comments or prose.

## What Changes

- **`src/transformers/transformer_registration_transformer.cue`**: the WHY block above the GVK literals
  says the CRD is owned by `opm-controller` (citing 0015:D3) and that the controller's
  `TransformerRegistration` CRD must match. The member's doc comment says the controller accepts the
  claim.
- **`src/transformers/transformer_registration_transformer_fixtures.cue`**: the order-pinning comment
  says `opm-controller` sorts both lists.
- **`src/resources/v1alpha1/transformer_registration.cue`**: the `catalog!` field comment says the
  controller's acceptance refuses a non-catalog artifact.
- **`src/INDEX.md`**: regenerated with `task generate:index` (it repeats the transformer's doc comment).
- **`AGENTS.md`** (Notify downstream bullet), **`.github/workflows/release.yml`** (the
  `notify-downstream` comment) and **`.tasks/branch-tag.sh`** (the range-subscription comment) name
  `opm-controller`.

The Kubernetes `operator:` selector and toleration fields, the third-party "operator CRDs" in
`crd.cue`, the "external secret operator" and "an operator's metrics-reader role" are not the product
and stay. `.tasks/cascade/wiring-check.sh` names `opm-operator` twice, but it is a byte-identical copy
of the `.github` canonical file: it changes only through a `.github` change and its pin round.
`CHANGELOG.md` and `openspec/changes/archive/**` are history and stay as written.

## Before / After

No member's shape, constraint, default or output changes. The reviewed surface is comment text.

**Before**

```cue
// WHY the group, version and kind below are literals: they name a CRD that
// opm-operator owns (enhancement 0015 D3), so nothing in this catalog can
// derive them. The operator's TransformerRegistration CRD must match these

// TransformerRegistrationTransformer renders a provider module's claim as the
// cluster-scoped TransformerRegistration the operator accepts. The object's
```

**After**

```cue
// WHY the group, version and kind below are literals: they name a CRD that
// opm-controller owns (0015:D3), so nothing in this catalog can derive
// them. The controller's TransformerRegistration CRD must match these

// TransformerRegistrationTransformer renders a provider module's claim as the
// cluster-scoped TransformerRegistration the controller accepts. The object's
```

## Impact

- **Published catalog: no behaviour change.** Only comments under `src/` change, so the module source
  differs but no member does. Section 1 commits as `docs(transformers)`, section 2 as `docs`, the
  archive as `chore(openspec)`: all hidden types, so `opm` does not advance on its own. The text ships
  with the next functional catalog release. PR
  title: `docs: follow the opm-controller rename`.
- **modules fleet, subscribing platforms, cli fixtures under `testing.opmodel.dev`:** nothing to do.
- **opm-suite-installer** vendors this catalog; its copy of the fixtures comment updates through its
  own `cue mod tidy` after the next `opm` release, never by hand.
- **library:** bump the `opmodel.dev/catalogs/opm@v4` dep in `testdata/parity/cue.mod/module.cue`
  (and `testdata/parity/opm_platform/cue.mod/module.cue`) with the catalog pin, then run
  `go test ./opm/kernel/ -run TestParity`.
- **Cascade:** none of the three hashed `.tasks/cascade` files (`pins.sh`, `classes`, `cascade.sh`)
  changes, so the `.github` `mirror_sources` hashes for catalog_opm stay valid.

## Enhancement

None yet. The rename's enhancement entry (amending 0006) is still a draft without a number, so there
is no `enhancement.yaml`.
