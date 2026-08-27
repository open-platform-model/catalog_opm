## Why

The `doc-comment-gate` change (archived 2026-08-27) recorded the three-tier comment convention and installed `task docs:check`, warn-only, so the rule would be in place before the existing comments were moved. Measured on `main` today the report lists 32 doc comments over 6 lines: 30 under `opm/`, 2 under `k8s/` (`#RuntimeClassTrait` 22 lines, `#ContainerResource.matchLabels` 21, `#ExposeSchema.name` 20, `deployment_transformer.cue` `_updateStrategy` 26). Every one of them is replayed verbatim by `cue lsp` hover, `Value.Doc()` in `opmodel.dev` docgen and `cue def`. Until the count is zero the report cannot be made strict, and the convention protects only new comments.

Now, because the sibling `core` sweep (`core/openspec/changes/archive/2026-08-27-doc-comment-sweep`, PR core#55) has landed and its review settled one point the gate got wrong: the detached rationale block belongs ABOVE the doc comment, not below the field. The rule text here still says "below" in three places and has to be corrected before any comment is moved under it.

## What Changes

- **Rule correction (first commit).** `CLAUDE.md` § Working Style for Agents, `openspec/config.yaml` § Code Style and the header and warning text of `.tasks/doc-check.sh` all say the `// WHY` block goes below the field. They change to: the `// WHY` block sits ABOVE the doc comment, separated from it by one blank line. `.tasks/doc-check.sh` becomes byte-identical to `core/.tasks/doc-check.sh` again (the script's counting logic is unchanged; only the header and the message differ today).
- **Relocation of the 32 sites**, one commit per kind directory (`opm/blueprints`, `opm/identity` + `k8s/identity`, `opm/resources`, `opm/traits`, `opm/transformers`, `k8s/resources`). At each site the doc comment keeps the contract (what it is, what it renders, what a value must satisfy) in at most 6 lines; every other sentence moves, verbatim, into a `// WHY ...` block above the doc comment. No sentence is deleted and no code line changes. Hidden `_test*` fixture fields are exempt from the report and are not touched.
- **Strict flip (last commit).** `Taskfile.yml` `docs:check` passes `--strict`, so `task check` and `ci.yml` fail on any doc comment over 6 lines from then on. `CLAUDE.md` and `openspec/config.yaml` drop the "warn-only until the sweep lands" wording.
- No change to any member's shape, default, closedness or required-field set. Both published modules evaluate identically before and after.

## Before / After

No member shape changes. The block shows the layout the sweep produces, on the first site it touches. `opm/resources/v1beta1/volume.cue`, `#VolumeMount.mountPropagation`:

**Before**

```cue
	// How mounts created on the host after this container starts become
	// visible inside it. Kubernetes defaults to "None", which gives the
	// container a snapshot of the mount tree taken at start-up: anything the
	// host bind-mounts underneath the path later is invisible forever.
	//
	// "HostToContainer" is required whenever a controller populates a hostPath
	// lazily: Istio's CNI agent mounts /host/var/run/netns to enter pod network
	// namespaces, and the container runtime bind-mounts those entries as pods
	// are created, i.e. after the agent is already running. Without
	// propagation the agent silently never sees pods created after it started,
	// which presents as a network fault rather than a config error.
	//
	// "Bidirectional" additionally propagates the container's own mounts back
	// to the host and requires a privileged container.
	mountPropagation?: "None" | "HostToContainer" | "Bidirectional"
```

**After**

```cue
	// WHY: "HostToContainer" is required whenever a controller populates a hostPath
	// lazily: Istio's CNI agent mounts /host/var/run/netns to enter pod network
	// namespaces, and the container runtime bind-mounts those entries as pods
	// are created — i.e. after the agent is already running. Without
	// propagation the agent silently never sees pods created after it started,
	// which presents as a network fault rather than a config error.

	// How mounts created on the host after this container starts become
	// visible inside it. Kubernetes defaults to "None", which gives the
	// container a snapshot of the mount tree taken at start-up — anything the
	// host bind-mounts underneath the path later is invisible forever.
	// "Bidirectional" additionally propagates the container's own mounts back
	// to the host and requires a privileged container.
	mountPropagation?: "None" | "HostToContainer" | "Bidirectional"
```

Hover shows the second block only. Lines are moved, not rewritten (design D2); the value, the constraint and the rendered output are identical.

## Impact

- Release class: `docs:` for every commit that touches `*.cue`, `CLAUDE.md` or `openspec/config.yaml`; `chore:` for the Taskfile strict flip and the script header. Neither type releases in this repo. No `apiVersion` moves. Does not rely on the v2 alpha line.
- `modules` fleet, subscribing platforms, `cli` fixtures under `testing.opmodel.dev`: nothing to do; no published CUE evaluates differently.
- `opm/INDEX.md`, `k8s/INDEX.md`: `generate-index.sh` takes the first sentence of each definition's doc comment. The sweep keeps every first sentence, so the committed INDEX files are expected to be unchanged; `task generate:index:check` in every commit proves it.
- `opmodel.dev` docgen: field descriptions become contract-only once this lands; nothing to do there.
- `core`: the rule text and `.tasks/doc-check.sh` already say "above" there (core PR #55). After the first commit here the two scripts are byte-identical again.

## Enhancement

None. Repository documentation hygiene, not a slice of an enhancement entry.
