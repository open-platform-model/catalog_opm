## Context

See `proposal.md` for motivation. Files and segments:

- `opm/transformers/pvc_transformer.cue`: one label added to the PVC's `metadata.labels`. Flat transformer file, no segment.
- `opm/traits/v1alpha1/backup.cue` and `opm/traits/v1alpha1/backup_command.cue`: new directory, `package v1alpha1`, the first `v1alpha1` traits in the module (resources already have a `v1alpha1` segment). Filing per 0010 D49: `modulePath: "\(id.kindPrefix.traits)/v1alpha1"`, `fqn` flat.
- `opm/schemas/common.cue`: `#CronSchema` beside `#NameType`. The `schemas` package cannot import core, so it holds plain types.
- `opm/catalog.cue`: both traits keyed into `#traits`, behind a new `tra` alias for the `v1alpha1` traits segment. Filing is only half a member's registration; `task vet:listing` enforces the other half.
- `docs/transformer-authoring.md` (new), `CLAUDE.md` (one pointer line and one rule), `opm/INDEX.md` (regenerated).

Constraints: doc comments at most 6 lines (`task docs:check`); the publish gates run locally as `opm catalog publish ./opm --dry-run` (exit 0 is GO), which is what catches a trait whose `optional` is pinned. The measured shape this change lands is `enhancements/0015/experiments/02-policy-and-command/contracts/traits/v1alpha1/`; deviations are listed under Research & Decisions.

## Goals / Non-Goals

**Goals:**
- Ship the two traits exactly as measured on both engines, minus what has no consumer.
- Make per-volume selection possible for any adapter (P1), with the label name fixed here so adapters agree on it.
- Land the adapter-authoring rules the experiments paid for where provider-catalog authors will find them.

**Non-Goals:**
- No transformer for either trait: the declaring catalog of a provider-fulfilled contract ships none (0010 D37). No stub transformer either, ever; it would count as a provider.
- No `executor` switch and no policy projection (deferred; additive when a module needs it).
- No repository resolution: `repository` is a name the provider resolves from platform configuration (0015 OQ2).
- No change to `cron_job_config`'s untyped `scheduleCron`; typing it later is a tightening and its own decision.

## Decisions

**D-A. P1: the volume key as a PVC label.**

```cue
labels: #context.labels & {"volume.opmodel.dev/name": volumeName}
```

`#context.labels` accepts an extra key by unification (measured, experiment 02 case P1); `#context.componentLabels` does not (closed). The key is the component's volume map key, which is what `backup.volumes` names, so the two sides agree by construction. Rendered output changes by one label on every PVC; no spec field moves, so no PVC is recreated.

**D-B. `backup@v1alpha1`, the policy.** Shape as in the proposal's After block. Points that are decisions rather than transcription:

- `optional: bool | *false`: load-bearing. An unhandled backup means there are no backups; a module may narrow to `true` at the attachment site (0010 D28).
- `appliesTo: [res.#VolumesResource]`: the policy is about persistent state; a component without volumes has nothing to back up.
- `repository?: sch.#NameType`: a platform-registered name. Inline object storage is refused by shape, because on Velero a location is an admin object and on k8up the credentials Secret must be in the instance namespace; both are the platform's, never the module's.
- `volumes?: [string, ...string]`: absent means all. Needs D-A.
- `method`, `excludes`, `maintenance` are advisory under the keep-more rule: an adapter that ignores any of them captures at least as much. A field whose wrong reading could lose data would be a contract, not a field; none of these is.
- Retention: keep counts plus `keepWithin`, at least one tier (`matchN`). Adapters with one span (Velero `ttl`) take the longest tier; adapters with counts map directly.

**D-C. `backup-command@v1alpha1`, the producer.** Three deviations from the experiment's file:

- `optional: bool | *false`, not the pinned `optional: false`. The trait-optional publish gate refuses a pinned posture (`#TraitOptionalGate`, core §5.1); the experiment never ran publish.
- `command!: string & !=""`, without the experiment's `!~"'"`. The single-quote ban was k8up's `sh -c '...'` wrapping leaking into the contract. Escaping is the adapter's job; the contract says "a shell line".
- `compensate?: string & !=""`, a shell line like `command`, not an exec array. Both run through a shell hook; one shape.

