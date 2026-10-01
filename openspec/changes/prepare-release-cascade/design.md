## Context

This change touches no catalog member: no file under `opm/` or `k8s/`, and no `apiVersion`
segment. It touches CI and its docs only:

- `.github/workflows/ci.yml`: the required job `ci` ("Validate catalog", `:22-23`), the
  workflow-level `OPM_CLI_VERSION` (`:18-19`), and `Install opm` (`:60-70`). On a release branch
  this workflow runs through `workflow_dispatch` from `release.yml:117-126`, because a PR that
  release-please updates does not always fire `pull_request`. In that run `github.head_ref` is
  empty and `github.ref_name` is `release-please--branches--main--components--<m>`.
- `.github/workflows/release.yml`: `OPM_CLI_VERSION` (`:15-17`). Two jobs install the CLI:
  `release-please` (`Clone the code` `:59-64`, then `Install opm` `:66-76`, which serves the
  identity advance at `:100`) and `publish-cue` (it checks out the **released tag** at
  `:144-147`, then runs `Install opm` at `:149-159`, which serves publish at `:177` and
  `--compat` at `:189`).
- `.github/workflows/branch-publish.yml`: `on.push.branches-ignore: [main]` (`:4-6`),
  `OPM_CLI_VERSION` (`:23-25`), and the job `publish` (`Install opm` at `:57-67`).
- `Taskfile.yml`: the home of every repo check (`fmt:check`, `vet`, `vet:layering` ...). The
  `MODULES` var (`:11`) fans out over `opm k8s`.
- `AGENTS.md` § Release & publishing (`:216-224`) and § Build And Dev Commands (`:196-214`).

The shipped pins that G1 judges are `opm/cue.mod/module.cue:13-15` and
`k8s/cue.mod/module.cue:9-11`. Both pin `opmodel.dev/core@v2` at `v2.0.0-beta.1` today.

## Goals / Non-Goals

**Goals:**

- A release PR in either catalog cannot pass the required check while either catalog pins a
  `-0.dev.` dependency or tracks a `cue.mod/local-module.cue`.
- Pushes to `deps/**` never publish anything.
- No opm CLI version literal is left under `.github/workflows/`. The single source is
  `.opm-cli-version`, which a bot can edit with the Contents permission alone.

**Non-Goals:**

- G2 (`cascade/freshness`) and G3 (`cascade/settled`). They live in the shared cascade
  workflows (later phase X1).
- Running G1 on every PR. The owner scoped G1 to release PRs (workspace `RELEASING.md`,
  section "Gates").
- Splitting "Verify the published build" out of `publish-cue`, and the notify job. Both belong
  to `join-release-cascade` (C1).

## Decisions

### D1. G1 is a Taskfile task, called by a conditional step in the existing required job

```yaml
# ci.yml, job `ci`, placed after "Install Task" and before "Check CUE formatting":
# fail fast, before any registry access.
      # G1 release-pin gate (workspace RELEASING.md, section "Gates"). Release PR CI
      # arrives either as pull_request (head_ref set) or as the workflow_dispatch run
      # release.yml starts on the release branch (head_ref empty, ref_name set).
      - name: Release-pin gate (G1)
        if: startsWith(github.head_ref || github.ref_name, 'release-please--')
        run: task deps:release-check
```

```yaml
# Taskfile.yml
  deps:release-check:
    desc: >
      G1 release-pin gate: fail if either catalog pins a -0.dev. dependency in
      cue.mod/module.cue or tracks a cue.mod/local-module.cue. CI runs it on
      release-please branches; safe to run anywhere.
    cmds:
      - |
        rc=0
        for m in {{.MODULES}}; do
          if grep -nE 'v: "[^"]*-0\.dev\.' "$m/cue.mod/module.cue"; then
            echo "G1: $m/cue.mod/module.cue pins a dev build; a release must pin published versions" >&2
            rc=1
          fi
        done
        tracked=$(git ls-files -- '*cue.mod/local-module.cue')
        if [ -n "$tracked" ]; then
          echo "G1: tracked local replacement(s), never shipped in a release:" >&2
          echo "$tracked" >&2
          rc=1
        fi
        exit $rc
```

The gate is a **step**, not a job. A job skipped by its `if:` would report "skipped", which a
required check treats as passing. The job `ci` always runs, so only the step can be skipped, and
only when the ref is not a release branch. A Taskfile task, rather than inline YAML, means the
gate can be run locally (`task deps:release-check`) and follows the repo's habit of keeping every
check in the Taskfile. The name `deps:release-check` matches the plan's name for the same gate
in the other repos.

**Alternative rejected:** a separate `release-pin-gate` job. It would need its own required
check name in the ruleset, and a skipped job would read as a pass.

### D2. Both catalogs are checked on every release PR

release-please keeps one release PR per catalog (`release.yml:92-93`), but G1 scans both
`MODULES`. A dev pin in `k8s` therefore also blocks an `opm` release PR. This is deliberate:
`main` should never carry a dev pin, and a scan per module would need the component name parsed
from the ref for no real gain.

### D3. `.opm-cli-version` is read in every job, right after that job's checkout

```yaml
      - name: Read the pinned opm CLI version
        run: |
          test -s .opm-cli-version
          echo "OPM_CLI_VERSION=$(cat .opm-cli-version)" >> "$GITHUB_ENV"
```

Placement in each job:

