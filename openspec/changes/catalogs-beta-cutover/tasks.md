## Gates

The supervisor ticks these; no worker ticks a gate. No task, from 1.1 onward, starts before G1 and SP1 are ticked. The supervisor ticks G1 and SP1 in `<wt>`'s tasks.md before handing over, and those ticks ride the section 2 commit.

Versions below are written as core `v2.0.0-beta.1` and k8s `1.0.0-beta.1`. Substitute the real G1 core version, and the k8s version actually on GHCR after protocol step 3, wherever `beta.1` appears (the SP1 hunk check, 1.2, 1.4, 2.1, the design.md D1 messages, the PR titles and the D5 texts). If k8s lands as a `beta.N` other than `beta.1`, amend PR2's `AGENTS.md`, `README.md` and `docs/site` lines before protocol step 5.

- [ ] G1 core `v2.0.0-beta.1` is resolvable on GHCR (`opmodel.dev/core@v2`).
- [ ] SP1 **Supervisor patch: root `task deps:update`**, run after G1 on the main checkouts. Only catalog_opm's diff is kept, as a patch file whose path is handed to the worker. Every other repo's main checkout is restored. The patch holds exactly two hunks: `opm/cue.mod/module.cue` and `k8s/cue.mod/module.cue`, each changing `"opmodel.dev/core@v2": v:` from `v2.0.0-alpha.13` to `v2.0.0-beta.1`. Any other hunk means the patch is refused and regenerated.
- [ ] G3 (produced by this change, confirmed by the supervisor at the end of the merge protocol) `k8s-v1.0.0-beta.1` and `opm-v4.4.4` are on GHCR.

Conventions for every task below:

- `<wt>` is `/var/home/emil/dev/open-platform-model/catalog_opm/.claude/worktrees/beta-catalogs-beta-cutover` on branch `beta/catalogs-beta-cutover` (PR2).
- `<wt-k8s>` is `/var/home/emil/dev/open-platform-model/catalog_opm/.claude/worktrees/beta-catalogs-beta-cutover-k8s` on branch `beta/catalogs-beta-cutover-k8s` (PR1).
- `<patch>` is the SP1 patch path. Always `cd` into the worktree inside each command, and never edit the main checkout.
- Export the registry variables on two separate lines before any `task` or `cue` run, as in the workspace root `AGENTS.md`.
- `task check` runs `fmt:check`, which diffs every `.cue` file under `opm/` and `k8s/` (including `cue.mod/module.cue`) against the git index (`AGENTS.md`, Build And Dev Commands). Stage a changed `.cue` file before running it, or it fails although the file is formatted.
- Before every commit, scan the message for a bare `@` and for a body line that starts with `word(`, and fix every hit.
- Stage files by explicit path.

## 1. k8s carrier, PR1 (`k8s/cue.mod/module.cue`, branch `beta/catalogs-beta-cutover-k8s`)

- [ ] 1.1 Create the PR1 worktree from `origin/main`, never from the change branch: `git -C /var/home/emil/dev/open-platform-model/catalog_opm fetch origin && git -C /var/home/emil/dev/open-platform-model/catalog_opm worktree add .claude/worktrees/beta-catalogs-beta-cutover-k8s -b beta/catalogs-beta-cutover-k8s origin/main`.
- [ ] 1.2 **(Supervisor patch SP1, k8s hunk only.)** `cd <wt-k8s> && git apply --include='k8s/cue.mod/module.cue' <patch>`. Verify two things:
  - `git -C <wt-k8s> diff --stat` shows 1 file, 1 insertion and 1 deletion.
  - The changed line reads `v: "v2.0.0-beta.1"`.

  Never hand-edit the pin.
