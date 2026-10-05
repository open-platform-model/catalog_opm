## 1. src/ comment sites

- [x] 1.1 `src/transformers/transformer_registration_transformer.cue`: the WHY block names `opm-controller` (cite `0015:D3`) and "the controller's TransformerRegistration CRD"; the doc comment says "the controller accepts"
- [x] 1.2 `src/transformers/transformer_registration_transformer_fixtures.cue`: "opm-controller sorts both lists"
- [x] 1.3 `src/resources/v1alpha1/transformer_registration.cue`: "The controller's acceptance refuses"
- [x] 1.4 `task generate:index`; the `#TransformerRegistrationTransformer` row reads "the controller accepts"
- [x] 1.5 `task check` green, then commit `docs(transformers): name the controller in the registration comments`

## 2. Repository prose

- [ ] 2.1 `AGENTS.md` Notify downstream bullet: "library, opm-controller and cli"
- [ ] 2.2 `.github/workflows/release.yml` `notify-downstream` comment: "opm-controller and cli"
- [ ] 2.3 `.tasks/branch-tag.sh` range-subscription comment: "the opm-controller's platform registry"
- [ ] 2.4 The residue grep (`opm[-_ ]?operator|operator-system|operatorVersion|...`) outside `CHANGELOG.md` and `openspec/changes/archive/` hits only `.tasks/cascade/wiring-check.sh`
- [ ] 2.5 `task check` green, then commit `docs: name opm-controller in the cascade prose`

## 3. Verify and archive

- [ ] 3.1 Verify the change against these artifacts (the `opsx:verify` skill)
- [ ] 3.2 Archive the change on this branch with `--skip-specs`
- [ ] 3.3 `openspec validate --all --strict` and `task check` green, then commit `chore(openspec): archive follow-controller-rename`
