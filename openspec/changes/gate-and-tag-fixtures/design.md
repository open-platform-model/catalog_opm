## Context

No catalog member changes and no `apiVersion` segment is touched. The change moves test data and
changes the checks around it.

- **Fixture inventory at `1978438`:** 292 top-level `_test*` fields in 29 files. 28 are in
  `src/transformers/` (every file there except `pod_helpers.cue`); 5 fields are in
  `src/blueprints/v1beta1/network_policy_attachment.cue`. In every file the fixtures come after
  all definitions, usually under a `//// Test Data` banner. `network_policy_attachment.cue` holds
  only its package clause, one import, a banner explaining why the file exists, and fixtures.
- **Other top-level hidden fields stay where they are:** `src/schemas/kinds/check.cue`
  `_tableEntriesConform` is a conformance check that must run on every plain vet, and
  `src/resources/v1alpha1/objects.cue` `_builtinGroups` is live code.
- **The checks today** (`Taskfile.yml`): `vet` is `cue vet ./...` (`:36-40`); `vet:fixtures`
  runs `.tasks/fixtures.sh`, which selects the 56 fields declared
  `_test<Name>: (#<T>.#transform & {` under `src/transformers/` and runs
  `cue export -e <field> ./transformers` once each (about 30 s); `check` (`:202-213`) runs both.
- **CI today:** `.github/workflows/ci.yml` job `ci` ("Validate catalog", the required check)
  runs `task vet` (`:67-68`) but not `vet:fixtures`. `branch-publish.yml` runs `task check`.
  `release.yml` publishes the released tag with `opm catalog publish` and runs no vet of its
  own; the release PR's required check is the dispatched `ci.yml` run (`release.yml`,
  "Trigger required CI on the release PR").
- **Scripts that enumerate `.cue` files:** `generate-index.sh` reads definitions only (the
  fixture files declare none); `doc-check.sh` exempts `_test*` labels wherever they are;
  `listing.sh` and `description-check.sh` read definitions and the catalog maps. None of them
  changes behaviour when a file is split.

## Goals / Non-Goals

**Goals:**

- No PR merges while a rendered-output fixture fails to evaluate.
- A plain `cue vet ./...`, which is how a consumer or editor sees the shipped packages, loads no
  fixture; `-t fixtures` loads all of them.
- No top-level `_test*` field can land outside a tagged file without failing a check.

**Non-Goals:**

- Removing the fixture bytes from the published module. That needs the fixtures outside `src/`
  (a sibling module importing the catalog), and it loses same-package access to hidden helpers.
- Running blueprint fixtures through an export gate. `vet:fixtures` keeps its selector; the
  blueprint fixtures stay covered by `cue vet -t fixtures` as today by `cue vet`.
- Correcting the wider prose about what `cue vet` checks in hidden fields (see Risks).
- Any change to `release.yml` or `branch-publish.yml` (D2).

## Decisions

### D1. Tag the fixture files with `@if(fixtures)`; never use a `_test.cue` suffix

Each fixture file starts with the file attribute, above the package clause:

```cue
@if(fixtures)

package transformers
```

The name is `<definition file stem>_fixtures.cue`, beside the file whose member it tests.
Alternatives considered:

- **`<name>_test.cue`.** Rejected: the cue CLI has no test mode. `cue vet ./...` silently skips
  `_test.cue` files and naming one directly fails with "_test.cue files excluded in non-test
  mode". The fixtures would stop being checked at all, with nothing failing.
- **A sibling `fixtures/` package or module.** Rejected for this change: every unqualified
  reference to the package's definitions (`#DeploymentTransformer`, `#ToK8sVolumes` and so on)
  would become a qualified import across a module boundary, a rewrite of about 3,600 lines, and
  the only gain over the tag is the shipped bytes. The owner chose the tag.

A tag never reaches a consumer: the loader treats every tag as unset for files outside the main
module (cue v0.17.1, `cue/load/loader_common.go:400-408`), so no consumer can switch the
fixtures on, even by passing `-t fixtures`.

### D2. `vet:fixtures` joins the required job; the release path needs no extra step

```yaml
# ci.yml, job ci, after "Verify every member has a description":
      - name: Check every rendered-output fixture evaluates
        run: task vet:fixtures
```

The owner asked for the gate on the release path too "if it publishes without it". The release
commit is gated: `release.yml` dispatches `ci.yml` onto the release-please branch, and that run
is the required `Validate catalog` check the release PR must pass before it merges. The
`publish-cue` job then publishes that merged tag and runs no vet step of any kind, the same
position `task vet` is in today. Adding `vet:fixtures` to `publish-cue` would re-check a commit
that already passed, at 30 s per release plus a Task install, so this change adds none.
`branch-publish.yml` already runs `task check`, which picks up the new lint by itself.

### D3. `task vet` runs both views