- [ ] 1.3 `git -C <wt-k8s> add k8s/cue.mod/module.cue`, then `task -d <wt-k8s> check` is green. Then `git -C <wt-k8s> status --short` must print exactly `M  k8s/cue.mod/module.cue` (staged, nothing unstaged, nothing else). If `k8s/INDEX.md`, `k8s/identity/identity.cue`, `k8s/RELEASE` or any other path changed, stop and report it (design.md, Risks).
- [ ] 1.4 Commit in `<wt-k8s>` with exactly the carrier message from design.md D1: subject `fix(deps): bump opmodel.dev/core@v2 to v2.0.0-beta.1 in the k8s catalog`, the two-line body, then the final block `Release-As: 1.0.0-beta.1` directly followed by `Co-Authored-By: Claude <noreply@anthropic.com>`. Verify with `git -C <wt-k8s> log -1 --format=%B` that the last two lines are exactly those. Then verify that `git -C <wt-k8s> diff --name-only origin/main...HEAD` prints only `k8s/cue.mod/module.cue`. Tick 1.1-1.4 in `<wt>`'s tasks.md; that tick rides the section 2 commit.

## 2. opm core bump (`opm/cue.mod/module.cue`, PR2)

- [ ] 2.1 **(Supervisor patch SP1, opm hunk only.)** `cd <wt> && git apply --include='opm/cue.mod/module.cue' <patch>`. Verify that `git -C <wt> diff --stat -- opm` shows 1 file, 1 insertion and 1 deletion, and that the `cue.dev/x/k8s.io@v0` dep is untouched. Never hand-edit the pin. Nothing under `k8s/` changes on this branch.
- [ ] 2.2 `git -C <wt> add opm/cue.mod/module.cue`, then `task -d <wt> check` is green. `git -C <wt> status --short -- opm k8s` must print exactly `M  opm/cue.mod/module.cue`. Then stage this tasks.md and commit `fix(deps): bump opmodel.dev/core@v2 to v2.0.0-beta.1 in the opm catalog`. No `Release-As` footer.

## 3. release-please config (`release-please-config.json`, PR2)

- [ ] 3.1 Set `packages.k8s."prerelease-type"` to `"beta"` (design.md D4). Leave `packages.opm` untouched: `"prerelease": false` stays, and `"prerelease-type": "alpha"` stays. Add no `release-as` key. Verify with `jq -e '.packages.k8s["prerelease-type"]=="beta" and .packages.k8s.prerelease==true and .packages.opm.prerelease==false and ([..|objects|has("release-as")]|any|not)' release-please-config.json`. Do not touch `.release-please-manifest.json`.
- [ ] 3.2 `task -d <wt> check` green, then commit `ci(release): set the k8s prerelease-type to beta`.

## 4. Beta promise per release class (rule files and docs, PR2)

These tasks land both durable decisions from design.md. The target texts are in design.md D5 and are applied verbatim, apart from reflow.

- [ ] 4.1 `AGENTS.md`:
  - line 127: replace the alpha-line clause.
  - line 128: split into the `opm` stable-line bullet and the `k8s` beta-line bullet, with the `Release-As` crossing sentence appended to the `k8s` bullet.
  - Release & publishing: insert the `--match-head-commit` merge-rule bullet directly after the release-please bullet (line 217).
  - Commit conventions: insert the `k8s` beta note between the release table and the **Rule of thumb** line. The table rows stay unchanged.
  - line 249: `opmodel.dev/catalogs/opm@v2` becomes `opmodel.dev/catalogs/opm@v4`, and `opm@v2` becomes `opm@v4`.
- [ ] 4.2 `openspec/config.yaml`:
  - Principle I, lines 24-27: the two release-line bullets.
  - Proposal rule, lines 119-122: the release-line tail. It is a plain scalar, so it must contain no `: ` and no ` #` (design.md D5).
  - Verify both of these:
    - `cd <wt> && python3 -c 'import yaml;r=yaml.safe_load(open("openspec/config.yaml"))["rules"]["proposal"];assert all(isinstance(x,str) for x in r)'` exits 0.
    - `cd <wt> && openspec instructions proposal --change catalogs-beta-cutover 2>&1` contains neither `could not parse` nor `array of strings`, and does contain `which release line it is on`.
