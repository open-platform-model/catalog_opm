## Why

Agents and the owner use loose words for catalog concepts: "module" for the CUE module and for an OPM module, "contract" for a member and for its schema, "provider" for a catalog and for a transformer. A root `GLOSSARY.md` fixes one word for each concept. The skills that design and refactor read it and let its terms win over their generic architecture words.

## What Changes

- Add `GLOSSARY.md` at the repo root with the domain terms of this repo.
- Add one layout line to `AGENTS.md` and one router row to `CONTEXT.md` that point to it.
- No other line of any file changes.

## Before / After

No CUE member changes.

**Before**

```cue
```

**After**

```cue
```

## Impact

No catalog member, no published module and no consumer changes. Release class: `docs:` for the commit and the PR title; it is hidden in this repo and cuts no release. Agents that work in this repo read the new file.

## Enhancement

None.
