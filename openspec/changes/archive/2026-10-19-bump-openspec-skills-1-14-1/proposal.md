## Why

OpenSpec 1.14.1 makes a requirement over 500 characters a WARNING, and `--strict` fails on any warning. The workspace moves every repo to 1.14.1. This repo has no specs, so for it the move is the generated skill files only. The local edits to four skills and the deleted `openspec-sync-specs` skill must survive the regeneration.

## What Changes

- Regenerate the `.claude/skills/openspec-*` files with `openspec update`, which writes `generatedBy: "1.14.1"`.
- Merge the four local edits (archive-change, new-change, propose, verify-change) with a 3-way merge against pristine 1.12.0 and 1.14.1 output.
- In `openspec-propose`, keep the repo's fixed-schema paragraph in step 3 and drop the new workflow-selection text of 1.14.1 in that step (owner ruling, option 1).
- Delete `openspec-sync-specs` again, as `AGENTS.md` asks.
- No pin, Taskfile target or CI line changes. There is no spec delta.

## Before / After

No CUE member changes.

**Before**

```cue
```

**After**

```cue
```

## Impact

No catalog member, no published module and no consumer changes. Release class: `chore:` for every commit and for the PR title; nothing reaches release-please. Agents that work in this repo read the new skill text.

## Enhancement

None.
