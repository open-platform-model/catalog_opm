## Context

`openspec/config.yaml` and `AGENTS.md` set the repo rules: schema `catalog-change`, `skip_specs: true`, and `openspec-sync-specs` deleted after every `openspec init` or `openspec update`. Four skills carry local edits: `openspec-archive-change`, `openspec-new-change`, `openspec-propose` and `openspec-verify-change`. The repo has no hand-written `openspec-cleanup-change`. No CUE member and no `apiVersion` segment is touched.

## Goals / Non-Goals

**Goals:** skills at 1.14.1; local edits kept; sync-specs deleted.

**Non-Goals:** pinning an OpenSpec CLI version; adding a strict gate; any spec text.

## Decisions

- **3-way merge per edited file.** Base is pristine 1.12.0 output, theirs is pristine 1.14.1 output, ours is the repo file (`git merge-file`). `openspec update` overwrites without a merge, so the merge runs after it on saved copies of the repo files.
- **Propose conflict.** The owner ruled for the repo's paragraph: keep "This repo's default is the project-local `catalog-change` schema" and its "Never select `spec-driven`" rule, and drop the 1.14.1 workflow-selection text in step 3. Every other 1.14.1 change in the file stays.
- **No version pin.** The repo has no OpenSpec CLI pin or gate; this change adds none.

## Risks / Trade-offs

Skill files steer agents -> scan the changed skills for hidden Unicode and check that no `allowed-tools` line changed.

## Durable decisions

None.
