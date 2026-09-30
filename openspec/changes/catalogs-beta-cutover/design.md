## Context

State on `origin/main` (`7d2e1dd`, 2026-09-30):

- `.release-please-manifest.json` holds `opm` `4.4.3` and `k8s` `1.0.0-alpha.6`. The tags are `opm-v4.4.3` and `k8s-v1.0.0-alpha.6`. No release PR is open, and nothing releasable has landed since either tag.
- Both `cue.mod/module.cue` files pin `opmodel.dev/core@v2` `v2.0.0-alpha.13` (`opm/cue.mod/module.cue:14`, `k8s/cue.mod/module.cue:10`). Pins move only through root `task deps:update`, never by hand.
- `release-please-config.json`: `opm` has `prerelease: false` and `prerelease-type: "alpha"` (unused while stable); `k8s` has `prerelease: true` and `prerelease-type: "alpha"`.
- `release.yml` runs on each push to `main`. After release-please it checks out each open release branch (`release-please--branches--main--components--<m>`) and runs `opm catalog version set <manifest version> ./<m>`. It then commits `chore: advance <m> identity.Version to <v>` and dispatches `ci.yml` onto that branch. Merging the release PR tags `<m>-v<v>`, and `publish-cue` then asserts `--version` against the committed identity.
- The release tooling writes three files per module, and no human commit touches them: `<m>/identity/identity.cue`, `<m>/RELEASE` and `.release-please-manifest.json`. `<m>/INDEX.md` is generated and checked by `task generate:index:check`.

This change touches no member file and no `apiVersion` segment in either module. It changes no definition's closedness, defaults or required-field set.

## Goals / Non-Goals

**Goals:**

- Put both catalogs on core `v2.0.0-beta.1` and release `k8s` as `1.0.0-beta.1` and `opm` as `4.4.4`. Those two releases are gate G3.
- Leave the release config such that the next `k8s` release after `beta.1` is `beta.2`, and `opm` stays stable.
- Replace every rule-file statement about the closed alpha line or the stale `@v2` path with the beta promise for each release class.

**Non-Goals:**

- Moving the pinned opm CLI (`OPM_CLI_VERSION`). A later `ci:` PR does that through root `task deps:pins:opm-cli`, after G6.
- GA of `k8s` (`prerelease: false` plus a visible `k8s/` carrier) and any contract-level (`v1alpha1`/`v1beta1` segment) change. Contract levels are an independent axis (`docs/site/reference/catalog-contract.md:25`).
- Historical comments that cite measured core `alpha.N` behaviour (`docs/name-constraints.md`, `docs/struct-disjunctions.md`, transformer `WHY` blocks, `.tasks/fixtures.sh:21`). They are records and stay.

## Decisions

### D1. Two PRs with disjoint package paths; PR1 is the only carrier

release-please splits commits by package path (`src/util/commit-split.ts`) and applies a `Release-As` note to every package the commit touches. The dry run is `scratchpad/research/gap-release-please-manifest-dry-run.md`, item 2, on the real config and manifest. It found:

| Footer commit touches | Result |
| --- | --- |
| `k8s/` only | one PR, `chore(main): release k8s 1.0.0-beta.1`; `opm` stays 4.4.3 |
| `opm/` and `k8s/` | both PRs; `opm` goes 4.4.3 to **1.0.0-beta.1** (irreversible tag) |
| an empty commit | both packages (`includeEmpty: true`), same failure |
| root files only | no package; no PR |

So the supervisor patch from `task deps:update` is split by path. PR1 applies only the `k8s/cue.mod/module.cue` hunk, and PR2 applies only the `opm/cue.mod/module.cue` hunk.

PR1 (branch `beta/catalogs-beta-cutover-k8s`, cut from `origin/main`) holds exactly one commit, and that commit's message is the carrier message. Because it is a single-commit PR, the squash can reuse that message verbatim: the footer sits in the final footer block, and mention-guard has scanned it on the branch.

```text
fix(deps): bump opmodel.dev/core@v2 to v2.0.0-beta.1 in the k8s catalog

Moves the raw Kubernetes catalog onto the core beta line and starts its
own beta line at the first beta.

Release-As: 1.0.0-beta.1
Co-Authored-By: Claude <noreply@anthropic.com>
```

At merge the supervisor appends ` (#N)` to the subject and changes nothing else.

PR2 (branch `beta/catalogs-beta-cutover`) holds this plan commit, the opm bump and the policy edits. Its squash has type `fix(deps)`, **no footer**, and a body in which no line starts with `word(`:

