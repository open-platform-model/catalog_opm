## Why

The catalog's golden transformer fixtures are only load-bearing under `task vet:fixtures`
(`cue export -e <field>` per rendered-output fixture), and the required PR check never runs it:
`.github/workflows/ci.yml` runs `task vet`, listing, descriptions, index, kindgen and docs, but
not `vet:fixtures`. Only `branch-publish.yml` runs it, through `task check`. A PR that stops a
fixture from evaluating merges green.

The fixtures also sit inside the shipped packages with nothing marking them test-only: 292
top-level `_test*` fields, 287 of them in 28 files of package `transformers` (49% of its lines)
and 5 in `blueprints/v1beta1/network_policy_attachment.cue`. Every load of `transformers` or
`blueprints/v1beta1` as a main instance (`cue vet ./...`, an editor, any future tool that
finalizes the package) evaluates all of them. Measured 2026-10-02, cue v0.17.1:
`cue vet ./transformers` takes 0.57 s and 110 MB with the fixtures against 0.29 s and 63 MB
without (kernel plan beta1 task j2, `j2-g1-result.json`). Consumers that import the catalog pay
about 2 MB of parse retention and no evaluation, so this half of the change is hygiene and
clarity, not a consumer speed-up.

Owner decision, 2026-10-03 (kernel plan beta1, task j2): "run vet:fixtures in PR CI, and do the
@if(fixtures) split."

## What Changes

- **Section 1: `vet:fixtures` in the required check.** `ci.yml`'s `Validate catalog` job gains a
  `task vet:fixtures` step. The release PR's CI arrives as the `workflow_dispatch` run of the same
  job (`release.yml`, "Trigger required CI on the release PR"), so the release commit is gated
  too. `release.yml`'s `release-please` job, which tags whatever `main` holds with no vet of its
  own, gains the same `task vet:fixtures` step before the release-please action runs, so a
  broken `main` never tags (design D2).
- **Section 2: fixtures move behind a build tag.** Each of the 29 files moves its `_test*` tail
  (the fixtures plus the comment banner above them) into a sibling `<name>_fixtures.cue` whose
  first line is the file attribute `@if(fixtures)`, above the package clause. 28 transformer
  files keep their definitions; `network_policy_attachment.cue` holds nothing but fixtures and
  moves whole to `network_policy_attachment_fixtures.cue`. Imports the split leaves unused are
  removed from both sides.
  - `task vet` runs `cue vet ./...` (the shipped view, fixtures left out) and then
    `cue vet -t fixtures ./...` (the fixtures).
  - `.tasks/fixtures.sh` exports with `cue export -t fixtures -e <field> ./transformers`.
  - New lint `task vet:fixtures:tagged` (`.tasks/fixture-tags.sh`): every file under `src/`
    that declares a top-level `_test*` field carries `@if(fixtures)` as a file attribute. It
    joins `task check` and `ci.yml`.
  - The tag, not a `_test.cue` file suffix: the cue CLI has no test mode, so it silently drops
    `x_test.cue` from `cue vet ./...` and refuses it when named directly (design D1).
  - `AGENTS.md` and the docs that give raw fixture commands (`cue eval -c -e _test… ./transformers`
    and the like) gain `-t fixtures`, and file references follow the move.

## Before / After

No catalog member changes. The shape that changes is where a fixture lives.

**Before** (`src/transformers/configmap_transformer.cue`, one file, always loaded)

```cue
package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
	// … imports the definitions use
)

#ConfigMapTransformer: c.#ComponentTransformer & { /* … */ }

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testConfigMapNamingComponent: res.#ConfigMaps & { /* … */ }
```

**After** (two files; the second is left out unless `-t fixtures` is set)

```cue
// src/transformers/configmap_transformer.cue
package transformers

import (
	// only the imports the definitions use
)

#ConfigMapTransformer: c.#ComponentTransformer & { /* … */ }
```

```cue
// src/transformers/configmap_transformer_fixtures.cue
@if(fixtures)

package transformers

import (
	res "opmodel.dev/catalogs/opm/resources/v1beta1"
)

/////////////////////////////////////////////////////////////////
//// Test Data
/////////////////////////////////////////////////////////////////

_testConfigMapNamingComponent: res.#ConfigMaps & { /* … */ }
```

The checks, before and after:

```text
Before: task vet = cue vet ./...                     (fixtures always evaluated)
        ci.yml  : no vet:fixtures                    (golden literals unchecked on PRs)
After:  task vet = cue vet ./... && cue vet -t fixtures ./...
        task vet:fixtures = cue export -t fixtures -e <field> ./transformers, per fixture
        task vet:fixtures:tagged = no top-level _test* field outside an @if(fixtures) file
        ci.yml  : vet, vet:fixtures and vet:fixtures:tagged all in Validate catalog
        release.yml release-please: vet:fixtures before it can tag
```

## Impact

- **Published catalog:** no member, field, default or closedness changes, and no `apiVersion`
  segment moves. The next release ships 29 new `*_fixtures.cue` files (`source: kind: "self"`
  ships every `.cue` file under `src/`); a consumer's build leaves them out, because a tag
  passed outside the main module is always unset (`cue/load/loader_common.go:400-408`). The
  published zip keeps its size; only moving the fixtures out of `src/` would remove the bytes,
  which this change does not do.
- **Release class:** section 1 is `ci:`, section 2 is `test:`. Both are hidden types; neither
  releases `opm` on its own.
- **`modules` fleet, subscribing platforms, `cli` fixtures under `testing.opmodel.dev`:** nothing
  to do. They import the catalog root, which never references a `_test*` field.
- **Catalog authors:** a new fixture goes into the member's `<name>_fixtures.cue`, never into the
  definition file; the lint refuses the old placement. Raw `cue eval` or `cue export` of a
  fixture needs `-t fixtures`. Without it the field is "not found", which is loud, not silent.
  The tag is valid only for a package that holds a fixture file, or over `./...`; elsewhere cue
  refuses it with `tag "fixtures" not used in any file`.
- **CI time:** `vet:fixtures` takes about 30 s (56 exports), in `Validate catalog` and once
  more on every push to `main` in `release.yml`'s `release-please` job; `task vet` gains one extra pass of
  about 0.3 s.

## Enhancement

None. The work is task j2 of the kernel plan beta1 (owner walkthrough, 2026-10-03); no
enhancement entry backs it, so there is no `enhancement.yaml`.
