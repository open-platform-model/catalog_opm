## 1. opm/resources/v1beta1/role.cue

- [x] 1.1 Add `nonResourceURLs?: _|_` to `#ResourcePolicyRuleSchema` and `apiGroups?: _|_`, `resources?: _|_`, `resourceNames?: _|_` to `#NonResourcePolicyRuleSchema` (D-A), with a `// WHY` block above `#PolicyRuleSchema` and doc comments within the 6-line cap.

## 2. opm/transformers/role_transformer.cue

- [x] 2.1 Add `_testEmbeddedRoleComponent` in the embedded form (`{res.#Role, spec: role: ...}`) with a plain rule, a `resourceNames` rule and a `nonResourceURLs` rule; render through `#RoleTransformer.#transform`; pin `apiGroups`, `resourceNames`, `nonResourceURLs` and `verbs` of each rule by interpolation (D-B).
- [x] 2.2 Add a negative fixture proving a rule with both `apiGroups` and `nonResourceURLs` is refused (list-length guard over `[if (rule & res.#PolicyRuleSchema) != _|_ {1}] & []`, or the repo's established negative idiom).

## 3. Durable decisions

- [x] 3.1 `docs/struct-disjunctions.md`: the rule, the measured embedding behaviour, the `other?: _|_` idiom, and the embedded-form fixture requirement.
- [x] 3.2 `CLAUDE.md` Working Style: one pointer line to the note beside the closedness-workaround pointer.

## 4. Verification

- [x] 4.1 `task check`.
- [x] 4.2 `cue eval -c -e '_testEmbeddedRoleTransformer' ./transformers` (from `opm/`) renders all three rules concrete.
- [x] 4.3 Byte-identity: `cue export` the existing `_testExtendedRulesTransformer` golden before and after; identical. (Measured with `cue eval`; `cue export` is refused by the pre-existing incomplete `#context` in the fixtures, which predates this change.)
