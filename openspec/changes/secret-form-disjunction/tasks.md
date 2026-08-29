## 1. opm/resources/v1beta1/secret.cue

- [ ] 1.1 Add `secretName?: _|_`, `remoteKey?: _|_` to `#SecretLiteral` and `value?: _|_` to `#SecretK8sRef` (D-A); WHY block above `#Secret`; doc comments within the 6-line cap.

## 2. Fixtures

- [ ] 2.1 `opm/transformers/secret_transformer.cue`: embedded-form component whose secret arrives through a `res.#Secret`-typed config field (literal); pin the rendered Secret's data key by interpolation (D-B).
- [ ] 2.2 `opm/transformers/container_helpers.cue`: embedded-form fixture with one literal and one k8s-ref env secret; pin `secretKeyRef.name`/`key` for the reference and the prefixed name for the literal.
- [ ] 2.3 Negative fixture: a secret with both `value` and `secretName` is refused.

## 3. Durable decisions

- [ ] 3.1 `docs/struct-disjunctions.md`: add the `#Secret` worked case (create the note if absent).

## 4. Verification

- [ ] 4.1 `task check`.
- [ ] 4.2 `cue eval -c` over the new fixtures (from `opm/`).
- [ ] 4.3 Byte-identity: `cue export` the existing secret and container-helper goldens before and after; identical.