| Workflow | Job | After | Before |
|---|---|---|---|
| `ci.yml` | `ci` | `Clone the code` | `Install opm` |
| `branch-publish.yml` | `publish` | `Clone the code` | `Install opm` |
| `release.yml` | `release-please` | `Clone the code` (`:59`) | `Install opm` (`:66`) |
| `release.yml` | `publish-cue` | `Clone the released tag` (`:144`) | `Install opm` (`:149`) |

The `Install opm` step bodies do not change: they already read `${OPM_CLI_VERSION}`. The step
name is the same in every job, which helps `grep`. The `test -s` line comes before the verbatim
`echo` line. A missing or empty file would otherwise write `OPM_CLI_VERSION=`, and the step
would still succeed, because a failing command substitution inside `echo` does not trip
`bash -e`. The install would then fail later with an unclear 404 on `.../download//...`.

`publish-cue` reads the file from the **released tag**. The CLI that publishes a release is
then the one committed in that release, which is more reproducible than today's workflow-level
literal from `main`.

**Alternative rejected:** keep a workflow-level `env:` and have a bot edit it. That needs the
GitHub Workflows permission (workspace `RELEASING.md`, section "Owner settings"), and the
cascade App must not have it.

### D4. `branch-publish.yml` ignores `deps/**`

```yaml
on:
  push:
    branches-ignore:
      - main
      - 'deps/**'
```

The cascade pushes `deps/cascade`. A dev catalog published from that branch would be a GHCR
artifact that nobody consumes, made from a bot commit. Feature branches and the
`release-please--*` branches keep publishing dev tags as today. `deps/**` matches only under
`deps/`, so a branch like `deps-foo` still publishes.

### D5. The bump to `v1.0.0-beta.4` is its own section

The move (section 1) keeps `v1.0.0-beta.2`, so it changes no behaviour and can be checked on
its own: CI installs the same binary as before. The bump (section 2) is then the one-line
`ci(deps)` diff that the cascade will produce later, and a regression bisects to it alone.

## Research & Decisions

### Does any publish gate already refuse these pins?

**Context**: G1 should not duplicate an existing refusal without reason.
**Explored**: `cli/internal/cmd/catalog/publish.go:13-15`: `opm catalog publish` always refuses
a tree carrying `cue.mod/local-module.cue`. Searching `cli/internal/publish/` found no refusal
for a `-0.dev.` *dependency* pin (the `0.dev` hits are about the catalog's own version
ordering, `compat.go:160-185`).
**Decision**: G1 checks both. The local-module check is defence in depth: it fails earlier and
names the file, and the `Publish gates dry-run` step (`ci.yml:82-103`) would also catch it. The
dev-pin check is new coverage.
**Rationale**: the check costs one `git ls-files` call. Keeping the same two rules in every
repo's G1 makes the gate uniform across the cascade.

### Is `v1.0.0-beta.4` safe for catalog publishing?

**Context**: the bump sits on the release path (a release-tool pin).
**Explored**: `gh release view` on cli: `v1.0.0-beta.4` (2026-10-01) is published and not a
draft, and ships `opm-linux-amd64.tar.gz` and `checksums.txt`. The notes for beta.3 and beta.4
list only `fix(deps)` changes (embedding opm-operator `v1.0.0-beta.2`, and `golang.org/x/term`).
Nothing touches `opm catalog`.
**Decision**: bump straight from beta.2 to beta.4. Section 2 still runs both dry-run publishes
locally before it commits.
**Rationale**: the CI dry-run (`ci.yml:82-103`) is the real proof, and it runs on the PR.

## Risks / Trade-offs

- [Re-running `publish-cue` for a tag cut before section 1 merges finds no `.opm-cli-version`]
  -> `test -s` fails loudly in the read step. No such re-run is planned: every existing tag is
  already published, and AGENTS.md says a failed release is fixed by releasing the next version.
- [The workspace `deps:pins:opm-cli` still edits workflow literals when this merges] -> stated as
  a dependency in proposal.md. The workspace `docs/release-cascade` branch must merge first.
  Otherwise the script's `grep -q ... || continue` (`.tasks/deps/opm-cli.sh:24`) skips this
  repo silently.
- [G1 is advisory until the ruleset requires `Validate catalog`] -> catalog_opm's `main`
  branch protection already requires `Validate catalog` (checked 2026-10-01 with
  `gh api .../branches/main/protection`; dispatched CI exists to satisfy it, `ci.yml:7-10`). The owner's
  D14 ruleset keeps it required.
- [A grep on `v: "..."` misses a pin written in another CUE shape] -> `cue mod tidy` and
  `opm catalog version set` always write the `v: "<version>"` form. A hand-written shape would
  fail `task tidy`'s diff anyway.

## Durable decisions

- `.opm-cli-version` is the only home of the opm CLI pin. No version literal goes into
  `.github/workflows/`, and a bump is a `ci(deps)` commit. Lands in `AGENTS.md` § Release &
  publishing (section 1).
- G1 (`task deps:release-check`) runs on release-please branches inside `Validate catalog`, and
  what it refuses. Lands in `AGENTS.md` § Release & publishing, plus a row in § Build And Dev
  Commands (section 3).
- `branch-publish.yml` publishes every non-main branch **except `deps/**`**. The `AGENTS.md`
  § Release & publishing bullet on `branch-publish.yml` is amended (section 4).
