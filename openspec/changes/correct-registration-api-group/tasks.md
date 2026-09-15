# Tasks: correct-registration-api-group

One section. design.md's two research entries are measurements already taken, not assumptions to
prove, so section 1 is not a spike. No definition is added, removed or renamed, so
`task generate:index` is not needed — `INDEX.md` extracts doc comments, and only the `WHY` block
above the doc comment changes.

## 1. opm — the rendered API group

- [x] 1.1 In `opm/transformers/transformer_registration_transformer.cue`, change **both** occurrences of `"opm.opmodel.dev/v1alpha1"` to `"opmodel.dev/v1alpha1"`: the renderer's `#transform.output.apiVersion` (line 57) and the golden fixture `_testTransformerRegistrationOutput.apiVersion` (line 115). One edit, not two steps — a one-sided change fails `task vet` with a conflicting-values error naming both lines. Verify: no `opm.opmodel.dev` remains anywhere in `opm/`.
- [x] 1.2 Extend the file's `WHY` block (above the doc comment, per `CLAUDE.md`'s doc-comment tiers) with the group's source: the operator's API group is the flat `opmodel.dev` that enhancement 0002 D5 chose, rejecting prefixed and kind-specific groups, so a prefixed group here names a CRD that does not exist. Verify: the block says which group and why, not only that the strings are literals.
- [x] 1.3 Add one line to the `task vet:fixtures` bullet in `CLAUDE.md` (design.md § Durable decisions): one error-class conflict in a golden literal poisons every export in the module, so the failure reports as "N of N rendered-output fixtures do not evaluate" and each file's entry names the *conflicting* field rather than its own — read the field name, not the count. Verify: the line sits with the existing fixtures guidance, not in a new section.
- [x] 1.4 `task check` green (fmt check, vet, layering, listing, rendered-output fixtures, INDEX freshness, doc-comment limit), then commit `fix(transformers): render TransformerRegistration in the operator's API group`.
