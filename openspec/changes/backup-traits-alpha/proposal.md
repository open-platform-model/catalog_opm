## Why

The catalog has no backup contract, and the provider-fulfilled shape core reserves for it (`fulfilment: "provider"`, 0010 D37) has no first instance anywhere: a module today cannot even say "back up this component". Two experiments under `enhancements/0015` settled the shape on the shipped kernel: `01-provider-trait-across-catalogs` rendered a policy trait through k8up and Velero adapters, and `02-policy-and-command` (2026-09-13) added the one thing a module can hand an engine, a command that writes a consistent artefact, and rendered a MariaDB and a Minecraft module on both engines with no engine-specific arm. Alpha promises nothing (0010 D34), so the measured shape ships now as `v1alpha1`, and the first provider catalog is cut against it instead of against a fixture.

## What Changes

- `opm/transformers/pvc_transformer.cue`: every rendered PVC gains the label `volume.opmodel.dev/name: <volume key>` (the experiments' prerequisite P1). Without it no adapter can select one of a component's volumes, and the policy's `volumes` field is unimplementable. Additive: a label on a mutable object.
- `opm/traits/v1alpha1/backup.cue` (new segment directory, package `v1alpha1`): the policy trait `backup@v1alpha1`. Provider-fulfilled, load-bearing by default (`optional: bool | *false`), applies to the volumes resource. Fields: `schedule`, `retention` (keep counts or `keepWithin`, at least one tier), `repository` (a platform-registered name, never inline storage), `volumes` (component volume keys, needs P1), and three advisory fields under the keep-more rule: `method`, `excludes`, `maintenance`.
- `opm/traits/v1alpha1/backup_command.cue`: the producer trait `backup-command@v1alpha1`. Provider-fulfilled, load-bearing by default, applies to the container resource. Fields: `container`, `command` (a shell line writing the artefact to stdout, quiesce inside it), `volumes`, `landing`, `fileExtension`, `compensate`.
- `opm/schemas/common.cue`: `#CronSchema`, the five-field cron the policy's schedules are typed on.
- `docs/transformer-authoring.md` (new) and a `CLAUDE.md` pointer: three adapter-authoring rules the experiments measured, which every provider catalog will copy from here.

Deferred from the experiment, deliberately: the `executor: platform | module` switch and the policy-projection function (no fleet module runs its own backup tool; the only consumer is the Minecraft fixture, and the projection's values are restic-shaped), the stand-in repository table (platform configuration, 0015's OQ2), and the k8up and Velero adapters (provider catalogs). Listing every member in the contract maps core `alpha.8` added is its own change.

## Before / After

**Before**

```cue
// opm/transformers/pvc_transformer.cue
metadata: {
	name:      "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)-\(volumeName)"
	namespace: #context.#moduleInstanceMetadata.namespace
	labels:    #context.labels
}

// opm/traits/v1alpha1/backup.cue          none
// opm/traits/v1alpha1/backup_command.cue  none
```

**After**

```cue
// opm/transformers/pvc_transformer.cue
metadata: {
	name:      "\(#context.#moduleInstanceMetadata.name)-\(#context.#componentMetadata.name)-\(volumeName)"
	namespace: #context.#moduleInstanceMetadata.namespace
	labels:    #context.labels & {"volume.opmodel.dev/name": volumeName}
}

// opm/schemas/common.cue
#CronSchema: string & =~"^(\\S+\\s+){4}\\S+$"

// opm/traits/v1alpha1/backup.cue
#BackupTrait: c.#Trait & {
	metadata: {name: "backup", apiVersion: "v1alpha1", ...}
	fulfilment: "provider"
	optional:   bool | *false
	appliesTo: [res.#VolumesResource]
	spec: backup: #BackupSchema
}
#BackupSchema: {
	schedule!:   sch.#CronSchema
	retention!:  #BackupRetentionSchema
	repository?: sch.#NameType
	volumes?: [string, ...string]
	method: *"any" | "snapshot" | "filesystem"
	excludes?: [...string & !=""]
	maintenance?: {pruneSchedule?: sch.#CronSchema, checkSchedule?: sch.#CronSchema}
}
#BackupRetentionSchema: {
	keepLast?: int & >0, keepHourly?: int & >0, keepDaily?: int & >0
	keepWeekly?: int & >0, keepMonthly?: int & >0, keepYearly?: int & >0
	keepWithin?: string & =~"^[0-9]+[hdw]$"
	matchN(>=1, [{keepLast!: _}, {keepHourly!: _}, {keepDaily!: _}, {keepWeekly!: _}, {keepMonthly!: _}, {keepYearly!: _}, {keepWithin!: _}])
}

// opm/traits/v1alpha1/backup_command.cue
#BackupCommandTrait: c.#Trait & {
	metadata: {name: "backup-command", apiVersion: "v1alpha1", ...}
	fulfilment: "provider"
	optional:   bool | *false
	appliesTo: [res.#ContainerResource]
	spec: backupCommand: #BackupCommandSchema
}
#BackupCommandSchema: {
	container!: string
	command!:   string & !=""
	volumes?: [...string]
	landing?: {volume!: string, path!: string & =~"^[^/].*"}
	fileExtension?: string & =~"^\\.[a-z0-9]+(\\.[a-z0-9]+)*$"
	compensate?: string & !=""
}
```

## Impact

- **`modules` fleet:** nothing to do. No module attaches either trait until a provider catalog exists; a module that attaches one before then fails its render with an unresolved trait demand naming the contract (0010 D28), which is the designed behaviour. jellystat's exported-backup volume is the first real candidate for `backup` with `volumes`.
- **Subscribing platforms:** every rendered PVC gains one label on the next reconcile. Labels are mutable, so the server-side apply updates the object in place; nothing is recreated.
- **`cli` fixtures under `testing.opmodel.dev`:** nothing to do; none renders a PVC whose labels are pinned.
- **Release class:** three sections, `feat(transformers)`, `feat(traits)`, `docs(opm)`; the `opm` module goes `v4.0.1` to `v4.1.0`. No member moves segment; both traits are new at `v1alpha1`, where the compatibility gate is off (0010 D34). The `opm` module ships the stable v4 line; nothing here relies on a pre-release line.

## Enhancement

None. `enhancements/0015` motivates the provider-fulfilled contract and hosts the experiments, but decides nothing about the trait's shape; the listing in the contract maps (0015 D1) is a separate change.
