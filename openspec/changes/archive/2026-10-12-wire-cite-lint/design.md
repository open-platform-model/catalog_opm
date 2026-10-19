## Context

`ci.yml` runs on `pull_request` and on `push` to `main`, so a new job there covers both events.
`.github` PR 22 added the `cite-lint` reference kind to `wiring-check.sh` and the reusable
`cite-lint.yml`. A caller passes only `paths` and `exclude`; the tool pin lives in `cite-lint.yml`.

## Goals / Non-Goals

**Goals:** the same comment rule locally and in CI; one pin for every `.github` reference.

**Non-Goals:** rewriting a citation; making the check required; changing any CUE.

## Decisions

- **No excludes.** `enh cite-lint --root .` reports 0 findings with none, so neither the task
  nor the CI call passes an exclude. A later exclude goes into both places, each with a comment
  that names the other.
- **One tool commit in the task.** `CITE_LINT_REF` in `Taskfile.yml` is the commit that
  `cite-lint.yml` uses as its `enh-ref` default. The wiring check does not compare the two; a
  comment in the Taskfile names the workflow.
- **Not in `task check`.** `task check` leaves cite-lint out because the tool needs Go 1.26.9 and the repo's Go is older; CI runs it through `cite-lint.yml`.
- **Separate job, not a step.** A reusable workflow is a job. It runs in parallel with the
  `Validate catalog` job and needs no registry.
- **`openspec:check` as a step** after the wiring check, because the wiring check says only
  SHA-pinned actions may come before it. The step runs `task openspec:check`, which is offline.
- **Pin move.** All five `.github` references and the check copy move together in one `ci(deps)`
  commit, as earlier pin moves did. Between `0f9c6ac2` and `2b66da51` the cascade scripts changed
  to accept `opm-controller` as a source name and a tag prefix (the cascade receive here now also
  reads opm-controller releases, one more API call per run) and the wiring check gains the
  `cite-lint` kind.

## Risks / Trade-offs

A reviewer could move `CITE_LINT_REF` without the workflow pin, so the local and CI tool differ ->
the Taskfile comment names the workflow; the next `.github` pin move is the time to compare.

## Durable decisions

None.
