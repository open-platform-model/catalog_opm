## Context

See `proposal.md` for motivation. Files: `opm/cue.mod/module.cue`, `k8s/cue.mod/module.cue` (pins), `opm/catalog.cue`, `k8s/catalog.cue` (the maps), `.tasks/listing.sh` (new), `Taskfile.yml` (`vet:listing`, wired into `check`), `CLAUDE.md` (one rule). No member file is touched; segments reached by import only: `opm/resources/{v1beta1,v1alpha1}`, `opm/traits/{v1beta1,v1alpha1}`, `opm/blueprints/v1beta1`, `k8s/resources/{v1,v2}`.

Core's landed shape (`alpha.8`, `src/catalog.cue`): each map is `[#ContractFQNType]: #<Kind> & {metadata: {A=apiVersion: #APIVersionType, modulePath: "\(M._ref.registryPath)/<kind>/\(A)", catalogVersion: M.version}}`. Members here author `modulePath: "\(id.kindPrefix.<kind>)/<apiVersion>"` and `catalogVersion: id.Version`; `id.kindPrefix` is `RegistryPath + "/<kind>"`, so the stamp and the authored value are the same string by construction.

## Goals / Non-Goals

**Goals:**
- Every member of both catalogs is a key in its map, and the repo cannot drift from that state silently.
- The listing is byte-mechanical: same idiom, same ordering rule, as `#transformers`.

**Non-Goals:**
- No inventory computation here; that is core's `platform-contract-inventory`.
- No gate that a provider-fulfilled contract has a provider; that is the inventory's report, not the catalog's business.
- No change to `opm catalog publish` (the `cli` repo). The listing gate is a repo task, not a publish gate; promoting it to a publish gate is an 0011-family follow-up in `cli`.

## Decisions

**D-A. One import alias per version segment directory.** `opm/catalog.cue` imports `resources/v1beta1` as `res`, `resources/v1alpha1` as `resa`, `traits/v1beta1` as `tr`, `traits/v1alpha1` as `tra`, `blueprints/v1beta1` as `bp`; `k8s/catalog.cue` imports `resources/v1` and `resources/v2`. A new segment directory adds an alias; the gate catches a directory that is not imported.

**D-B. Entries sorted by definition name within each map, as `#transformers` is**, with the experimental `v1alpha1` members grouped last under the same comment `#transformers` uses. Key expression is always `(pkg.#X.metadata.fqn)`, never a string literal, so a renamed member cannot leave a stale key.

**D-C. The listing gate compares two sets per module and kind.** Expected: for every `*.cue` under `<module>/<kind>/`, the authored `fqn:` line, with `\(id.kindPrefix.<kind>)` substituted from `identity/identity.cue`'s `RegistryPath`; a file may hold several members. Listed: `cue eval -e '[for k, _ in #<kind> {k}]' ./` in the module root. Sorted, diffed, non-empty diff fails with the missing and extra keys named. A kind directory that does not exist (k8s traits, blueprints) expects the empty set, which an absent map satisfies.

```sh
# .tasks/listing.sh <module> — sketch
for kind in resources traits blueprints; do
  expected=$(grep -rhoE 'fqn: +"\\\(id\.kindPrefix\.'"$kind"'\)/[^"]+"' "$module/$kind" 2>/dev/null | sed "s|.*kindPrefix\.$kind)|$registry/$kind|; s|\"||g" | sort -u)
  listed=$(cd "$module" && cue eval -e "[for k, _ in #$kind {k}]" ./ | tr -d '[]", ' | sort -u)
  diff <(echo "$expected") <(echo "$listed") || fail "$module #$kind"
done
```

**D-D. The k8s maps for traits and blueprints stay absent.** Core's pattern constraint makes an absent map empty; writing `#traits: {}` would be a promise the raw catalog does not make.

Closedness, defaults, required-set: unchanged for every member. The catalog root value gains three definition-field maps; a consumer unifying against the root (only platforms do, through `#CatalogEntry.#catalog`) sees three more hidden fields.

## Research & Decisions

### Old-core platforms keep evaluating a listing catalog

**Context**: The proposal must say what happens to a platform still pinning core `alpha.7` or older once the catalog lists members.
**Explored**: On a scratch copy of core, `#Platform & {#undeclaredMap: {a: 1}}` evaluated and read back `1` (cue v0.17.1, 2026-09-13): closedness does not refuse an undeclared definition field.
**Decision**: state the maps as inert, not breaking, on old-core platforms; no consumer action required.
**Rationale**: measured, not assumed; it is also why the pin bump and the listing can ship in one release without sequencing consumers.

### Counting the members

**Context**: The listing must be complete on day one.
**Explored**: `grep -rhoE "^#[A-Za-z0-9]+: c\.#(Resource|Trait|Blueprint) & \{"` per module and kind: `opm` 11 resources, 26 traits, 5 blueprints; `k8s` 29 resources, 0 traits, 0 blueprints (2026-09-13, before `backup-traits-alpha`).
**Decision**: those counts are the gate's first expected sets; the gate, not the counts, is what the repo keeps.
**Rationale**: a count in a document goes stale on the next member.

## Risks / Trade-offs

- [A member added later without a listing entry] -> `task vet:listing` in `task check` and CI fails naming the key.
- [`backup-traits-alpha` and this change race] -> whichever lands second lists the two backup traits; the gate demands it.
- [The k8s catalog gains a trait or blueprint one day] -> the gate expects the new directory's members; the author adds the map and the alias.
- [Platform evaluation grows by three maps of full member values] -> the values are the same ones the transformers' required maps already carry; CUE shares them by reference.

## Durable decisions

- "Every contract member is listed in its catalog's `#resources` / `#traits` / `#blueprints` map, keyed `(pkg.#X.metadata.fqn)`; `task vet:listing` enforces it and a new member's checklist gains the entry" -> `CLAUDE.md` Working Style, beside the filing rule.
