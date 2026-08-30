## 1. opm/traits/v1beta1/resource_name.cue

- [ ] 1.1 Delete the file (`#ResourceNameTrait`, `#ResourceName`, `#ResourceNameSchema`); confirm no other file in `opm/traits/v1beta1/` references them

## 2. opm/transformers/name_helpers.cue

- [ ] 2.1 Delete `#WorkloadName`, its WHY block and the "Workload naming" section banner; `#ServiceName`, its WHY block and its `_testServiceName*` guards stay untouched

## 3. opm/transformers/{deployment,statefulset,daemonset,job,cronjob,hpa,pdb}_transformer.cue

- [ ] 3.1 Remove `(tr.#ResourceNameTrait.metadata.fqn): tr.#ResourceNameTrait` from `optionalTraits` in all seven files
- [ ] 3.2 Replace `(#WorkloadName & {#comp: #component}).out` with `#component.#names.resourceName` (six `metadata.name` sites, hpa `_targetName`)
- [ ] 3.3 Migrate the seven exact-name fixtures: drop `tr.#ResourceName` and `spec.resourceName`, add `metadata: resourceName:` with the same string; every `_test*NameResolves` / parity guard keeps its pinned value
- [ ] 3.4 Rewrite the two StatefulSet comments to the design D-C text; reword the "Trait naming" / "Default naming" section comments in job, cronjob, deployment, daemonset, hpa and pdb so none names the trait or the seam
- [ ] 3.5 `cue eval -c` every `_test*Name*` and parity guard in the seven files (not `cue vet`); all resolve

## 4. Major crossing (opm/cue.mod/module.cue, opm/identity/identity.cue)

- [ ] 4.1 `opm/cue.mod/module.cue`: `module: "opmodel.dev/catalogs/opm@v4"`; `opm/identity/identity.cue`: `ModulePath: "opmodel.dev/catalogs/opm@v4"`; `opm catalog version set 4.0.0 ./opm` writes `Version: "4.0.0"` (never hand-edit)
- [ ] 4.2 `task tidy`; deps unchanged
- [ ] 4.3 `.tasks/branch-tag.sh "$(pwd)/opm" opm-` prints a `v4.0.0-0.dev.*` tag
- [ ] 4.4 `CLAUDE.md`, `README.md`, `openspec/config.yaml`: every `opmodel.dev/catalogs/opm@v3` and `v3.x.x` becomes `@v4` / `v4.x.x` (measured 2026-08-30: CLAUDE.md lines 66, 93, 95, 112, 155; README.md lines 5, 9, 19, 25; config.yaml line 9)

## 5. docs/name-constraints.md

- [ ] 5.1 § "Transformers read names, never derive them": remove the `#WorkloadName` seam sentences ("read through one seam ... collapses to a direct read when the trait is deleted"); the direct-read rule and the three carve-outs stay

## 6. Durable decisions

- [ ] 6.1 None to promote (design.md: the docs already carry the read rule; the crossing procedure stays with `catalog-remove-legacy-secrets`)

## 7. Verification

- [ ] 7.1 `task generate:index` (definitions removed); `opm/INDEX.md` no longer lists `#ResourceName*` or `#WorkloadName`
- [ ] 7.2 Byte-identity: `cue export` of the seven exact and seven default fixtures before and after the rewrite (the `catalog-names-readonly-workloads` 5.4 method); `diff` is empty
- [ ] 7.3 `grep -rn 'ResourceNameTrait\|WorkloadName\|resource_name\|resource-name\|catalogs/opm@v3' --include='*.cue' --include='*.md' --include='*.yaml' .` matches only `openspec/changes/archive/` and the CHANGELOG
- [ ] 7.4 `task check`
