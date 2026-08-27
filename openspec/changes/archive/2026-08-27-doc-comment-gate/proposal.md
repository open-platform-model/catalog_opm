## Why

This repo's constitution says the definition is the spec: a member's CUE and its doc comments are the contract text. A CUE doc comment is exactly the `//` block that ends on the line directly above a declaration (parser flag `Doc`, cue v0.17.1), and every consumer surface replays it verbatim: `cue lsp` hover in the VS Code extension, `Value.Doc()` in `opmodel.dev` docgen, `cue def`. Measured on `main`: 46 doc comments across `opm/` and `k8s/` exceed 6 lines (`#RuntimeClassTrait` 22, `#ContainerResource.matchLabels` 21, `#ExposeSchema.name` 20, `deployment_transformer.cue` `_updateStrategy` 26). The extra length is evaluator behavior, rendering rationale and history that an author hovering `mountPropagation` did not ask for, and it will keep growing because nothing states where each kind of comment belongs and nothing measures it. `INDEX.md` is unaffected (the generator takes the first sentence only), which is why the drift has been invisible.

Now, because the sibling `core` change `doc-comment-gate` records the same convention on the schema side, and the sweep that relocates the existing comments here needs the rule and a report in place first.

## What Changes

- A three-tier comment convention for every `*.cue` file under `opm/` and `k8s/`: the doc comment (at most 6 lines, the contract an author needs), a detached `// WHY` note below the field after one blank line for rationale that must stay next to the code, and a `docs/<note>.md` or the enhancement entry for a full argument. Recorded in `CLAUDE.md` § Working Style for Agents and in `openspec/config.yaml` § Code Style, the two normative sources here.
- A new report, `.tasks/doc-check.sh`, with a `task docs:check` task wired into `task check` and a `ci.yml` step. It lists every doc comment over 6 lines in both modules, skipping hidden `_test*` fixture fields, `package` docs, `let` and comprehension clauses. **Warn-only in this change**: exits 0. The follow-up sweep change flips it to `--strict` once the count is zero.
- No member `*.cue` edits. Both published modules are byte-identical before and after.

## Before / After

No member changes in this change. The block below is the shape the convention produces, shown on the member the sweep will touch first, so the review surface is concrete. `opm/resources/v1beta1/volume.cue`, `#VolumeMount.mountPropagation`:

Before (14-line doc comment, all of it hover text):

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

After (5-line doc comment; the example survives as a detached note):

```cue
	// How host mounts created after the container starts become visible
	// inside it. "None" (Kubernetes default) snapshots the mount tree at
	// start-up. "HostToContainer" is required when a controller populates a
	// hostPath lazily. "Bidirectional" also propagates the container's own
	// mounts back to the host and requires a privileged container.
	mountPropagation?: "None" | "HostToContainer" | "Bidirectional"

	// WHY "HostToContainer" matters in practice: Istio's CNI agent mounts
	// /host/var/run/netns to enter pod network namespaces, and the runtime
	// bind-mounts those entries as pods are created, after the agent is
	// already running. Without propagation the agent silently never sees pods
	// created after it started, which presents as a network fault rather than
	// a config error.
```

The value, the constraint and the rendered output are identical; only what hover shows changes.

## Impact

- Release class: none. `chore:` for the script, Taskfile and CI; `docs:` for `CLAUDE.md` and `openspec/config.yaml`. No `apiVersion` moves. Does not rely on the v2 alpha line.
- `modules` fleet, subscribing platforms, `cli` fixtures: nothing to do; no published CUE changes.
- `opmodel.dev` docgen: benefits once the sweep lands (contract-only field descriptions); nothing changes here.
- `core`: the sibling change `core/openspec/changes/doc-comment-gate` installs the same script and rule; neither change depends on the other, and the scripts are intended to stay byte-identical so the rule reads the same across the v2 line.

## Enhancement

None. This is repository tooling, not a slice of an enhancement entry.
