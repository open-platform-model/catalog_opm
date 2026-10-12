## Why

Code comments in this repo cite enhancements by id beside a reason in words. Nothing stops a later
change from citing a decision number or a lone id again. The shared `cite-lint` tool of the
enhancements repo checks the rule. This change runs it locally and in CI.

## What Changes

- A `task cite-lint` that runs the tool at one pinned commit of `enhancements`, with no excludes
  (the repo has 0 findings without any).
- A `cite-lint` job in `ci.yml` that calls the reusable `cite-lint.yml` of the `.github` repo.
- A step in the `Validate catalog` job that runs `task openspec:check` (the durable-decisions check).
  Before, only `task check` ran it locally.
- The five `.github` references move to the `.github` commit that holds `cite-lint.yml`, and
  `.tasks/cascade/wiring-check.sh` becomes the copy from that commit. The wiring check now
  accepts the `cite-lint` call as a declared extra reference in `wiring-check.yaml`.

## Before / After

Not applicable: no member shape changes.

## Impact

No published catalog change. Every commit has a non-releasing type. The new job is a normal check
on the pull request; making it required is the owner's setting and is not part of this change.
The repo pins no OpenSpec CLI, so no pin moves.