- [ ] 4.3 `openspec/schemas/catalog-change/schema.yaml:31-32` and `openspec/schemas/catalog-change/templates/proposal.md:28-30`: the same release-line tail as the proposal rule in 4.2. Verify that `python3 -c 'import yaml;yaml.safe_load(open("openspec/schemas/catalog-change/schema.yaml"))'` exits 0.
- [ ] 4.4 `README.md:60`: the D5 paragraph, covering the `@v4` path, stable `v4.x.x`, and the `k8s` beta line.
- [ ] 4.5 `docs/site/authoring/use-a-raw-kubernetes-resource.md:35`: `1.0.0-alpha.4` becomes `1.0.0-beta.1`. Nothing else on the line changes.
- [ ] 4.6 Check for leftovers. Each of these prints nothing:
  - `grep -rn -i 'v2 alpha line\|alpha line closed\|explicit config flip' AGENTS.md README.md openspec/config.yaml openspec/schemas`
  - `grep -n 'major `@v2`' README.md`
  - `git -C <wt> grep -n 'catalogs/opm@v2\|opm@v2' -- AGENTS.md README.md docs`
  - `grep -rn '1.0.0-alpha' docs/site`
- [ ] 4.7 `task -d <wt> check` green, then commit `docs: state the beta promise per catalog release line`.

## 5. Branch-tag ranking comments (`.tasks/branch-tag.sh`, PR2)

- [ ] 5.1 Rewrite the comment lines 91-93 and 106 as shown in design.md D5, naming the `-beta.N` line and adding `v1.0.0-beta.1` to the ranking chain. Change comments only. `git -C <wt> diff -U0 -- .tasks/branch-tag.sh | grep '^[+-][^+-]' | grep -v '^[+-]#'` prints nothing, and `bash -n .tasks/branch-tag.sh` passes.
- [ ] 5.2 `task -d <wt> check` green and `cd <wt> && openspec validate catalogs-beta-cutover --strict --no-interactive` green, then commit `ci(publish): name the beta line in the branch-tag ranking comments`.

## 6. Verify and archive the change (PR2)

- [ ] 6.1 Verify the change by reading `<wt>/.claude/skills/openspec-verify-change/SKILL.md` and following it for `catalogs-beta-cutover`. Run each `openspec` command as `cd <wt> && openspec ...`. Boxes 6.2-6.4, section 7 and gate G3 are expected to be open at this point. Report any other finding as a deviation.
- [ ] 6.2 Check both branches and the messages:
  - `task -d <wt-k8s> check` is still green.
  - `git -C <wt> diff --name-only origin/main...HEAD` lists no path under `k8s/` and none of `.release-please-manifest.json`, `opm/identity/`, `opm/RELEASE` or `opm/INDEX.md`.
  - `git -C <wt> log origin/main..HEAD --format=%B | grep -i 'release-as'` prints nothing.
  - `git -C <wt-k8s> log origin/main..HEAD --format=%B | grep -c '^Release-As: 1.0.0-beta.1$'` prints `1`.
  - Neither branch's messages contain a bare `@` token.
- [ ] 6.3 Confirm that design.md's Durable decisions are landed (section 4). Tick 6.1-6.3, then `cd <wt> && openspec archive catalogs-beta-cutover --skip-specs --yes`. `--yes` accepts the still-open boxes 6.4, section 7 and G3; any other open box is a stop. Confirm that no `openspec/specs/` directory was created. There is no `enhancement.yaml`, so no delivery log follows.
- [ ] 6.4 Tick 6.4 in the archived tasks.md, then commit `chore(openspec): archive catalogs-beta-cutover` (staging the moved change directory by explicit path).

## 7. Open the PRs

This change's deliverable is a release operation, so the delivery steps are tasks (`openspec/config.yaml` tasks rules, sole exception). Workers open PRs and never merge them. PR bodies are at most 250 words of prose, with no commit list, no out-of-scope section and no test-plan list; any `@` in them goes in backticks.

