## 1. Rule correction (WHY block above the doc comment)

- [x] 1.1 `CLAUDE.md` § Working Style for Agents: WHY block ABOVE the doc comment, one blank line between; add the D3 one-sentence rule on what stays in the doc comment
- [x] 1.2 `openspec/config.yaml` § Code Style: same correction
- [x] 1.3 `.tasks/doc-check.sh`: header and warning message say "above"; `diff` against `core/.tasks/doc-check.sh` is empty
- [x] 1.4 Commit `docs(rules): move WHY blocks above the doc comment`

## 2. opm/blueprints/v1beta1

- [x] 2.1 `stateless_workload.cue` `spec` (8 lines)
- [x] 2.2 Per-file checks (D4) and commit `docs(blueprints): move rationale out of doc comments`

## 3. opm/identity, k8s/identity

- [x] 3.1 Confirm `opm catalog version set` preserves comments in `identity.cue` (D5)
- [x] 3.2 `opm/identity/identity.cue` `kindPrefix` (7 lines); `k8s/identity/identity.cue` `kindPrefix` (7 lines)
- [x] 3.3 Per-file checks and commit `docs(identity): move rationale out of doc comments`

## 4. opm/resources

- [x] 4.1 `v1alpha1/namespace.cue` `spec` (10), `#NamespaceSchema` (8)
- [x] 4.2 `v1beta1/configmap.cue` `exactName` (7)
- [x] 4.3 `v1beta1/container.cue` `matchLabels` (21), `gpus` (11)
- [x] 4.4 `v1beta1/crd.cue` `annotations` (10)
- [x] 4.5 `v1beta1/volume.cue` `mountPropagation` (14)
- [x] 4.6 Per-file checks and commit `docs(resources): move rationale out of doc comments`

## 5. opm/traits/v1beta1

- [x] 5.1 `disruption_budget.cue` `#DisruptionBudgetSchema` (9)
- [x] 5.2 `expose.cue` `name` (20), pointer to `docs/name-constraints.md`
- [x] 5.3 `network_policy.cue` `#NetworkPolicyTrait` (17)
- [x] 5.4 `pod_metadata.cue` `#PodMetadataSchema` (13)
- [x] 5.5 `resource_name.cue` `#ResourceNameSchema` (16), pointer to `docs/name-constraints.md`
- [x] 5.6 `runtime_class.cue` `#RuntimeClassTrait` (22)
- [x] 5.7 Per-file checks and commit `docs(traits): move rationale out of doc comments`

## 6. opm/transformers

- [x] 6.1 `container_helpers.cue` `#ToK8sContainer` (16), `#ToK8sVolumes` (10)
- [x] 6.2 `daemonset_transformer.cue` `_updateStrategy` (9); `deployment_transformer.cue` `_updateStrategy` (26); `statefulset_transformer.cue` `_updateStrategy` (13), `serviceName` (8)
- [x] 6.3 `hpa_transformer.cue` `#HPATransformer` (12); `pdb_transformer.cue` `#PDBTransformer` (12); `network_policy_transformer.cue` `#NetworkPolicyTransformer` (8); `secret_transformer.cue` `#SecretTransformer` (8)
- [x] 6.4 `name_helpers.cue` `#WorkloadName` (15), pointer to `docs/name-constraints.md`
- [x] 6.5 `pod_helpers.cue` `#PodTemplateMetadata` (15), `#PodSchedulingFields` (9); `sa_helpers.cue` `#ToK8sServiceAccount` (8)
- [x] 6.6 `service_transformer.cue` `port` (10)
- [x] 6.7 Per-file checks and commit `docs(transformers): move rationale out of doc comments`

## 7. k8s/resources/v1

- [x] 7.1 `object.cue` `#ObjectsResource` (7)
- [x] 7.2 Per-file checks and commit `docs(k8s): move rationale out of doc comments`

## 8. Strict flip and durable decisions

- [x] 8.1 `Taskfile.yml` `docs:check` passes `--strict`; desc "Fail on doc comments over 6 lines"
- [x] 8.2 `CLAUDE.md` command table and `openspec/config.yaml`: drop "warn-only until the sweep lands"; state that `task docs:check` fails
- [x] 8.3 Commit `chore(tasks): make docs:check strict`

## 9. Verification

- [x] 9.1 `task docs:check` reports 0 sites in both modules
- [x] 9.2 `task generate:index:check` (INDEX files unchanged)
- [x] 9.3 All 25 touched `*.cue` files code-identical to `main` (comments and blank lines stripped); `cue fmt` idempotent
- [x] 9.4 `task check`
