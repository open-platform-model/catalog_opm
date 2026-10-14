# Transformer fixtures and the rendered-output gate

Covers where a transformer fixture lives, how it is built so that it evaluates, why `cue vet` alone is not enough, and the gates `task vet:fixtures` and `task vet:fixtures:tagged`. 

## Where a fixture lives

- A fixture lives in `<name>_fixtures.cue` beside the member's file. The file attribute `@if(fixtures)` above the package clause keeps it out of a plain build. It never goes in the definition file and never in a `_test.cue` file.
- A plain build (every consumer, an editor, `cue vet ./...`) leaves tagged files out, and a tag never reaches a consumer: the loader treats every tag as unset outside the main module.
- The cue CLI has no test mode, so it silently drops `x_test.cue` from `cue vet ./...` and the fixtures there would never be checked.
- `task vet:fixtures:tagged` (`.tasks/fixture-tags.sh`) refuses a top-level `_test*` field in a file whose `@if(fixtures)` line is missing, commented out or compound. It is text only and offline. CI runs it in `Validate catalog` before the registry login.
- Raw fixture commands need `-t fixtures`: `cue eval -c -t fixtures -e _test... ./transformers` and `cue export -t fixtures -e _test... ./transformers`. Without it the field is "not found". The tag is valid only for a package that holds a fixture file, or over `./...`. Elsewhere cue refuses it with `tag "fixtures" not used in any file`.

## The standing gate

- `task vet:fixtures` is in `task check`. It exports every field declared `_test<Name>: (#<Transformer>.#transform & {` under `src/transformers/` and fails naming the file and field. There are 71 such fixtures (counted 2026-10-14 with the selector in `.tasks/fixtures.sh`).
- `cue vet` evaluates the hidden fields of the package it vets and fails on an error-class conflict in one. It passes one that stays incomplete, with or without `-c`. The two checks are complementary: `cue vet` enforces a golden literal once the value is concrete, and the gate makes the value concrete in the first place.
- Measured 2026-09-15 (cue v0.17.1, core v2.0.0-alpha.9): 44 of the 47 fixtures then in the transformers failed export while `cue vet ./...` exited 0. Every fixture evaluates now, and one that stops evaluating fails the build.
- Read the field name in the failure, not the count. Fixtures are package-level hidden fields, so one error-class conflict in a single golden literal poisons every export in the module. The gate then reports "N of N rendered-output fixtures do not evaluate", and each file's entry names the conflicting field rather than its own. The first error line under each `FAIL` names the cause.
- The selector keys on the `#transform` form, not on a naming convention, so renaming a fixture keeps it covered. Sweeping every hidden `_test*` field would report about 90 known-acceptable failures, mostly `_test*Component` fixtures whose attached primitives carry schemas and are non-concrete by design.

## Inputs

- A fixture supplies `#transform.#moduleInstance`, never `#context.#moduleInstanceMetadata`. Since core alpha.7 `#moduleInstanceMetadata` is a projection computed at the `#transform` site from `#moduleInstance` (enhancement 0019). A fixture that fills it leaves `#moduleInstance` at `_`, and the rendered output never becomes concrete.
- The right spelling is `#moduleInstance: {metadata: {name, namespace, fqn, uuid}, #moduleMetadata: version: ...}` plus `#context: #runtimeName: ...`. The wrong spelling is `#context: #moduleInstanceMetadata: {...}`.
- `cue vet` does not catch the wrong spelling: the failure is incomplete-class. Measured 2026-09-14 (cue v0.17.1): export fails with `#moduleInstance.metadata undefined as #moduleInstance is incomplete (type _)` while `cue vet` exits 0. Working examples: `src/transformers/transformer_registration_transformer_fixtures.cue` and `src/transformers/pvc_transformer_fixtures.cue`.
- The component fixture, not the context, carries the component's name. `#context.componentLabels` reads `#component.metadata.name`, so a component stub with no `metadata.name` fails export with `required field missing: name`. Do not put it back on the context as `#componentMetadata`.
- A nested `#transform` inside a guard field needs `#moduleInstance` too. The gate's selector enumerates only top-level fixtures, so a guard such as `[if (#X.#transform & {...}).output.spec.replicas != _|_ {...}] & [3]` passes vacuously when its inner transform is incomplete. Supply the input at every call site.

## Golden literals

- A golden literal unifies onto the render, so it asserts presence, never absence. A key the render does not produce is silently added to the fixture rather than rejected. This is how `role_transformer.cue` carried an `app:` label for months that the transformer never rendered.
- Assert absence with the explicit `] & []` comprehension guard the workload transformers use. Never assert it by omitting a key from a golden block.
- An interpolation pin does not catch an absent optional field. Interpolating a missing field (`"\(x.seccompProfile.type)" & "RuntimeDefault"`) is incomplete, not an error, so `cue vet` passes it when the transformer stops rendering the field.
- A one-element list guard does catch it: `[if x.f != _|_ {x.f.type}] & ["RuntimeDefault"]` fails with `incompatible list lengths (0 and 1)`. Measured 2026-10-04 (CUE v0.17.1): removing `seccompProfile` from the Deployment's pod-level guard passed an interpolation pin and failed the list guard.

## Pitfalls

- Trusting `cue vet` for a golden literal: run `task vet:fixtures`, or `cue export -t fixtures -e <fixture> ./transformers`.
- Putting a fixture in the definition file or in `x_test.cue`.
- Filling `#context.#moduleInstanceMetadata` in a fixture.
- Omitting a key to assert absence.
- Reading the failure count instead of the field name when one literal poisons the package.
- Running `cue eval -t fixtures` on a package with no fixture file.
- `task fmt:check` formats and then diffs the git index: stage first, or a correct edit reads as a failure.

## Check before you finish

- [ ] `task vet:fixtures` and `task vet:fixtures:tagged` pass.
- [ ] Every new `_test*` field sits in a file that opens with `@if(fixtures)`.
- [ ] Absence is asserted with `] & []`, and optional-field presence with a one-element list guard.
- [ ] The fixture supplies `#moduleInstance`, and the component stub has `metadata.name`.