```yaml
  vet:
    desc: >
      Validate every catalog package twice: as a consumer loads it (fixture
      files left out) and with -t fixtures (every fixture file loaded).
    dir: "{{.MODULE_DIR}}"
    cmds:
      - cue vet ./...
      - cue vet -t fixtures ./...
```

The plain pass is what keeps the shipped view valid: an import only a fixture used, left behind
in a definition file, fails it as "imported and not used". The tagged pass checks the fixtures,
including unused imports inside a fixture file. `.tasks/fixtures.sh` changes only its export
line to `cue export -t fixtures -e "$field" ./transformers`, and its header comment says why.

### D4. Lint: `task vet:fixtures:tagged`

`.tasks/fixture-tags.sh <module_dir>` fails, naming each file, when a `.cue` file under the
module (outside `cue.mod/`) has a line matching `^_test[A-Za-z0-9_]*[!?]?:` and no line
`@if(fixtures)` before its `package` clause. It reads text only, needs no registry and runs in
milliseconds. It runs in `task check` and as its own step in `ci.yml`, before the registry
login, so a misplaced fixture fails fast. It checks only what the owner asked for: the
placement of top-level `_test*` fields. It does not require the `_fixtures.cue` name; the name is
a convention in `AGENTS.md`.

### D5. How the split is done

A scratch script (not committed) splits each of the 28 transformer files at the start of its
test tail: the `//// Test Data` banner when there is one, otherwise the comment block directly
above the first top-level `_test*` field. The tail moves verbatim below the attribute, the package
clause and the imports it uses. `network_policy_attachment.cue` is renamed with `git mv` and gains
the attribute, so its explanatory banner keeps its history. Imports are pruned by `cue vet` in
both views (D3), never by hand-guessing. The prototype of 2026-10-02 removed 20 imports this way
(6 from definition files, 14 from fixture files).

## Research & Decisions

### Does the tag keep the fixtures checked and the shipped view clean?

**Context**: The split only helps if `-t fixtures` still catches a broken golden and the untagged
build sees nothing.
**Explored**: kernel plan beta1 task j2 experiment (`claude-stuff/kernel-plan-beta1/j2-g1-result.json`,
`raw.cat`), a full prototype of this split on a copy of `src/` at `1978438` (scratch tree
`exp/catalog-pins/tagged`), cue v0.17.1.
**Decision**: Use `@if(fixtures)` files (D1) with both vet passes (D3).
**Rationale**: On the prototype, `cue vet ./...` passes and loads no fixture; `cue vet -t fixtures
./...` passes on the real tree. With one golden literal changed to `"WRONG"`, the untagged vet
passes (it cannot see it) and the tagged vet fails with `conflicting values "istio-istiod" and
"WRONG"`. Main-instance cost of `transformers` falls from 76.0 MB / 231 ms to 35.0 MB / 115 ms
untagged; importers see 43.5 MB against 42.9 MB, inside the noise.

### Does `cue fmt ./...` still format a tag-excluded file?

**Context**: `task fmt:check` runs `cue fmt ./...` without tags; if fmt skipped excluded files,
fixture files would escape the format gate.
**Explored**: On a copy of the prototype, misindented a line in
`transformers/configmap_transformer_fixtures.cue` and ran `cue fmt ./...` (cue v0.17.1,
2026-10-03).
**Decision**: No tag on the fmt tasks.
**Rationale**: `cue fmt` rewrote the excluded file. It formats every `.cue` file, tags or not.

## Risks / Trade-offs

- **A raw command without `-t fixtures` reports the fixture "not found".** That is loud, and every
  documented command gains the tag in this change.
- **The fixture bytes still ship**, and the loader still parses excluded files (about 1.2 MB
  retained per runtime). Accepted; see Non-Goals.
- **Existing prose overstates what `cue vet` skips.** `fixtures.sh`'s header and `AGENTS.md` say
  `cue vet` does not check hidden fields; the j2 experiment shows it does fail on an error-class
  conflict in one (the AGENTS.md bullet already says so in a parenthesis). This change leaves that
  wording alone except where it rewrites the line for `-t fixtures`.

## Durable decisions

- **Fixtures live in `<name>_fixtures.cue` beside the member's file, with `@if(fixtures)` above
  the package clause; never in the definition file, never in a `_test.cue` file.** Lands in
  `AGENTS.md`, Working Style (transformer fixtures bullet) and in the `task vet:fixtures:tagged`
  row of Build And Dev Commands.
- **Raw fixture commands need `-t fixtures`** (`cue eval -c -t fixtures -e _test… ./transformers`,
  `cue export -t fixtures …`). Lands in `AGENTS.md` and in each doc that gives such a command
  (`docs/name-constraints.md`, `docs/struct-disjunctions.md`, `docs/site/extending/write-a-transformer.md`,
  `docs/site/extending/write-a-blueprint.md`).
- **`task vet` validates both views.** Lands in the `task vet` row of `AGENTS.md`.
