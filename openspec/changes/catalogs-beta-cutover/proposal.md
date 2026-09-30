## Why

OPM is cutting its prerelease lines from alpha to beta (owner decisions of 2026-09-30). Core ships `opmodel.dev/core@v2` `v2.0.0-beta.1` first (gate G1). Both catalogs pin core `v2.0.0-alpha.13` and must move onto the core beta. The raw catalog `k8s` must also cross its own release line from `1.0.0-alpha.6` to `1.0.0-beta.1`. The abstraction catalog `opm` stays stable at major `@v4` and takes a patch release, `4.4.4`. The repo's rule files still describe the closed alpha line and the old `@v2` path. They must state the beta promise for each release class before the beta ships under them.

release-please does not cross onto beta when `prerelease-type` alone flips. From `1.0.0-alpha.6` it proposes `alpha.7` whatever that key says. The version crosses only through a one-shot `Release-As: 1.0.0-beta.1` footer in the final commit message on `main`. That footer applies to every package whose paths the commit touches. A footer on anything under `opm/` would tag `opm-v1.0.0-beta.1`, and that tag cannot be undone. So the change ships as two PRs with disjoint package paths.

## What Changes

- **PR1, the k8s carrier** (branch `beta/catalogs-beta-cutover-k8s`): only `k8s/cue.mod/module.cue`, with the core pin moved `v2.0.0-alpha.13` to `v2.0.0-beta.1`. The change comes from a supervisor patch (root `task deps:update`, run after G1). The squash commit is `fix(deps)` and carries `Release-As: 1.0.0-beta.1`. Nothing else under `k8s/` changes: `k8s/identity/identity.cue`, `k8s/RELEASE` and `k8s/INDEX.md` are written by release tooling or generated.
- **PR2, the opm and policy PR** (branch `beta/catalogs-beta-cutover`, no footer):
  - `opm/cue.mod/module.cue` gets the same core pin move, from the same supervisor patch.
  - `release-please-config.json` sets the `k8s` package to `"prerelease-type": "beta"`, so that `beta.2` and later follow `beta.1`. The `opm` package keeps `"prerelease": false`. No `release-as` key is added anywhere.
  - `AGENTS.md` (Repository Rules lines 127-128 and the `feat!:` row of the release table) and `openspec/config.yaml` (Principle I lines 24-27 and the proposal rule at lines 119-122) state the beta promise per release class:
    - `opm` is a stable line: a break is a new major.
    - `k8s` is a beta line: a break is a `feat!:` with a `BREAKING CHANGE:` migration note, advances `-beta.N` and never moves the path.
  - The same proposal-rule wording is mirrored in `openspec/schemas/catalog-change/schema.yaml` (line 32) and `templates/proposal.md` (line 29).
  - `README.md:60`: the stale `@v2` / `v2.x.x` statement becomes `@v4` / `v4.x.x`, and the `k8s` alpha-line phrase becomes the beta line.
  - `docs/site/authoring/use-a-raw-kubernetes-resource.md:35`: "latest release is 1.0.0-alpha.4" becomes `1.0.0-beta.1`.
  - `.tasks/branch-tag.sh:91-106`: the comments name the beta line beside the alpha one. The logic is unchanged.
  - This change directory, archived. Root paths feed no release-please package.
- Nothing is **BREAKING**. No member, schema or transformer changes, and no member moves to a new `apiVersion` segment.

## Before / After

No catalog member changes. Both published modules are byte-identical except for the core dependency pin, which is the review surface.

**Before**

```cue
// k8s/cue.mod/module.cue (PR1) and opm/cue.mod/module.cue (PR2), same dep
deps: "opmodel.dev/core@v2": v: "v2.0.0-alpha.13"
```

**After**

```cue
deps: "opmodel.dev/core@v2": v: "v2.0.0-beta.1"
```

The release-line state each PR produces (JSON, `.release-please-manifest.json` after the release PRs merge; release-please writes it, never a hand edit):

```cue
before: {opm: "4.4.3", k8s: "1.0.0-alpha.6"}
after:  {opm: "4.4.4", k8s: "1.0.0-beta.1"}
```

## Impact

- **Release class.** PR1 squashes as `fix(deps)` with the footer `Release-As: 1.0.0-beta.1` and is the only carrier. Expected release PR: `chore(main): release k8s 1.0.0-beta.1`. PR2 squashes as `fix(deps)` with no footer. Expected release PR: `chore(main): release opm 4.4.4`. The inner section commits of PR2 (`ci(release)`, `docs`, `ci(publish)`, `chore(openspec)`) are hidden types and release nothing on their own. The change no longer relies on any alpha line. It retires the "v2 alpha line" question from the proposal rule.
- **Gate.** Both PRs merge only after G1 (core `v2.0.0-beta.1` resolvable on GHCR). The two catalog releases together are gate G3 for the rest of the cutover.
- **Subscribing platforms.** A Platform pins an exact catalog build (0010 D14/D31). `cli/hack/kind-platform.yaml` and the `opm-operator` sample Platform move to opm `4.4.4` and k8s `1.0.0-beta.1`. The supervisor moves them with root `task deps:update` after G3, in `test(fixtures)` PRs in those repos. Nothing is required of them here.
- **`modules` fleet and `opm-modules`.** They pin `opmodel.dev/catalogs/opm@v4` and pick up `4.4.4` through `task deps:update` after G3, as `fix(deps)` patch releases in their own repos. They do not consume `k8s`.
- **`cli` fixtures under `testing.opmodel.dev`.** They move through `task deps:pins:fixtures` after G3 (supervisor, `test(fixtures)`). This repo has nothing to do.
- **Downstream consumers of `k8s`.** A consumer on `opmodel.dev/catalogs/k8s@v1` without an exact pin resolves the highest prerelease, which becomes `1.0.0-beta.1`. The path does not change.
- **Pinned opm CLI.** CI still installs `v1.0.0-alpha.27`, which publishes a catalog built on a newer core. A cli older than the core it validates has published before (opm-v4.4.3 on core alpha.13 with cli alpha.25). The pin moves later in a separate `ci:` PR (root `task deps:pins:opm-cli`, after G6).

## Enhancement

None. The cutover implements no enhancement decision; 0021 (versioning policy) is still a draft. There is no `enhancement.yaml` and no delivery logging at archive.

This change's deliverable is a release operation: crossing `k8s` onto its beta line. So `tasks.md` carries the branch, PR and merge-order steps as tasks, under the sole exception in the `openspec/config.yaml` tasks rules. Its sections map to two PRs, not one. Section 1 ships alone as PR1, and the rest ship as PR2.

Delivery: one PR per section (release-please needs the k8s carrier alone on main after section 1)

Section 1 is PR1. Sections 2-5 ride one PR, PR2, because none of them may carry a footer and none of them touches `k8s/`.
