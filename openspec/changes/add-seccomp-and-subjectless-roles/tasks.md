## 1. Seccomp profile (0028:D12:R1): src/resources/, src/traits/, src/transformers/

- [ ] 1.1 Gate check: this change has no upstream gate (wave 1 of 0028). Confirm the branch is based on current `origin/main` (`git fetch && git merge-base --is-ancestor origin/main HEAD`) and `task check` is green before the first edit; if it is red on the base, stop and report instead of fixing unrelated failures here.
- [ ] 1.2 `src/resources/v1beta1/container.cue`: add `seccompProfile?: #SeccompProfileSchema` to `#SecurityContextSchema` and the three definitions `#SeccompProfileSchema`, `#SeccompProfileBuiltinSchema`, `#SeccompProfileLocalhostSchema` (design D-A), each with a doc comment of at most 6 lines and a `// WHY` block pointing at `docs/struct-disjunctions.md` for the `localhostProfile?: _|_` arm.
- [ ] 1.3 `src/traits/v1beta1/security_context.cue`: reword the doc comment's first sentence and `metadata.description` to "Pod-level security settings for a workload: user, groups and seccomp profile" (design D-E), word for word identical.
- [ ] 1.4 `src/transformers/container_helpers.cue`: render `seccompProfile` inside `#ToK8sContainer`'s `securityContext` block when set (design D-B).
- [ ] 1.5 Pod level, design D-B: in `deployment_transformer.cue`, `statefulset_transformer.cue`, `daemonset_transformer.cue`, `job_transformer.cue` and `cronjob_transformer.cue`, add `|| _sc.seccompProfile != _|_` to the pod-level presence guard and render `seccompProfile` inside the pod `securityContext`. Touch nothing else in those blocks (the `fsGroup` gap in job/cronjob is a follow-up).
- [ ] 1.6 `src/transformers/container_helpers_fixtures.cue`: a container with a `Localhost` profile renders `type` and `localhostProfile` (presence-list guards, design D-F); a container with no `seccompProfile` renders none (absence guard); a `RuntimeDefault` profile carrying `localhostProfile` is refused against `res.#SeccompProfileSchema` (`] & []` negative idiom).
- [ ] 1.7 Each of the five workload `*_transformer_fixtures.cue`: one embedded-form component with `tr.#SecurityContext` setting only `securityContext: seccompProfile: type: "RuntimeDefault"` (no other pod-level field, so the guard itself is under test), declared `_test<Name>: (#<T>.#transform & {...}).output`; assert pod-level `seccompProfile.type` with a presence-list guard and that no `localhostProfile` leaked. The Deployment fixture also sets a container-level `Localhost` profile and asserts it on `containers[0]`. Confirm at least the Deployment guard fails when `|| _sc.seccompProfile != _|_` is temporarily removed, then restore it.
- [ ] 1.8 `task generate:index` (three definitions added, one description changed); review the `src/INDEX.md` diff.
- [ ] 1.9 Confirm every existing golden exports unchanged: `cue export -t fixtures -e <field> ./transformers` for the workload goldens touched by 1.5, compared against the same export on `origin/main`.
- [ ] 1.10 `task check` green, then commit `feat(catalog): add a seccomp profile to the workload security context`

## 2. Roles with no subjects (0028:D12:R2, R3): src/resources/, src/transformers/

- [ ] 2.1 `src/resources/v1beta1/role.cue`: `subjects!` becomes `subjects?`, still `[...#RoleSubjectSchema] & [_, ...]` (design D-C). Reword the `#RoleResource` doc comment and `metadata.description` to say subjects are optional and that a role without them renders no binding; keep the description the first sentence of the doc comment, word for word.
- [ ] 2.2 `src/transformers/role_transformer.cue`: guard `_k8sSubjects` and the RoleBinding and ClusterRoleBinding arms on `_role.subjects != _|_` (design D-D); leave every object body unchanged; update the transformer's doc comment to name the role-only output.
- [ ] 2.3 `src/transformers/role_transformer_fixtures.cue`: embedded-form subject-less ClusterRole (a `nonResourceURLs` rule, the shape of the operator's `metrics-reader`) and subject-less namespace Role, each declared `_test<Name>: (#RoleTransformer.#transform & {...}).output`; assert `(len(out) + 0) & 1` and the kind by interpolation; add a negative fixture that `subjects: []` is still refused against `res.#RoleSchema`.
- [ ] 2.4 R3: add a golden for `_testNsRoleTransformer` (namespace Role plus RoleBinding, as a closed two-element list, labels spelled out) so both scopes have a with-subjects golden; confirm `cue export -t fixtures -e _testExtendedRulesTransformer ./transformers` is byte-identical to `origin/main`. Confirm the length guard fails when the ClusterRoleBinding arm's subjects guard is temporarily removed, then restore it.
- [ ] 2.5 `task generate:index` (description changed); review the `src/INDEX.md` diff.
- [ ] 2.6 `task check` green, then commit `feat(catalog): render a role with no subjects without a binding`

## 3. Durable decisions: docs/

- [ ] 3.1 `docs/transformer-authoring.md`: new section 7, the shared-security-context wiring rule and the presence-list assertion rule (design.md Durable decisions, both entries).
- [ ] 3.2 `task check` green, then commit `docs(catalog): note the shared security context wiring rule`