```text
fix(deps): move the opm catalog onto core v2.0.0-beta.1 and adopt the beta line (#N)

Bumps opmodel.dev/core@v2 to v2.0.0-beta.1 in the opm catalog, sets the
k8s release-please prerelease-type to beta, and states the beta promise
per release class: opm stays stable (a break is a new major), k8s is on
its beta line (a break is a feat! with a migration note that advances
the beta counter and never moves the path).

Co-Authored-By: Claude <noreply@anthropic.com>
```

Before merging PR2, grep the final squash message for `release-as`, case-insensitive, and abort on any hit.

Alternatives rejected:

- One PR with a `BEGIN_COMMIT_OVERRIDE` block listing two commits. It works in principle, but it is a PR-body edit, which mention-guard does not scan, and the path split then depends on the override being exact.
- An empty or root-only carrier. An empty commit hits both packages. A root-only commit hits neither.
- A config `release-as` key. It is sticky: it pins every later release (precedent `bc778ca`).

### D2. How PR1 relates to the change's branch history

PR1's branch is cut from `origin/main`, not from `beta/catalogs-beta-cutover`. This keeps the OpenSpec files and every root edit out of it. The apply worker creates it as a second worktree, `.claude/worktrees/beta-catalogs-beta-cutover-k8s`, and records it in `tasks.md` section 1.

The change branch never contains the `k8s/` hunk while PR1 is open. After PR1 and its release PR merge, `beta/catalogs-beta-cutover` picks the k8s change up through `git merge origin/main`. That merge is a no-op for PR2's diff, so PR2's diff never shows `k8s/`.

### D3. Merge order (supervisor)

The two PRs merge strictly one after the other. PR2 never merges while the k8s release PR is open.

1. G1 confirmed. Merge PR1 with the carrier message from D1.
2. `release.yml` opens `chore(main): release k8s 1.0.0-beta.1`, then pushes `chore: advance k8s identity.Version to 1.0.0-beta.1` onto `release-please--branches--main--components--k8s` and dispatches CI there. List every open release PR (`gh pr list --label 'autorelease: pending'`). Exactly the k8s one must appear. An opm PR, or a k8s title reading `alpha.7`, means the footer was lost. In that case stop and do not merge anything.
3. **k8s release-PR merge rule:** merge only when the PR's head commit is the identity-advance commit for `1.0.0-beta.1` and the CI run dispatched on that head has passed. Use `gh pr merge <N> --squash --match-head-commit <advance-sha>`, never `--admin`. Merging an earlier head tags a tree that still declares `alpha.6`: `publish-cue` then refuses, and the tag stays with nothing on GHCR.
4. Confirm `k8s-v1.0.0-beta.1` on GHCR (the k8s half of G3).
5. Update PR2 (`git merge origin/main`, push). Its CI must be green. Merge PR2 with the D1 message, after the `release-as` grep.
6. `release.yml` opens `chore(main): release opm 4.4.4` and pushes `chore: advance opm identity.Version to 4.4.4`. Apply the same head-commit rule: `--match-head-commit <advance-sha>`.
7. Confirm `opm-v4.4.4` on GHCR, which completes G3.

Serialising closes the window the review found. A push to `main` while a release PR is open lets release-please force-update that branch. The identity advance is then dropped, and it re-lands only on the next run.

### D4. release-please config

Only one key changes:

```json
"k8s": { "prerelease": true, "prerelease-type": "beta" }
```

`opm` keeps `"prerelease": false`. Its `"prerelease-type": "alpha"` stays as it is: it is inert while `prerelease` is false, and changing it would suggest `opm` has a prerelease channel. Measured in the dry run: from `1.0.0-beta.1`, a `fix`, `feat` or `feat!` gives `beta.2` either way. The key matters only if `k8s` ever returns to a stable base. It is set so that the config matches the line the package is on.

### D5. Rule-file wording (the target text)

The canonical beta promise is adapted per release class. Apply these texts verbatim, apart from reflow.

`AGENTS.md:127`: replace the clause `ships stable \`v4.x.x\` releases (the \`v2.x.x-alpha.x\` line closed at \`2.0.0\`); release-please keeps \`versioning: prerelease\` with \`prerelease: false\`, so a later prerelease is an explicit config flip, and` with:

> ships stable `v4.x.x` releases, and stays stable through the OPM beta while it depends on the `opmodel.dev/core@v2` beta line (the `v2.x.x-alpha.x` line closed at `2.0.0`); release-please keeps `versioning: prerelease` with `prerelease: false`, and

The rest of the bullet (the identity writer, `v1` branch and "Was:" history) is unchanged.

`AGENTS.md:128`: replace the bullet with two:

