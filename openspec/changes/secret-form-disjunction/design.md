## Context

Files: `opm/resources/v1beta1/secret.cue` (`#SecretLiteral`, `#SecretK8sRef`, segment `v1beta1`), fixtures in `opm/transformers/secret_transformer.cue` and `opm/transformers/container_helpers.cue` (env `secretKeyRef` path, lines 55-84), `docs/struct-disjunctions.md`. Depends on `role-rule-disjunction` for the docs note only; the schema edit is independent.

Readers of the arms: `secret_transformer.cue:85-87` (`_entry.value != _|_`, `_entry.secretName == _|_`) and `container_helpers.cue:55-84` (`e.value`, `e.from.secretName`, `e.from.remoteKey`, `e.from.$secretName`). None changes.

## Goals / Non-Goals

**Goals:**
- `#Secret` resolves for a literal and for a reference in both authoring forms and through `#config` unification.
- The silent-drop path (`!= _|_` on an unresolved value) is closed by making the value resolve.

**Non-Goals:**
- Changing the `$opm`/`$secretName`/`$dataKey` discriminator contract or the transformer's dispatch.

## Decisions

**D-A. Negative optional fields, same idiom as `role-rule-disjunction`.**

```cue
#SecretLiteral: {#SecretType, value!: string, secretName?: _|_, remoteKey?: _|_}
#SecretK8sRef:  {#SecretType, secretName!: string, remoteKey!: string, value?: _|_}
```
Closedness, defaults and the required-field set of each arm are unchanged; a secret carrying both forms becomes an error.

**D-B. Fixtures exercise the `#config` path.** The embedded-form fixture types a field as `res.#Secret & {$secretName: *"app" | string, $dataKey: *"pw" | string}` (the `DESIGN_PATTERNS.md` 1 shape) and supplies `value` by unification, mirroring how a ModuleInstance supplies it; a second supplies `secretName`/`remoteKey`. Pins: the rendered Secret's data key for the literal, the `secretKeyRef.name`/`key` for the reference, both interpolated and checked with `cue eval -c`.

## Research & Decisions

### Does `#Secret` actually fail, or only `#PolicyRuleSchema`?
**Context**: same structure, but values usually arrive through `#config` unification rather than a literal in the component.
**Explored**: Probe 2026-08-29: `#Config & {pw: {..., value: "x"}}` copied into `{#Res, spec: secrets: pw: cfg.pw}`: `.value` is `unresolved disjunction`; `.value != _|_` is `false`. With D-A applied: `.value` resolves, a k8s-ref secret resolves to `secretName`, and `.value != _|_` on the reference is `false` for the right reason.
**Decision**: fix now, in its own slice.
**Rationale**: the failure is silent (missing env wiring), which is worse than the role transformer's hard error.

## Risks / Trade-offs

- A module that set both `value` and `secretName` on purpose -> none in the fleet (grep); refused with a clear error.
- `$`-prefixed discriminator fields are shared by both arms -> untouched; they never distinguished the arms.

## Durable decisions

- "`#Secret` is the second instance of the struct-disjunction rule; `value` and `secretName`/`remoteKey` are mutually refusing" -> `docs/struct-disjunctions.md` worked-case section (create the note if `role-rule-disjunction` has not landed).
