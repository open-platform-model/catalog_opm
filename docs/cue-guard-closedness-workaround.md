# Authoring rule: hoist `if … != _|_` propagation guards out of `spec`

**Status:** Active workaround (2026-07-04). Re-evaluate when the CUE toolchain
moves past `v0.17.0`.

## The rule

In a `#Component`/blueprint definition, never write an existence guard whose
condition references a **nested non-scalar field** (struct or list) *inside*
the `spec` block:

```cue
// WRONG — trips a CUE evaluator regression (v0.17.0-alpha.2 … v0.17.0):
// "spec.statelessWorkload.scaling: field not allowed"
spec: {
    statelessWorkload: #StatelessWorkloadSchema
    if spec.statelessWorkload.scaling != _|_ {
        scaling: spec.statelessWorkload.scaling
    }
}
```

Hoist the guard to component level and write through `spec:` instead:

```cue
// RIGHT — semantics-identical, evaluates cleanly on all CUE versions
spec: {
    statelessWorkload: #StatelessWorkloadSchema
}
if spec.statelessWorkload.scaling != _|_ {
    spec: scaling: spec.statelessWorkload.scaling
}
```

All five workload blueprints (`src/blueprints/workload/*.cue`) follow the
hoisted form. Keep new blueprints consistent with it.

## Why

CUE `v0.17.0-alpha.2` introduced an evaluator closedness regression that
**shipped in the final `v0.17.0` release**: an `if <path> != _|_` comprehension
guard evaluated inside a closed spec struct, whose condition path traverses a
nested struct- or list-valued field, causes that field to be spuriously
rejected as `field not allowed` — as if the enclosing schema did not declare
it. `v0.16.0` and `v0.17.0-alpha.1` (the version the OPM kernel pins) are
unaffected.

Empirically established boundaries (full bisection matrix in the library repo,
`docs/design/cue-closedness-regression-alpha2.md`):

- The **guard condition** is the trigger — the guarded field errors even if
  the body copies nothing.
- **Unconditional** references/copies of the same field are fine.
- **Scalar/enum-valued** fields (e.g. `restartPolicy`) are exempt; struct- and
  list-valued fields are affected.
- Nothing else matters: optional vs required, hidden vs public destination,
  copy mechanism (`let`/spread/embed), schema definition identity, opening the
  nested schema with `...`, or removing `close()` upstream — all were varied
  independently with no effect.

An alternative workaround (guarding on a required/defaulted scalar leaf, e.g.
`if spec.….scaling.count != _|_`) also works but depends on each schema's
internals and does not cover list-valued fields; the hoisted form is uniform,
so the catalog standardizes on it.

## Verification recipe

Reproduce/verify with a module that sets a guarded field (e.g. the workspace
`modules/web_app`, which sets `scaling` + `updateStrategy`):

```bash
GOBIN=/tmp/cue-check go install cuelang.org/go/cmd/cue@v0.17.0
( cd modules/web_app && /tmp/cue-check/cue vet ./... )   # must be clean
```

Go-kernel-level canary (library repo): `go test ./opm/kernel -run
TestIntegration_Live_ValidateRealConfig`.

## References

- Full forensic analysis + version matrix: `library/docs/design/cue-closedness-regression-alpha2.md`
  (library repo — covers the kernel pin on `cuelang.org/go v0.17.0-alpha.1`).
- **Upstream issue:** [cue-lang/cue#4423](https://github.com/cue-lang/cue/issues/4423)
  — same regression, independently reported 2026-07-02 and bisected to commit
  `339485ddf008` (`internal/core/adt: dependency-tracking comprehension
  pushdown`), the v0.17.0-alpha.2 comprehension-algorithm redesign. Retire this
  workaround only after that issue is fixed in a released CUE version and the
  OPM toolchain has moved past it.