`fileExtension?` has no default (the experiment's `.sql` was wrong for the Minecraft case). Absent, an adapter derives it from `landing.path` or applies its own default. `landing?` stays optional: a stream-consuming engine ignores it, a file-capturing engine needs it and refuses a component without one at render, naming the field.

**D-D. `#CronSchema` in `opm/schemas/common.cue`.** Five whitespace-separated fields. Engine tokens (`@daily`) are not admitted at the contract; an adapter may add its own where it renders its own schedules (k8up's `@daily-random` for prune).

**D-E. Category `storage`** for both traits, the category the volumes resource already uses.

Closedness, defaults, required-set: both traits are new, closed definitions; `#BackupSchema` requires `schedule` and `retention`, `#BackupCommandSchema` requires `container` and `command`. The PVC transformer's output gains one label; its inputs are unchanged.

## Research & Decisions

### Executor switch and projection deferred

**Context**: Experiment 02's policy carries `executor: *"platform" | "module"` and a projection function every adapter calls under `module`.
**Explored**: The fleet (`modules/`) for a consumer: no module runs its own backup tool; jellystat exports backups into a volume, which is the `volumes` case, not the executor case. The projection's values (`RESTIC_REPOSITORY`, `--keep-*` flags) are one tool's convention.
**Decision**: ship without `executor` and without the projection.
**Rationale**: Principle V, a field with no module expressing it is surface without a consumer; and adding the field later is additive. The projection would bake restic's convention into the abstraction catalog for a fixture.

### The trait-optional gate against the experiment's files

**Context**: `backup-command` in the experiment pins `optional: false`.
**Explored**: `cli/internal/publish/catalog_gates.go` `gateTraitOptional` unifies each trait's `optional` against core's `#TraitOptionalGate`, which refuses a concrete value ("does not state an overridable optional posture"). The experiment served its catalog by directory replacement and never ran the gates.
**Decision**: `optional: bool | *false`; section 2's commit task runs `opm catalog publish ./opm --dry-run`.
**Rationale**: the gate is the rule; a posture is a default the attachment may narrow.

### What the experiments measured about adapter authoring

**Context**: Three evaluator behaviours forced modifications during experiment 02's run, and every provider catalog will hit them.
**Explored**: (i) an `error()` fallback in a transformer fired at platform build, where a definition is evaluated once with no component, and refused every platform carrying the catalog; (ii) `#context.componentLabels & {extra: v}` is `field not allowed`, surfaced only as an opaque transformer error at render; (iii) a field computed from the component (`list.Max` over retention tiers) failed the platform build unless guarded on presence.
**Decision**: record all three in `docs/transformer-authoring.md` with the label-key rule from D-A.
**Rationale**: this repo is where adapter authors copy shapes from; an archived change must not be the only home of an authoring rule.

## Risks / Trade-offs

- [No provider exists at release, so attaching either trait refuses the render] -> designed (0010 D28, D37): the refusal names the contract; the k8up provider catalog is the next change outside this repo. Under 0015 D18 a platform subscribing this catalog keeps generating.
- [Every existing PVC changes on the next reconcile] -> one label, applied in place by SSA; no immutable field moves. Stated in the proposal's Impact.
- [Quoting moves to adapters; a k8up adapter that wraps naively breaks on a `'` in `command`] -> the authoring note says so; the adapter escapes or uses an exec form.
- [Alpha shape, first consumer is a provider catalog rather than a module] -> alpha promises nothing (0010 D34); a shape change is a new `v1alpha2` file, not an in-place mutation.

## Durable decisions

- "`volume.opmodel.dev/name` is the per-volume selection key: the PVC transformer stamps the component's volume map key on every PVC, and an adapter selecting one of a component's volumes MUST match on it" -> `docs/transformer-authoring.md` (new).
- "Validation inside a transformer is a unification, never `error()`: a definition is evaluated once at platform build with no component, and a bottom there refuses every platform carrying the catalog. Any field computed from the component MUST be guarded on presence" -> same note.
- "`#context.componentLabels` is closed; build label maps by comprehension, and add keys to `#context.labels` by unification" -> same note.
- "A `fulfilment: "provider"` member ships no transformer here and never a stub: a stub is a provider and the first real one becomes the second" -> `CLAUDE.md` Working Style, beside the closedness pointer, with the pointer line to the note.
