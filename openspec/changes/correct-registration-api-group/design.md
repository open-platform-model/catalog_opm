## Context

See `proposal.md` for motivation. One file is touched, in the `opm` module only:

- `opm/transformers/transformer_registration_transformer.cue` — flat under `transformers/`, no `apiVersion` segment (transformers have none). It carries both the renderer (`#transform.output.apiVersion`, line 57) and the golden fixture (`_testTransformerRegistrationOutput.apiVersion`, line 115).

No contract member moves. `opm/resources/v1alpha1/transformer_registration.cue` — `#TransformerRegistrationResource`, `fqn` `.../resources/transformer-registration@v1alpha1` — is untouched: its `spec.transformerRegistration` fields (`catalog!`, `version!`, `provides!`) do not change, so no `apiVersion` segment moves and no `catalog.cue` listing changes. The `k8s` module is not reached.

The operator's CRD, the other side of this contract, is `opmodel.dev/v1alpha1` and already shipped (`opm-operator` PR 133).

## Goals / Non-Goals

**Goals:**

- The rendered `apiVersion` names the CRD the operator actually installs, so a provider module's claim can be applied for the first time.
- The renderer and its golden fixture stay in lockstep, enforced rather than remembered.
- The next author reads why the group belongs to the operator, at the line that carries it.

**Non-Goals:**

- Any change to `#TransformerRegistrationResource`'s schema, its `apiVersion` segment, or its `catalog.cue` entry.
- Anything about acceptance, activation or regeneration — those are the operator's, in three follow-on changes.
- Correcting `enhancements/0015/contracts/contracts.cue:145`, which carries the same prefixed literal in a pre-drafted shape. It is a design sketch, not a published artifact; the enhancements repo owns it.

## Decisions

### The literal moves in both places, in one edit

```cue
// Renderer (line 57)
output: {
	apiVersion: "opmodel.dev/v1alpha1"   // was "opm.opmodel.dev/v1alpha1"
	kind:       "TransformerRegistration"
}

// Golden fixture (line 115)
_testTransformerRegistrationOutput: {
	apiVersion: "opmodel.dev/v1alpha1"   // was "opm.opmodel.dev/v1alpha1"
	kind:       "TransformerRegistration"
}
```

Nothing else in the file changes: `metadata.name`, `metadata.labels`, and every `spec` field including `providerRef` are already correct, and the fixture's `_testTransformerRegistrationLabelCount` guard is unaffected.

**Alternative considered — move only the renderer and let the fixture be regenerated.** Rejected: there is no generator. The fixture is hand-written and is the only assertion of the rendered shape, so a one-sided edit is a build failure, not a regeneration (measured below).

### The `WHY` block gains the reason, not just the rule

The file already opens with a `WHY` block stating that the three strings are literals because nothing in a catalog can derive a CRD the operator owns. It does not say *which* group, or why a prefixed one is wrong. It gains that: the operator's API group is the flat `opmodel.dev` that enhancement 0002 D5 chose, rejecting prefixed and kind-specific groups. This is exactly the omission that produced the bug — the original author had the rule ("these are literals") without the value's source.

Per the doc-comment tiers in `CLAUDE.md`, this is rationale that must stay next to the code, so it belongs in the `WHY` block above the doc comment, not in the 6-line doc comment.

## Research & Decisions

### Both gates catch a one-sided edit, and `cue vet` alone is enough

**Context**: the renderer and the fixture carry the same literal. If only one moves, does the build fail, or does the drift ship?

**Explored**: changed line 57 only, leaving the fixture at the old value, and ran both gates (cue v0.17.1, 2026-09-15).

- `task vet` **fails**: `_testTransformerRegistrationOutput.apiVersion: conflicting values "opmodel.dev/v1alpha1" and "opm.opmodel.dev/v1alpha1"`, naming lines 57, 99 and 115.
- `task vet:fixtures` **fails**: same conflict, reported per fixture.

**Decision**: no new gate is needed; `task check` already covers this. The tasks file states the two edits as one atomic step rather than two.

**Rationale**: this confirms `CLAUDE.md`'s rule that an **error-class** conflict in a hidden field does fail `cue vet`, even though `cue vet` does not descend into hidden fields to check completeness. A changed golden literal is error-class, so it is caught by the cheaper gate. The incomplete-class failures are what `vet:fixtures` exists for, and that distinction stays intact.

### One conflicting fixture reports as every fixture failing

**Context**: reading the failure output, to know what a future author will see.

**Explored**: the `vet:fixtures` output for the one-sided edit.

**Decision**: record the diagnostic shape; no code change.

**Rationale**: the run printed `FAIL: opm — 47 of 47 rendered-output fixtures do not evaluate`, listing `_testTransformerRegistrationOutput.apiVersion` under `statefulset_transformer.cue`, `tcp_route_transformer.cue` and every other file. The fixtures are package-level hidden fields, so one error-class conflict poisons every export in the package and each file's failure names the *conflicting* field, not the file's own. A future author who changes one literal and sees "47 of 47" must read the field name in the message, not the file names, or they will hunt a catastrophe that is one line.

## Risks / Trade-offs

- [The published 4.3.0 keeps emitting the dead group until 4.3.1 releases] -> nothing consumes it: no provider catalog exists, no module attaches the contract, no fixture renders one. The window is unreachable rather than merely short.
- [A reviewer reads a changed transformer output as breaking and asks for a major crossing] -> the proposal answers it with 0010 D34: the promise is keyed to the level, and `v1alpha1` carries none. The member's schema is untouched regardless.
- [`enhancements/0015/contracts/contracts.cue` keeps the prefixed literal and re-seeds the bug in a later slice] -> out of scope here, but the `WHY` block now names the group's source, so the next implementer reads the correct value at the code rather than from the sketch.

## Durable decisions

- **The operator owns the group; it is the flat `opmodel.dev`.** Lands in the `WHY` block of `opm/transformers/transformer_registration_transformer.cue` as part of this change — it must sit at the literal it governs, which is the whole point of the fix.
- **One conflicting golden literal reports as every fixture in the module failing.** Lands as a line in `CLAUDE.md`'s existing `task vet:fixtures` bullet. The count in the message is not the blast radius; the field name in the message is.
- Everything else stays with the change.

## Open Questions

None.