- [ ] 7.1 **PR1, the carrier.** `git -C <wt-k8s> push -u origin beta/catalogs-beta-cutover-k8s`, then `gh pr create`:
  - Title: `fix(deps): bump opmodel.dev/core@v2 to v2.0.0-beta.1 in the k8s catalog`.
  - Squash type: `fix(deps)`. Carrier: **yes**. Footer, the final block of the squash message: `Release-As: 1.0.0-beta.1`, then `Co-Authored-By: Claude <noreply@anthropic.com>`.
  - Merge gate: G1.
  - Expected release PR: `chore(main): release k8s 1.0.0-beta.1`.
  - The body says that this is the single-path carrier, that it must be squashed with its one commit's message unchanged except for the ` (#N)` suffix, and that the k8s release PR merges only on its identity-advance head.
- [ ] 7.2 **PR2.** `git -C <wt> push -u origin beta/catalogs-beta-cutover`, then `gh pr create`:
  - Title: `fix(deps): move the opm catalog onto core v2.0.0-beta.1`.
  - Squash type: `fix(deps)`. Carrier: **no**, no footer. The squash message is design.md D1's PR2 message.
  - Merge gate: G1 **and** `k8s-v1.0.0-beta.1` on GHCR (merge order in design.md D3).
  - Expected release PR: `chore(main): release opm 4.4.4`.
  - The body says that it must merge after the k8s release and carry no `Release-As`, and that it also sets the k8s prerelease-type to beta and states the beta promise per release line.
- [ ] 7.3 Report both PR numbers and head SHAs to the supervisor, then stop. Boxes 7.1-7.3 stay open in the archived copy, because the archive commit precedes the push. The report is their record, and no extra commit is made to tick them.

## Merge and release protocol (supervisor; design.md D3)

This part has no checkboxes. The change is archived before these steps run, so they would stay open forever in the archive. The supervisor tracks them against G3 above. Every step is supervisor-run; a worker acts only when the supervisor re-dispatches one for a named step.

1. **[supervisor]** G1 ticked. Check PR1's squash message with `check-merge-msg.js <file> 1.0.0-beta.1 fix` (release-please's parser gives `RELEASE AS` = `1.0.0-beta.1` and type `fix`; mention-guard regexes pass). Then merge PR1 with that message.
2. **[supervisor]** After `release.yml`, `gh pr list --label 'autorelease: pending'` must show exactly `chore(main): release k8s 1.0.0-beta.1`. No opm PR may appear, and no `alpha.7` title. On a mismatch, stop and use the design.md recovery path; merge nothing.
3. **[supervisor]** **k8s release-PR merge rule.** Wait until the head commit of `release-please--branches--main--components--k8s` is `chore: advance k8s identity.Version to 1.0.0-beta.1` and the CI run dispatched on that SHA has passed. Then run `gh pr merge <N> --squash --match-head-commit <advance-sha>`, never `--admin`. Watch `publish-cue` and confirm `opmodel.dev/catalogs/k8s@v1` `v1.0.0-beta.1` on GHCR.
4. **[supervisor, or a worker it re-dispatches]** `cd <wt> && git fetch origin && git merge origin/main`, never a rebase. Confirm that PR2's diff still lists no `k8s/` path, then `git push`. CI must be green. `main` protection does not require an up-to-date branch, so this step re-tests PR2 on the tree holding the k8s bump; it is not a merge precondition GitHub enforces.
5. **[supervisor]** Grep PR2's final squash message for `release-as`, case-insensitive, and abort on any hit. Run `check-merge-msg.js <file> none fix`. Merge PR2 with the design.md D1 message.
6. **[supervisor]** The expected release PR is exactly `chore(main): release opm 4.4.4`. Apply the same head-commit rule: head = `chore: advance opm identity.Version to 4.4.4`, CI passed, then `gh pr merge <N> --squash --match-head-commit <advance-sha>`. Confirm `opmodel.dev/catalogs/opm@v4` `v4.4.4` on GHCR, and tick G3.
7. **[supervisor]** **Freeze.** From G3, no releasable commit touching `opm/` merges on `main` until the supervisor has saved the run-2 patches of root `task deps:update` (design.md D3 step 8). Hidden-type commits (`ci`, `docs`, `chore`, `test`) outside `opm/` are not frozen.