> - **`opm` is a stable line: a `feat!:` on `opm` bumps the major, and with it the module path (`opmodel.dev/catalogs/opm@vN`).** It has no prerelease counter to advance. A major crossing is the sanctioned way to correct a beta member *in place* when the `v1beta(N+1)` route (0010 D4) would leave the broken shape published under the old segment. It is not a licence to skip that route when a clean new segment is available. Consumers re-pin a path either way. A core beta break that would force an `opm` major needs owner sign-off before it lands.
> - **`k8s` is a beta line (`opmodel.dev/catalogs/k8s@v1`, from `1.0.0-beta.1`) on the path to GA.** A breaking change is still allowed during beta, but only as a `feat!:` commit whose `BREAKING CHANGE:` footer is the migration note `CHANGELOG-k8s.md` shows. It advances the `-beta.N` counter and never moves the module path to a new major. release-please keeps `prerelease: true` with `prerelease-type: beta`. GA drops the suffix: `prerelease: false` plus a visible carrier commit under `k8s/`, because a root-only config flip opens no release PR.

Append to that `k8s` bullet (durable decision 2):

> Crossing a release label (alpha to beta, beta to GA) takes a one-shot `Release-As:` footer, or for GA a visible commit, on a commit that touches only `k8s/`: a `prerelease-type` flip alone moves nothing, a root-only or empty commit reaches the wrong packages, and a `release-as` config key is sticky and never used. Merge a catalog release PR only when its head is the `chore: advance <m> identity.Version` commit and the CI dispatched on it passed (`gh pr merge --match-head-commit <sha>`).

`AGENTS.md:232`, the `feat!:` row of the release table. Its bump cell becomes:

> major (bumps the module path too); on `k8s` during beta: next `-beta.N`, path unchanged

`openspec/config.yaml:24-27`, Principle I. Replace the `feat!:` bullet with:

```yaml
  - `opm` is a stable line: a `feat!:` on `opm` bumps the major and with it the module path
    (`@vN`). A major crossing is the sanctioned way to correct a beta member in place when a
    `v1beta(N+1)` cascade would keep the broken shape published; a proposal MUST name it. A
    core beta break that would force an `opm` major needs owner sign-off.
  - `k8s` is a beta line on the path to GA: a break is allowed only as a `feat!:` whose
    `BREAKING CHANGE:` footer is the migration note the changelog shows; it advances
    `-beta.N` and never moves the module path (`@v1`).
```

`openspec/config.yaml:119-122`, the proposal rule. The tail `and whether the change relies on the module still shipping the v2 alpha line.` becomes:

> and, for each module touched, which release line it is on (`opm` stable: a break is a new major; `k8s` beta: a break is a `feat!:` with a `BREAKING CHANGE:` migration note that advances `-beta.N`).

The same tail changes in `openspec/schemas/catalog-change/schema.yaml:31-32` (proposal instruction, Impact bullet) and `openspec/schemas/catalog-change/templates/proposal.md:28-30` (Impact comment). Those two carry the same question, and leaving them would re-ask it in every future proposal.

`README.md:60` becomes:

> The `opm` module path is pinned to major `@v4` and ships stable `v4.x.x` releases; a break is a new major (the `v2.x.x-alpha.x` line of the core-v2 rollout, enhancement 0010, closed at `2.0.0`). The `v1` maintenance branch keeps the retired v1 line on `1.0.x` fix releases. The `k8s` module is on major `@v1` and its beta line from `1.0.0-beta.1`: until GA a break advances `-beta.N` with a migration note and never moves the path.

`docs/site/authoring/use-a-raw-kubernetes-resource.md:35`: `The latest release is 1.0.0-alpha.4` becomes `The latest release is 1.0.0-beta.1`. The rest of the line is unchanged. The statement is true when PR2 merges, because D3 merges PR2 only after `k8s-v1.0.0-beta.1` exists.

`.tasks/branch-tag.sh:91-93,106`, comments only:

```bash
#   1. With no stable release for the major (a long `-alpha.N` or `-beta.N`
#      line, which is where the `k8s` module lives until GA), `@vN` has nothing
#      to prefer and must pick the highest prerelease. `1.1.0-dev.*` beats
#      `1.0.0-beta.1` on the base
...
#   v1.0.0-0.dev.<ct>.g<sha>  <  v1.0.0-alpha.1  <  v1.0.0-beta.1  <  v1.0.0
```

### D6. Section commits inside PR2

PR2 squashes to one `fix(deps)` commit. Its inner section commits follow the repo's types so the branch history reads correctly:

- `fix(deps): bump opmodel.dev/core@v2 to v2.0.0-beta.1 in the opm catalog`
- `ci(release): set the k8s prerelease-type to beta` (precedent `bc778ca`)
- `docs: state the beta promise per catalog release line`
- `ci(publish): name the beta line in the branch-tag ranking comments` (precedent `b97cf7f`)
- `chore(openspec): plan catalogs-beta-cutover` and `chore(openspec): archive catalogs-beta-cutover`

Only the squash message reaches release-please.

## Research & Decisions

### Crossing a prerelease label in release-please

**Context**: The `k8s` package must go from `1.0.0-alpha.6` to `1.0.0-beta.1`.

**Explored**: `googleapis/release-please` `src/versioning-strategies/prerelease.ts`, plus a `Manifest.buildPullRequests()` dry run against this repo's real config, manifest and `RELEASE` files. The dry run used a mocked GitHub, with 17.3.0 (the version action v4.4.1 bundles) and 17.6.0 (`scratchpad/research/gap-release-please-manifest-dry-run.md`, `scratchpad/review-rp-merge/s_cat_empty.js`).

**Decision**: A one-shot `Release-As: 1.0.0-beta.1` footer on a commit that touches `k8s/` only, plus `prerelease-type: beta` for the counter afterwards.

**Rationale**: A config-only flip still proposes `alpha.7`. The footer is parsed only in the final footer block, and a GitHub multi-commit squash body loses it silently. A single-commit carrier PR is the dependable shape. `k8s/RELEASE` is rewritten to `1.0.0-beta.1 # x-release-please-version` by the generic updater. The RELEASE stamp on the release commit bounds the footer, so it is not resurrected later (precedent `660a982`).

### Keeping `opm` stable

**Context**: Should `opm` enter a beta channel too?

**Explored**: `research/catalog_opm.md` open questions A/B/C. The 0011 D9 compat gate is armed for `opm@v4` because it has a stable tag, and a prerelease would exempt beta/GA members from the compare. CUE `@v4` resolution prefers stable, so `4.5.0-beta.1` would be invisible to unpinned consumers. `5.0.0-beta.1` would change the module path for every consumer.

**Decision**: Stay stable (owner default 5 in the canon). `opm` takes `4.4.4` on the core beta.

**Rationale**: It keeps the compat gate binding and leaves `@v4` consumers undisturbed. A stable module with an exact prerelease dependency pin is already today's state (core alpha.13).

## Risks / Trade-offs

- [The carrier footer is lost, for example through a retyped squash or a bullet list] -> The k8s release PR reads `alpha.7`. Nothing is tagged until it merges, so stop and do not merge it. Recover by editing the merged PR1 body with a `BEGIN_COMMIT_OVERRIDE` block that holds the D1 carrier message, then re-run `release.yml` (strategy section 5). Never recover with an empty commit.
- [A footer reaches an `opm/` commit] -> An irreversible `opm-v1.0.0-beta.1` tag. Mitigated by the path split in D1 and the case-insensitive `release-as` grep on PR2's squash message.
- [The k8s release PR merges before its identity advance] -> The tag exists but GHCR stays empty (publish refuses the mismatch), and the version is burned (canon: the target moves to `beta.2` and downstream follows). Mitigated by the `--match-head-commit` rule in D3.
- [The pinned cli `v1.0.0-alpha.27` rejects a catalog on core beta.1 in the CI publish dry-run] -> The reviewed precedent (opm-v4.4.3 on newer core than the cli's default) says it does not. If it does, PR1 CI fails before anything merges. Report it to the supervisor, who decides whether the cli pin moves first. Workers do not bump it.
- [`task deps:update` swallows failures (`|| true`)] -> The supervisor reads the patch. Section 1 and section 2 each verify that the hunk is exactly one pin line going `alpha.13` to `beta.1`.
- [`task check` shows `k8s/INDEX.md` drift after the bump] -> Not expected, because the index lists definitions, not deps. If it happens, PR1 is no longer a single-file carrier. Stop and report; do not regenerate into PR1 without supervisor sign-off.

## Durable decisions

- The beta promise per release class (`opm` stable, a break is a new major; `k8s` beta, a break is a `feat!:` with a migration note that advances `-beta.N`) -> `AGENTS.md` Repository Rules and the release table, and `openspec/config.yaml` Principle I. Landed in section 4.
- Crossing a prerelease label needs a one-shot `Release-As` footer on a commit that touches only the target package's path; a config flip alone does nothing, and a config `release-as` key is forbidden. Also, merge a catalog release PR only on its identity-advance head (`--match-head-commit`) -> `AGENTS.md`, as one sentence appended to the `k8s` beta-line bullet. Landed in section 4.
- The PR split, merge order and exact squash messages -> stays with the change.
