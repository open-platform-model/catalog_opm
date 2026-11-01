## Context

`AGENTS.md` holds repo facts and `CONTEXT.md` is a router, under the workspace docs form. The workspace docs form lists `GLOSSARY.md` as an allowed root name. No CUE member and no `apiVersion` segment is touched.

## Goals / Non-Goals

**Goals:** one glossary in the form of the glossary format; every term backed by a file in this repo; two pointers.

**Non-Goals:** new rules; any change to authoring notes; any change to a definition.

## Decisions

- **Single context.** The repo is one catalog, so one root `GLOSSARY.md` and no glossary map.
- **Terms from the repo only.** A term appears only when `AGENTS.md`, `openspec/config.yaml`, `references/`, `docs/` or `src/` uses it. Core terms (`#Resource`, `#Trait`, `#Blueprint`, `#ComponentTransformer`) are defined as this repo uses them.
- **Pointers.** `AGENTS.md` gets a layout line, which is where it lists root material. `CONTEXT.md` gets one row. Neither names a heading.

## Risks / Trade-offs

Two files that steer agents change -> keep the new lines free of instructions that weaken a control, and scan the changed files for hidden Unicode.

## Durable decisions

None.
