# Authoring rule: hoist `if … != _|_` propagation guards out of `spec`

**Status:** Permanent authoring rule (re-confirmed 2026-07-16 against CUE `v0.17.1`).
**Do not retire it.** The underlying evaluator bug is still unfixed, and since the OPM
toolchain moved to `v0.17.1` this rule is the only thing keeping the catalog off the
trigger. Retiring it breaks rendering immediately.

## The rule

In a `#Component`/blueprint definition, never write an existence guard whose
condition references a **nested non-scalar field** (struct or list) *inside*
the `spec` block:

```cue
// WRONG — trips a CUE evaluator regression (v0.17.0-alpha.2 through v0.17.1, unfixed):
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
**shipped in the final `v0.17.0` release and is still present in `v0.17.1`**: an
`if <path> != _|_` comprehension guard evaluated inside a closed spec struct,
whose condition path traverses a nested struct- or list-valued field, causes that
field to be spuriously rejected as `field not allowed` — as if the enclosing
schema did not declare it.

Measured version matrix (fresh `CUE_CACHE_DIR` per run, 2026-07-16):

| CUE version | pre-workaround (in-spec guard) | hoisted form |
| --- | --- | --- |
| `v0.16.x` | clean | clean |
| `v0.17.0-alpha.1` | clean | clean |
| `v0.17.0` | **FAIL** | clean |
| `v0.17.1` | **FAIL** (unfixed) | clean |

**`v0.17.1` did not fix this.** It fixed upstream [#4423](https://github.com/cue-lang/cue/issues/4423)
*as filed* (a different symptom — `adding field … not allowed as field set was
already referenced`), which OPM's report was conflated with. OPM's symptom
(`field not allowed`) is a distinct, still-unreported bug, most likely a sibling
from the same `339485ddf008` comprehension-pushdown redesign.

Empirically established boundaries (full bisection matrix in the library repo,
`docs/design/cue-closedness-regression-alpha2.md`):

- The **guard condition** is the trigger — the guarded field errors even if
  the body copies nothing.
- **Unconditional** references/copies of the same field are fine.
- **Scalar/enum-valued** fields (e.g. `restartPolicy`) are exempt; struct- and
  list-valued fields are affected. This is why the error names `scaling` and
  `updateStrategy` but never `restartPolicy`.
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
GOBIN=/tmp/cue-check go install cuelang.org/go/cmd/cue@v0.17.1
( cd modules/web_app && /tmp/cue-check/cue vet ./... )   # must be clean
```

Note the CUE module cache is keyed by `module@version`, **not** by registry — so
republishing different content under the same `module@version` resolves the stale
cached copy. Use a fresh `CUE_CACHE_DIR` (cache lives at `~/.cache/cue`) for any
version comparison, or replace the dep via `cue.mod/local-module.cue`, which
bypasses the cache.

**The old Go canary is dead.** `TestIntegration_Live_ValidateRealConfig` in the
library repo no longer detects this: it resolves the catalog, and the catalog now
carries the workaround, so it passes on broken and fixed CUE alike. The live guard
is the standalone reproducer committed in the library repo, which asserts the bug
is still present and fails loudly when upstream finally fixes it — that failure is
the signal to retire this rule.

## References

- Full forensic analysis + version matrix: `library/docs/design/cue-closedness-regression-alpha2.md`.
- **Upstream issue:** [cue-lang/cue#4423](https://github.com/cue-lang/cue/issues/4423)
  — reported 2026-07-02, bisected to commit `339485ddf008` (`internal/core/adt:
  dependency-tracking comprehension pushdown`), the v0.17.0-alpha.2
  comprehension-algorithm redesign. Closed COMPLETED 2026-07-10 and fixed in
  `v0.17.1` — **but only for the symptom as filed.** OPM's symptom survives and has
  not been reported upstream yet.

Retire this rule only when the library's standalone reproducer starts passing on a
released CUE version — not merely because #4423 is closed, and not because the
toolchain has moved past `v0.17.0`.
