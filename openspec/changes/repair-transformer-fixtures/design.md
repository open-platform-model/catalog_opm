# Design: repair-transformer-fixtures

## Context

See `proposal.md` § Why. The authoring rule and the measured cause are already in `CLAUDE.md` § Working Style, landed with the D9 registration contract; the working examples are `opm/transformers/transformer_registration_transformer.cue` and `opm/transformers/pvc_transformer.cue`.

Measured 2026-09-15 (cue v0.17.1, core `v2.0.0-alpha.9`, catalog at 4.3.0), in `opm/`:

| Set | Count | Failing `cue export` |
| --- | --- | --- |
| Hidden `_test*` fields under `transformers/` | 231 | 92 |
| Rendered-output fixtures (`_testX: (#Y.#transform & {`) | 47 | 44 |
| Transformer files (excluding the four `*_helpers.cue`) | 23 | 22 carry at least one failure |

A full sweep of all 231 fields takes 42 seconds.

## Goals / Non-Goals

**Goals**

- Every rendered-output fixture in the package evaluates, so its golden literal compares something.
- A gate that fails when one stops evaluating, wired into `task check`.
- Each disagreement between a repaired fixture and the real render is triaged rather than papered over.

**Non-Goals**

- Fixing a transformer whose rendered output turns out to be wrong. That is a `fix:` change of its own, named here.
- Component fixtures (`_test*Component`). Many are legitimately non-concrete and are not a golden-output check.
- `k8s/`, which ships no transformers.
- Any change to a published member's shape or output.

## Decisions

### The gate checks rendered-output fixtures, identified structurally

`.tasks/fixtures.sh <module-dir>` MUST enumerate fields declared as

```
_test<Name>: (#<Transformer>.#transform & {
```

under `<module>/transformers/*.cue`, and MUST run `cue export -e <field> ./transformers` on each, reporting the field name and CUE's error on failure. `task vet:fixtures` runs it per module; `task check` gains it after `vet:listing`.

The selector is the declaration form, not a naming convention: a fixture is a rendered output because it is the `.output` of a `#transform`, and a future author renaming `_testFooTransformer` to `_testFooRendered` stays covered. Restricting to that form is what keeps the gate honest: sweeping all 231 hidden fields reports 92 failures, most of them component fixtures whose attached primitives carry schemas and are non-concrete by design. A gate with 90 known-acceptable failures is a gate nobody reads.

### The repair is mechanical, but the golden literals are not

For the 21 files using the retired spelling the input edit is the same everywhere:

```cue
// before
#context: {
	#moduleInstanceMetadata: {name: …, namespace: …, fqn: …, version: …, uuid: …}
	#componentMetadata: name: …
	#runtimeName: "opm-test"
}

// after
#moduleInstance: {
	metadata: {name: …, namespace: …, fqn: …, uuid: …}
	#moduleMetadata: version: …
}
#context: #runtimeName: "opm-test"
```

`role_transformer.cue` supplies neither input and gains both.

What is not mechanical is the golden literal. Once the projection evaluates, `#context.componentLabels` reads `#component.metadata.name`, and `#context.labels` folds module, component and controller labels together. A fixture whose component never set `metadata.name` will render labels its literal does not claim. Every touched fixture MUST therefore be re-pinned against the actual export, one file at a time, and a file is done only when `cue export` succeeds AND `cue vet` still passes with the literal in place.

### A disagreement is triaged, not overwritten

These literals have never been compared against a real render, so a disagreement has two possible causes and they are not interchangeable:

1. The literal was written by hand against an intended output and the transformer renders something else. That is a rendering defect, possibly shipped, and MUST NOT be silently absorbed by rewriting the literal.
2. The literal encodes an assumption the projection changed (a label whose source moved). That is the fixture being stale and is repaired here.

Any case of (1) MUST be recorded in this design under a "Findings" heading with the transformer, the expected and actual bytes, and MUST be fixed in its own `fix:` change. This change never changes a transformer's output.

### Section order keeps every boundary green

The gate lands **unwired** in section 1 and is wired into `task check` only in the last section. Wiring it first would make `task check` red for every intermediate section, which the mergeable-sections invariant forbids. Between those, the repair runs in two batches, each ending with `cue export` clean for its own files and `task check` green.

## Research & Decisions

### What the gate should enumerate

**Context**: The obvious gate is "export every hidden `_test*` field", and it is wrong.
**Explored**: Both sweeps, scripted in the scratchpad and run against the tree at 4.3.0 (2026-09-15): all 231 hidden fields, then only the 47 declared as `(#X.#transform & {`.
**Decision**: The structural selector, 47 fields.
**Rationale**: the broad sweep reports 92 failures. Spot-checking them, `_testTransformerRegistrationComponent` fails while its sibling output fixture passes: a component fixture holds primitives whose `spec` is a schema, so it is non-concrete by design. Gating on that would either demand concreteness the design forbids or ship with a suppression list.

### `cue vet -c` is not an alternative

**Context**: The cheap fix would be to run the existing vet with `-c`.
**Explored**: `cue vet -c ./transformers` on the unrepaired tree.
**Decision**: Not usable; the gate needs `cue export` per field.
**Rationale**: it exits 0. `cue vet -c` does not check hidden fields, which is the same property the library's own pin files record, and every fixture here is hidden on purpose so that an importing package never evaluates them.

## Risks / Trade-offs

- [Re-pinning 44 fixtures is a large mechanical diff in which a real defect could hide] -> two batches with a per-file rule: export must succeed and vet must still pass, and any literal that had to change in a way not explained by the projection is recorded as a Finding before the section's commit.
- [The repair uncovers a genuine rendering defect] -> expected, and the reason this change is `test:` only. The defect gets its own `fix:` change; this change's design names it.
- [The gate adds time to `task check`] -> measured 42 seconds for all 231 fields, so the 47-field subset is well under that; acceptable for a gate that runs in CI and before a commit.
- [A future author adds a fixture in a shape the selector misses] -> the selector keys on the `#transform` form every fixture must already use to render anything; a fixture that does not call `#transform` is not a rendered-output fixture.

## Durable decisions

- **The rendered-output fixture rule** is already in `CLAUDE.md` § Working Style. This change updates its "Known breakage, not yet repaired" sub-bullet: it is replaced by a pointer to `task vet:fixtures` as the standing gate.
- **`cue vet`, including `-c`, does not check hidden fixtures; `cue export` does** — stated once beside the gate's row in the commands table, so the next author does not re-discover it.
- Both land in `CLAUDE.md` in the last section, with the gate.

## Open Questions

None.
