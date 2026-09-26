---
title: The Catalog Contract
description: "What a catalog author promises, at which contract levels the promise binds, and where OPM enforces it."
type: reference
sidebar:
  order: 5
---

A catalog is a set of published promises. Every resource, trait, and blueprint it ships is a **contract**: modules are compiled against it, match on its key, and keep running against future builds. This page states what a catalog author promises, at which contract levels the promise binds, and exactly where OPM enforces it, including where it does not.

The rules here are restated from the OPM enhancement decisions that define them (cited as `0010 D27`-style); the decision logs remain the design record, this page is the contract's public form.

## Contract levels: where the promise binds

Every resource, trait, and blueprint carries its own `apiVersion` on the ladder:

| Level | Form | The promise |
| --- | --- | --- |
| Alpha | `v1alpha1`, `v2alpha3`, … | **None.** The definition may change or vanish between builds. The compatibility gate does not run. |
| Beta | `v1beta1`, `v1beta2`, … | The additive-only rule below, in full. |
| GA | `v1`, `v2`, … | The additive-only rule below, in full. |

Two things authors most often misread (`0010 D34`):

- **The level is per member, not per catalog.** One build may ship `v1` resources beside `v1alpha1` experiments; each member's own `apiVersion` decides whether it is bound.
- **The level is not the catalog's release version.** A `v1beta1` contract inside a `2.1.0-alpha.3` *release* is fully bound. The release's prerelease suffix says nothing about the contract's maturity. The two are independent axes, and they never read across.

Transformers carry no `apiVersion` and are never compatibility-gated (`0010 D44`): their key is an implementation version, and a new implementation ships as a new key.

## The additive-only rule

At beta and GA, a contract may grow and may never shrink (`0010 D27`):

1. **Fields and options may be added, never removed.**
2. **A newly added field must be optional or defaulted**, because an existing module that does not set it must still evaluate.
3. **An existing field's default may not change**. A default decides what unconfigured modules get, so moving it changes deployed behavior without any consumer editing anything.

Worked against the vocabulary the publish gate itself prints:

| Your edit | Verdict |
| --- | --- |
| Add `spec.retention?: string` (optional) | Legal, additive. |
| Add `spec.retention!: string` (required, no default) | Refused: `field added without optional or default`. |
| Delete `spec.retention` | Refused: `field removed`. |
| Change `spec.schedule: *"daily" \| string` to `*"hourly" \| string` | Refused: `default changed ("daily" -> "hourly")`. |
| Narrow `replicas: int` to `replicas: int & <=10` | Refused: `domain narrowed`. |
| Add an option to a disjunction | Legal, additive in the other direction. |

**The escape hatch is a new `apiVersion`.** A breaking reshape ships *alongside* the old contract at `v1beta2`, a new key with no history, which passes trivially. It does not replace the old one; modules matching the old key keep matching it.

## The three version-shaped values

Three values on and around a catalog member look like versions. They answer different questions, and only one of them is ever an escape from the rule above (`0010 D4`, `0010 D25`):

| Value | Lives on | Part of a key? | What changes it |
| --- | --- | --- | --- |
| `apiVersion` | resources, traits, blueprints | **Yes**, the contract key (`…/backup@v1beta1`) | A deliberate contract revision. Bumping it starts a new, unbound history. |
| Implementation version | transformers (`…/deployment-transformer@1.4.0`) | **Yes**, the implementation key | Every change to the transformer's behavior. Names the bytes that run. |
| `catalogVersion` | every member | **No**, provenance only | Every catalog release, automatically. Records which build shipped the definition. |

`catalogVersion` changes on every release by construction and is never consulted by matching or by the compatibility gate. Bumping it changes nothing about what you have promised.

## How the contract is enforced, exactly

**Enforcement lives in `opm catalog publish`, and only there** (`0010 D35`). On every publish:

- **The compatibility gate** compares each beta/GA member against the last published build that shipped a member of that name at that `apiVersion`, scanning the published history newest-first, **prereleases included** (`0011 D23`). A member no build has carried passes as new. Violations refuse the publish, path-located, in the vocabulary above.
- **The member gate** validates every member's declared path, key, and provenance against the catalog's identity by CUE unification.
- **The posture gate** refuses any trait whose `optional` posture is unstated or pinned rather than defaulted.

**What is *not* enforcement:**

- `opm catalog registry check --compat` runs the same comparison against an already-published catalog, out of band. It is **an aid, not a guarantee**. It can tell you a published build broke its contract; it cannot have prevented it.
- A catalog pushed with bare `cue mod publish` bypasses **every** gate. The registry does not distinguish a gated build from an ungated one, and nothing reports the broken chain afterwards. The contract's integrity is exactly as strong as the discipline of publishing through `opm catalog publish`. For the first-party catalogs, that discipline is CI, which has no other path.

## See also

- [Registry Namespaces](/docs/reference/registry-namespaces/): which registry prefixes are policed, by what, and which are yours.
- [CLI Commands](/docs/reference/cli/): `opm catalog publish`, `opm catalog version set`, `opm catalog registry check`.
