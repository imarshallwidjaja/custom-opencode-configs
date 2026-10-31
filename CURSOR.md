# Cursor Setup

This repository ships a Cursor asset bundle whose default parent Agent uses Hive-Builder-like ad-hoc orchestration through Cursor-native named subagents. Delegation is the baseline for non-trivial work; the parent classifies and coordinates lanes, inspects results and diffs, runs combined verification and review, and owns synthesis and integration.

This is a strong prompt policy, but Cursor routing is heuristic and not runtime-guaranteed. The bounded direct-work exception covers coordination, setup, and trivial conversation. Bounded direct reads and cheap parent checks stay with the parent. Non-trivial implementation, test, debug, refactor, integration, and review stay delegated. Separate context does not isolate files in a shared checkout. Parallel writing lanes, including overlapping writers, each get their own git worktree or isolated project copy. One writer may use the shared checkout when no other writer is active. If a separate placement cannot be created, report the blocker. Do not put two writers in one checkout, even on disjoint paths.

Planning uses Cursor's own Plan mode or a plan you supply; there is no planner agent. Before the parent places any lane it settles integration authority and history intent: a user-approved local commit or squash path runs without a repeated menu, absent commit permission it integrates uncommitted changes only when the destination holds no conflicting user work (otherwise it asks at that decision), and creating a worktree never grants Git authority. Missing required delegation or isolation is reported as a blocker; the parent does not silently implement the delegated work itself.

This is prompt-level behavior, not Agent Hive runtime parity. It has no Hive tools, state, task DAG, board, or worktree lifecycle, and it does not install `oc-arkive`, OpenCode commands, `opencode.json`, `tui.json`, `agent_hive.json`, or an OpenCode `AGENTS.md` profile. Execution stays inside Cursor's own subagent, editor, terminal, project-copy, and Rules features.

## What Cursor v1 Includes

The selected Cursor asset root contains:

- eight subagents: `approach-advisor`, `code-reviewer`, `forager`, `investigator`, `plan-reviewer`, `scout`, `simplicity-reviewer`, and `vulnerability-reviewer`
- eleven installed commands: eight Cursor-specific commands (`compact-summary`, `council-directive`, `council`, `dash-review`, `grill`, `implementation-brief`, `interview`, `vuln-review`) plus the three shared canonical commands `interview-drill-down`, `planning-prompt`, and `reflect`, which install from `.apm/prompts/`
- twenty-five managed Cursor skills installed into Cursor `skills/`: `adversarial-review`, `agents-md-mastery`, `brainstorming`, `code-design-principles`, `complexity-audit`, `complexity-review`, `finishing-a-development-branch`, `grilling`, `how`, `humanizer`, `orchestrating-ad-hoc-work`, `parallel-exploration`, `pr-writing`, `project-verification`, `stop-design-slop`, `stop-slop`, `subagent-delegation`, `systematic-debugging`, `test-driven-development`, `unslop`, `using-git-worktrees`, `verification`, `why`, `writing-for-agents`, and `writing-for-humans`. `writing-policy` is retired; `unslop` replaces it with no alias
- fifteen shared canonical skills consumed from `.apm/skills/` and installed once into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` for both Cursor and OpenCode: `aero-design`, `connecting-atlassian-tools`, `cymbal`, `decomposing-work`, `drawio-skill`, `frontend-slides`, `hard-cut`, `managing-work-in-jira`, `react-best-practices`, `resume-tailoring`, `running-agile-delivery`, `ui-mockups`, `web-design-guidelines`, `working-with-atlassian`, and `writing-work-items`. They are not copied into Cursor `skills/` or the OpenCode config `skills/` directory
- optional personal skill `ivan-writing` installed into the agents dir when `CURSOR_INSTALL_IVAN_WRITING=1` is set
- one composed default-Agent Rules payload: `rules/default-agent.md`, one separator, the capability contract in `rules/capability-contract.md` (Required Skills and Capability-Based Tool Selection), and the provenance-pinned Engineering Judgment snapshot under `vendor/oc-arkive/engineering-judgment/`
- the same contract and snapshot appended to each installed agent file: each installed agent file carries the source agent (frontmatter first), one separator, the capability contract, and the pinned snapshot, so no child depends on User Rules reaching it

The default Cursor-specific source root is `.apm/cursor`. If APM validation rejects unknown `.apm/cursor/**` content and a later task moves the bundle, the helper also supports the fallback root `cursor-assets/`. The shared command sources (`reflect`, `planning-prompt`, `interview-drill-down`) remain under `.apm/prompts/` in either layout. Do not hardcode only one Cursor-specific root in local automation; let `scripts/cursor-assets.sh` select it.

## Why A Helper Installs The Assets

Current APM documentation shows project-local Cursor deployment under a repository `.cursor/` directory. It does not prove that pure `apm install -g` deploys agents, commands, skills, and Rules into global `~/.cursor`.

For v1, `scripts/cursor-assets.sh` is the installer boundary. It validates the selected Cursor-specific asset root and the pinned Engineering Judgment provenance, rejects a competing `.apm/cursor/commands/<name>.md` for any shared command, copies `/reflect`, `/planning-prompt`, and `/interview-drill-down` from `.apm/prompts/`, composes each agent file with the capability contract and the pinned snapshot, installs the other supported assets into one or more target Cursor config directories, and prints the composed Rules text for manual paste. When install replaces existing Cursor files or directories, it writes backups before replacement into a new `.backup/custom-opencode-configs-cursor-<timestamp>.<suffix>/` directory per target and run, so two installs in the same second keep separate backups.

APM also routes the `.apm/prompts/*.prompt.md` files to project-local Opencode and Cursor command targets. APM may normalize frontmatter or newlines, so semantic metadata/body parity is the contract there; helper installs remain byte-identical to the canonical source. The shared prompts handle `$ARGUMENTS` portably: OpenCode interpolates it, and when the token stays literal in Cursor the command uses the text typed after the command name.

The target defaults to `~/.cursor`. For inspection, set `CURSOR_CONFIG_DIR` to a temporary directory. For dual installs, set `CURSOR_CONFIG_DIRS` to a semicolon-separated list.

## Prerequisites

- Run commands from this repository root.
- `python3` must be available on `PATH`.
- `scripts/cursor-assets.sh` must exist and be executable.
- The default target is `${HOME}/.cursor`.
- Set `CURSOR_CONFIG_DIR=/path/to/cursor-config` to validate, dry-run, or install into one custom target.
- Set `CURSOR_CONFIG_DIRS="/path/one;/path/two"` to install into multiple Cursor config roots.
- Railway CLI with auth installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it.
- `uv` plus the draw.io desktop CLI when you want the packaged `drawio-skill` to generate or export diagrams. Graphviz (`dot`) is optional for auto-layout.
- Node.js when you want `frontend-slides` PDF export or Vercel deploy helpers; `uv` when converting PPTX.
- `ui-mockups` needs an exposed image generation or editing tool that accepts reference images; it names no specific tool and reports a missing one before generating. Its layout references use Pillow, its storyboard helper runs through `uv` (`--with pillow --with numpy`) and needs `fc-match` from fontconfig unless font file paths are passed, and studying a named reference site needs a browser tool. Its transition storyboards also need an `animate` skill installed separately (for example at `~/.agents/skills/animate/SKILL.md`); this repository does not install it.
- Shared canonical skills install to `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`. Override that destination with `AGENTS_SKILLS_DIR`. Tests and other installer runs that keep the real `$HOME` must set this to a temp directory so they do not mutate `~/.agents/skills`.
- `connecting-atlassian-tools`, `managing-work-in-jira`, and `working-with-atlassian` are part of the fifteen shared canonical skills. They install once into that agents dir for both Cursor and OpenCode and are not copied into Cursor `skills/` or the OpenCode config `skills/` directory.
- `stop-design-slop` is Cursor-only. It lives in `.apm/cursor/skills/stop-design-slop/` and installs with its full tree (`SKILL.md`, `references/`, `scripts/`, `assets/`, `examples/`) into each Cursor target `skills/` directory. Neither installer writes it to the agents dir or the OpenCode config `skills/` directory, because `oc-arkive` supplies it to OpenCode.
- Set `CURSOR_INSTALL_IVAN_WRITING=1` to also install the personal `ivan-writing` skill from `profiles/personal/skills/ivan-writing/` into the agents dir.
- When installed, the Rules select its technical/product register for prose to or as Ivan; the requested authorship remains separate. `ivan-writing` defers to `writing-for-humans` for substantial prose: the Cursor bundle installs that skill, and OpenCode loads Hive's copy. The skill keeps its own technical/product clarity checks and working-note preference. Internal worker reports stay neutral unless requested, and PR and review drafts require explicit personal-voice selection under `pr-writing`.
- Accepted values: unset/empty (opt-out, no personal skill) and exact `1` (opt-in). Any other value (0, false, 2, etc.) fails before install or dry-run starts.
- When opt-in installs `ivan-writing`, the helper writes a hidden marker file `ivan-writing/.cursor-managed` inside the agents-dir skill directory. A leftover Cursor `skills/ivan-writing` is left in place and reported as a conflict with the agents-dir install path.
- On later opt-out (CURSOR_INSTALL_IVAN_WRITING unset), an agents-dir `ivan-writing` that still has `.cursor-managed`, and a Cursor `skills/ivan-writing` that still has `.cursor-managed`, are left in place and reported as unversioned. If no marker exists, an existing `ivan-writing` directory is left untouched and is not reported. A deleted-then-recreated user-owned directory is preserved.
- Cursor and OpenCode also scan `~/.claude/skills`, so shared skills must not be left there either. A leftover `humanizer`, `stop-design-slop`, `stop-slop`, `unslop`, `writing-for-agents`, `writing-for-humans`, or `writing-policy` in `~/.claude/skills` still shadows Hive's bundle and is not reported by either installer.
- A shared canonical name found in a Cursor `skills/` directory is left in place and reported as a conflict with `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}/<name>`. Retired names `consolidate-test-suites`, `root-cause-finder`, and `writing-policy` found there (or `writing-policy` in the agents dir) are left in place and reported as unversioned. A Hive-bundled skill (`humanizer`, `stop-design-slop`, `stop-slop`, `unslop`, `writing-for-agents`, `writing-for-humans`) found in the agents skills directory is left in place and reported as a conflict with the Cursor config `skills/<name>` path. That includes a `stop-design-slop` that an earlier install of this repository put in the agents dir. A `stop-design-slop` already in a Cursor `skills/` directory is the managed destination: the install replaces it and does not report it. Dry-run prints the same `decision needed` lines, changes nothing, and exits 1 when any finding exists. A clean dry-run exits 0. Install finishes the managed copy first, including every `CURSOR_CONFIG_DIRS` target, then exits 1 once when any decision line was printed. A clean install exits 0.

## Windows Cursor With WSL Projects

Windows Cursor can use a different global asset root when the active project is opened through WSL. Installing only into the Windows config directory can leave WSL projects without the file-based agents, commands, and skills; installing only into WSL can leave normal Windows projects without them.

When Windows Cursor is used for both Windows and WSL workspaces, install into both config roots:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install --dry-run
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
```

Replace `<WindowsUser>` with the Windows account name. The first target is the WSL global Cursor config. The second target is the Windows global Cursor config as seen from WSL. If running from Git Bash on Windows, use the Git Bash path for the Windows config instead.

## Install Flow

Validate the asset bundle first:

```bash
./scripts/cursor-assets.sh validate
```

Inspect the copy plan against a temporary target:

```bash
cursor_temp="$(mktemp -d)"
agents_temp="$(mktemp -d)"
CURSOR_CONFIG_DIR="$cursor_temp" AGENTS_SKILLS_DIR="$agents_temp" ./scripts/cursor-assets.sh install --dry-run
```

Install into the target Cursor config directory:

```bash
./scripts/cursor-assets.sh install
```

Install into two target Cursor config directories:

```bash
CURSOR_CONFIG_DIRS="/path/to/first;/path/to/second" ./scripts/cursor-assets.sh install
```

Print the default-Agent Rules text, or one installed agent prompt as it will land in the target:

```bash
./scripts/cursor-assets.sh print-rules
./scripts/cursor-assets.sh print-agent forager
```

Paste that output into Cursor Customize -> Rules -> User Rules. The helper does not write undocumented Cursor settings files. If `vendor/oc-arkive/engineering-judgment/provenance.json` records a new `sha256`, or `rules/default-agent.md` or `rules/capability-contract.md` changes, rerun `print-rules` and replace the previously pasted Rules text.

The vendored Engineering Judgment snapshot is provenance-pinned to oc-arkive 5.2.0 source metadata (Agent Hive commit `bce587395000ebdb4d381d2ad183b2673b374065`). OpenCode receives Engineering Judgment from the installed plugin; this repository does not duplicate it in OpenCode AGENTS profiles, config, agents, commands, or skills. Cursor continues to use that vendored snapshot because Cursor cannot load the plugin prompt directly. The same snapshot is appended to every installed agent file, and an agent's source file only points at the appended section.

Cursor User Rules apply to the parent Agent Chat, not Inline Edit, and Cursor does not document guaranteed propagation into every child subagent. The installed agent definitions and parent handoff packets therefore carry critical child instructions. `unslop` owns prose routing. `rules/default-agent.md` still runs a short prose finish loop for the parent. Each of the eight agent definitions requires the child to load `unslop`, and every installed agent file carries the Required Skills section, which tells each child to load a required skill by exact name, or read its installed `SKILL.md` manually when Cursor offers no loader, and to report a skill it could not load. The `subagent-delegation` skill requires every handoff to state the governing workspace, authority, candidate and base, required skills, preserved contracts, destination identity, artifact, audience, voice, and any additional depth or domain writing skills because parent-loaded skills do not propagate. Project `.cursor/rules/*.mdc` files are a separate opt-in mechanism for workspace-specific propagation; this helper does not create or install project rules automatically.

The Rules' `Request And Skill Precedence` section makes explicit user intent override skill defaults within higher-priority instructions, tool permissions, and project requirements. Clear implementation requests proceed; advice-only requests remain read-only. Skill-driven pauses cite the source instruction, and verification stops after acceptance and required gates unless new evidence warrants more checks. Reprint and manually repaste Rules after updating this guidance, and reinstall the changed managed skills.

## Planning, Isolation, And Integration

- **Planning.** Cursor's Plan mode (or a plan you paste) covers planning. `plan-reviewer` and `approach-advisor` assess a plan only when a plan is the artifact or you ask, and both read the same plan content.
- **Native isolation.** Cursor documents isolated project copies for subagents (each in its own Git worktree and branch), `/worktree`, `/apply-worktree`, and `/delete-worktree`. The Rules use them when the session exposes them and the parent can confirm the child works in a separate directory and branch. Otherwise the parent creates a Git worktree itself with `using-git-worktrees`. A subagent's separate context never isolates writes by itself.
- **Shared resources.** Separate worktrees do not isolate ports, databases, generated files, or fixtures; each keeps one explicit owner.
- **Integration authority.** Settled before placement and never implied by a worktree: see the introduction. Push, pull request, publish, and release each need their own request. `finishing-a-development-branch` holds the finishing steps.
- **Child sessions.** Every child returns one terminal report and every follow-up is a fresh child. Continuing a session needs an explicit operator instruction or a native interrupted-session mechanism. Recovery of an interrupted writer requires evidence that the writer and its subprocesses stopped, preserves the error and directory state, and lets a fresh worker adopt only edits attributable to the prior worker (`orchestrating-ad-hoc-work`).
- **Reviews.** Source changes get paired correctness and simplicity review. High-risk surfaces add an independent challenge from an existing reviewer under an explicit adversarial posture. Bounded mechanical, docs, or tests changes get one correctness lens, and verification-only gates get no review. Reviews, including `/dash-review` and `/vuln-review`, are source reviews by default and every reviewer stays read-only. When runtime proof would settle a material question, the parent commissions `investigator` only when an operator instruction already covers that exercise's purpose, candidate, and effects; otherwise it names the gap or asks. Security leads are never exploited against live systems, and the investigator does not count as a reviewer.
- **Experiments.** `investigator` handles standalone diagnosis, reproduction, scoped temporary experiments, verify-only runs, and assessments from source or evidence. `forager` keeps implementation and the diagnosis coupled to its own lane, and `scout` keeps bounded retrieval. An experiment names its candidate exactly (the commit plus relevant staged, unstaged, and untracked changes, or a runtime URL or environment, or the materials to read), runs variants only in a disposable placement, keeps its evidence outside every worktree, and closes on evidence plus cleanup without any commit or merge. Verify-only work changes no source, test, fixture, snapshot, or gate, even when a check fails. `investigator` sets `readonly: false` only so authorized experiments can write scratch files and probes; it is not a council seat.
- **History intent.** Before integrating, the parent declares each repository's history as private (unpublished worker commits, which may be squashed) or published (commits already pushed or shared, which integrate by a normal merge). For published history it runs `git merge-base --is-ancestor <published-tip> <destination>` and requires exit 0 before removing the source. Cursor's `/apply-worktree` is treated as a private-history path because this package has no observable proof that it preserves ancestry. Multi-repository work keeps per-repository target and pin maps and reports each outcome separately; nothing is described as atomic. When the destination moves, the parent records the newly observed target separately from the original checkpoint. Only a `forager` given an explicit reconciliation assignment with commit authority merges that newer target into the source; without commit authority, the drift goes back to the operator.
- **Worktree cleanup.** Cursor documents automatic cleanup that keeps only the newest worktrees up to a machine-wide cap and treats worktrees made with `git worktree add` or `/worktree` as eligible. The Rules therefore keep experiment and failure evidence outside worktrees. The helper changes no Cursor setting.

## Models

Every agent file sets `model: inherit`, so each subagent runs on the model the parent Agent uses. Cursor's subagent documentation accepts `inherit` or a specific model ID with bracketed options such as `[effort=high]`, but it publishes no model ID for the OpenAI Sol 6.1 or Terra 6.1 models this repository's OpenCode profile uses, and the OpenCode IDs `openai/gpt-6.1-sol` and `openai/gpt-6.1-terra` are not validated Cursor IDs. Select the unsuffixed Sol 6.1 or Terra 6.1 model (not a fast or ultrafast variant) and the reasoning effort the work needs in Cursor's model picker; the OpenCode seat map in [README.md](README.md#agent-hive-config) shows the efforts that profile pairs with each role. The agent files carry no reasoning-variant field and no fallback model. Cursor may substitute a compatible model when a plan or administrator setting blocks the selected one, and a per-task model choice the parent makes, where Cursor offers one, is a Cursor-native option rather than enforced parity with the OpenCode profile.

## Documented Cursor Capabilities Versus Validated Behavior

This package is validated statically: asset validation (including the agent roster, each role's `readonly` flag, and the composed capability contract), install layout, rendered agent prompts, and the install contract tests. The contract tests check delivered wording for the experiment, integration, capability, and review-authority scenarios; that is not evidence that a model follows the wording. Cursor's documentation describes subagents (including parallel and nested launches, resuming by agent ID, and isolated copies), skills, Rules, Plan mode, and worktrees, but this repository has not run them. The Cursor CLI is not installed on the maintainer host, so live Cursor behavior, such as whether a subagent receives User Rules or whether a native isolation request produces a separate worktree, stays unvalidated. The Rules therefore ask the parent to confirm placements instead of assuming them, and these docs make no live-parity claim.

## Maintainer Sync

Maintainer sync requires Git, Python 3, and a local Agent Hive checkout containing the selected ref. The scripts resolve that ref to a full commit and read committed Git objects, so dirty checkout files are ignored and no network access is required.

Engineering Judgment:

```bash
./scripts/sync-engineering-judgment.py \
  --source-repo /path/to/agent-hive \
  --ref <commit-or-ref>
./scripts/cursor-assets.sh validate
```

`scripts/sync-cursor-hive-skills.py` owns every imported Hive skill, including the writing skills. At the pinned commit (Agent Hive `bce587395000ebdb4d381d2ad183b2673b374065`) it copies these nineteen skills as full trees (`SKILL.md`, `references/`, scripts, licenses, and `UPSTREAM.md`): `adversarial-review`, `agents-md-mastery`, `brainstorming`, `code-design-principles`, `complexity-audit`, `complexity-review`, `grilling`, `how`, `humanizer`, `pr-writing`, `project-verification`, `stop-slop`, `systematic-debugging`, `test-driven-development`, `unslop`, `verification`, `why`, `writing-for-agents`, and `writing-for-humans`. `vendor/oc-arkive/cursor-skills/provenance.json` records the source and installed SHA-256 of every file, and `scripts/cursor-assets.sh validate` rejects a missing, extra, or edited file.

The source pin is tagged `v5.2.0` and its `package.json` declares 5.2.0. Provenance records the source commit and file hashes; it does not attest which build a running OpenCode process loaded. Both hosts route prose through `unslop`; `writing-policy` is retired. Cursor installs a selected, rendered subset of Hive skills, while OpenCode receives all 29 bundled skills from the plugin. The installers' ownership sets differ because the hosts have different responsibilities.

The sync accepts earlier `provenance.json` only when it parses and every recorded skill name is a canonical direct-child name that is still imported or explicitly retired; anything else stops it before it writes. Earlier provenance never grants deletion rights. The sync deletes a skill directory only when `RETIRED_SKILLS` in the script names it.

Markdown is rendered for Cursor. Host sections written for the OpenCode hosts (`<!-- hive-host opencode-v1 -->` and `opencode-v2`) are dropped and their shared text kept; an unknown host name, a nested or unclosed section, a stray closing marker, or a marker that shares a line with other text fails the sync. A small table of exact rewrites in the sync script (Hive-only wording, the `$ARGUMENTS` placeholder, the OpenCode compatibility note) must each match their source passage once, so a moved source passage fails the sync instead of shipping stale text. After rewriting, the sync also fails when an imported Markdown file other than `UPSTREAM.md` and the licence files still contains a host section marker, a `skill({` call, a `hive_` tool name, the words `Hive`, `OpenCode`, or `oc-arkive`, or the phrase `native skill`. These checks match those exact markers and name patterns. They help a reviewer catch a Hive role, state, or invocation before it ships as a Cursor instruction; they do not prove that no instruction Cursor lacks can ship, so a manual host review of the rendered diff stays part of every sync. `UPSTREAM.md` and licence files keep their source bytes and wording. They record the source runtime and ownership, are not Cursor operational instructions, and are not scanned. A skill the sync no longer imports (`writing-policy`) is removed from the shared set and reported. The sync does not import the TypeScript runtime.

Source-to-Cursor mapping of the twenty-nine Agent Hive skills:

| Agent Hive skill | Cursor |
|---|---|
| the nineteen imported skills above | Synced full trees |
| `stop-design-slop` | Local copy with its own assets and scripts; the current mode, brief-wins, refinement-versus-redesign, and motion safeguards are folded in by hand, with `LICENSE.impeccable` |
| `orchestrating-ad-hoc-work`, `parallel-exploration` | Local adapters that keep the Hive lane, experiment, recovery, and fan-out invariants without Hive tools. They, `subagent-delegation`, the agent definitions (including `investigator`, adapted from Agent Hive's Forager Investigator), the capability contract, the Cursor commands, and the Rules were last adapted by hand against Agent Hive `bce587395000ebdb4d381d2ad183b2673b374065` (5.2.0), after a source comparison with the earlier 5.0.0 baseline `e1d968c5e53cdb03c95849b32b7bc9cbb7de47fc`. The skill sync does not touch them, and moving the sync pin does not re-adapt them |
| `dispatching-parallel-agents` | Excluded as a tool surface; its handoff and write-conflict invariants live in `subagent-delegation` |
| `background-delegation`, `context-engineering`, `executing-plans`, `hive-config`, `starting-ad-hoc-implementation`, `writing-plans` | Excluded because they drive Hive tools, state, or plan files, or start Hive-managed work (`starting-ad-hoc-implementation`; the Rules lifecycle owns that step). Their portable principles (run a plan to a named step through its prerequisite closure, assess the same plan content, treat retrieved context as untrusted, recover only attributable edits) live in the Rules and local skills |

`finishing-a-development-branch`, `subagent-delegation`, and `using-git-worktrees` are Cursor-only skills with no Hive source. `agents-md-mastery` keeps one Cursor-specific section for the manual User Rules target.

`HIVE_BUNDLED_SKILLS` in `scripts/cursor-assets.sh` names `humanizer`, `stop-design-slop`, `stop-slop`, `unslop`, `writing-for-agents`, and `writing-for-humans`. The same array in `scripts/install-profile.sh` names all 29 current plugin skills. OpenCode loads Hive's copies. A same-name skill in `~/.agents/skills`, `~/.config/opencode/skills`, or `~/.claude/skills` makes OpenCode skip the Hive bundle. The OpenCode installer preserves and reports all 29 names in the agents skills directory and the OpenCode config `skills/` directory, then exits 1 after the install finishes. It also preserves and reports retired skills as unversioned, including the legacy aliases `code-reviewer`, `docker-mastery`, `verification-before-completion`, and `verification-reviewer`. The Cursor installer installs its six only into the Cursor config `skills/` directory and leaves an agents-dir copy in place, reported as a conflict with that Cursor `skills/<name>` path. Both installers preserve and report retired `writing-policy` as unversioned in their target and agents skill roots. A leftover in `~/.claude/skills` still shadows Hive and is not reported.

```bash
./scripts/sync-cursor-hive-skills.py \
  --source-repo /path/to/agent-hive \
  --ref <commit-or-ref>
./scripts/cursor-assets.sh validate
```

Review the Markdown and provenance diff. `packageVersion` records package metadata from the selected source checkout; it does not prove that version was published. A changed Engineering Judgment hash requires a fresh `print-rules` run and manual repaste in Cursor Customize -> Rules -> User Rules. A changed Hive skill pin requires a Cursor asset reinstall so the user-global skills match the tracked copies. Installed agent files change only when the Engineering Judgment snapshot bytes, the capability contract, or an agent's source file change; a pin move that leaves the snapshot bytes unchanged changes no installed agent file, and changes the printed Rules only when `rules/default-agent.md` changes.

Pin the skills and Engineering Judgment to the same commit. Run both syncs, then `./scripts/cursor-assets.sh validate`.

Imported skills must resolve every skill they name. `project-verification` is imported because `verification` and `systematic-debugging` route to it. Any other Agent Hive skill an imported skill names is either a Cursor-local skill or listed as undelivered in `scripts/cursor-assets.sh`, whose validation fails when a delivered file refers to an undelivered skill. When a new pin makes an imported skill name another Agent Hive skill, import it, adapt it by hand, or list it as undelivered before the pin lands.

Syncing changes tracked files only. The user-global Cursor copies change when `./scripts/cursor-assets.sh install` runs, and the Rules in Cursor change only when you paste the `print-rules` output again. Repaste is needed only when `rules/default-agent.md`, `rules/capability-contract.md`, or the Engineering Judgment snapshot hash changes; a pin move that leaves all three unchanged needs none.

## What Is Deliberately Excluded

Cursor v1 excludes the Agent Hive runtime command and tool surface because those pieces belong to Opencode plus `oc-arkive`, not Cursor prompt assets.

Excluded examples include:

- Hive lifecycle commands such as plan approval, task sync, worktree start, merge, and feature completion
- Hive MCP/tool calls and OpenCode-only tool syntax
- `opencode.json`, `tui.json`, `agent_hive.json`, Opencode `AGENTS.md`, and optional Opencode MCP snippets
- the `oc-arkive` plugin and the VS Code companion extension

The Cursor assets can describe workflows and review expectations, but they cannot create Agent Hive features, update Hive task state, call Hive tools, or guarantee the same runtime behavior as Opencode.

The shared `/reflect` command uses only evidence and targets available to the current harness. In Cursor, it waits for operator approval before editing accessible instruction files; when a scratchpad or global target is unavailable, it returns the approved exact change and manual destination without claiming to apply it. Cursor User Rules uses the explicit `cursor-user-rules:manual` target: the current Rules text must be supplied or visible for conflict analysis, and an approved change is returned with exact manual-paste instructions rather than a claim that Cursor Settings was read or edited.

## Verify The Installed Layout

After installing, check every target config directory. If you used a custom target, inspect `${CURSOR_CONFIG_DIR:-$HOME/.cursor}` instead of the literal `~/.cursor` examples below. If you used `CURSOR_CONFIG_DIRS`, inspect each semicolon-separated target.

```bash
cursor_target="${CURSOR_CONFIG_DIR:-$HOME/.cursor}"
ls "$cursor_target/agents"
ls "$cursor_target/commands"
ls "$cursor_target/skills"
```

Expected high-level layout:

```text
~/.cursor/agents/approach-advisor.md
~/.cursor/agents/code-reviewer.md
~/.cursor/agents/forager.md
~/.cursor/agents/investigator.md
~/.cursor/agents/plan-reviewer.md
~/.cursor/agents/scout.md
~/.cursor/agents/simplicity-reviewer.md
~/.cursor/agents/vulnerability-reviewer.md
~/.cursor/commands/compact-summary.md
~/.cursor/commands/council-directive.md
~/.cursor/commands/council.md
~/.cursor/commands/dash-review.md
~/.cursor/commands/grill.md
~/.cursor/commands/implementation-brief.md
~/.cursor/commands/interview.md
~/.cursor/commands/interview-drill-down.md   (from .apm/prompts)
~/.cursor/commands/planning-prompt.md        (from .apm/prompts)
~/.cursor/commands/reflect.md                (from .apm/prompts)
~/.cursor/commands/vuln-review.md
~/.cursor/skills/adversarial-review/SKILL.md
~/.cursor/skills/agents-md-mastery/SKILL.md
~/.cursor/skills/brainstorming/SKILL.md
~/.cursor/skills/code-design-principles/SKILL.md
~/.cursor/skills/complexity-audit/SKILL.md
~/.cursor/skills/complexity-review/SKILL.md
~/.cursor/skills/finishing-a-development-branch/SKILL.md
~/.cursor/skills/grilling/SKILL.md
~/.cursor/skills/how/SKILL.md
~/.cursor/skills/humanizer/SKILL.md
~/.cursor/skills/orchestrating-ad-hoc-work/SKILL.md
~/.cursor/skills/parallel-exploration/SKILL.md
~/.cursor/skills/pr-writing/SKILL.md
~/.cursor/skills/project-verification/SKILL.md
~/.cursor/skills/stop-design-slop/SKILL.md
~/.cursor/skills/stop-slop/SKILL.md
~/.cursor/skills/subagent-delegation/SKILL.md
~/.cursor/skills/systematic-debugging/SKILL.md
~/.cursor/skills/test-driven-development/SKILL.md
~/.cursor/skills/unslop/SKILL.md
~/.cursor/skills/using-git-worktrees/SKILL.md
~/.cursor/skills/verification/SKILL.md
~/.cursor/skills/why/SKILL.md
~/.cursor/skills/writing-for-agents/SKILL.md
~/.cursor/skills/writing-for-humans/SKILL.md
```

For a non-destructive verification run, install into a temp directory and inspect that directory instead:

```bash
cursor_temp="$(mktemp -d)"
agents_temp="$(mktemp -d)"
CURSOR_CONFIG_DIR="$cursor_temp" AGENTS_SKILLS_DIR="$agents_temp" ./scripts/cursor-assets.sh install
ls "$cursor_temp/agents" "$cursor_temp/commands" "$cursor_temp/skills"
ls "$agents_temp"
```

For dual-target verification, install into two temp directories:

```bash
one="$(mktemp -d)"
two="$(mktemp -d)"
agents_temp="$(mktemp -d)"
CURSOR_CONFIG_DIRS="$one;$two" AGENTS_SKILLS_DIR="$agents_temp" ./scripts/cursor-assets.sh install
```

Then inspect `$one`, `$two`, and `$agents_temp`.

## Smoke Testing

No live Cursor behavioral smoke test is required for v1. The acceptance boundary is static validation, installed file layout (including each agent file with the appended snapshot), and manual Rules paste into Cursor Customize -> Rules -> User Rules. Rules do not update themselves: after any change to the Rules text, the capability contract, or the Engineering Judgment snapshot hash, run `print-rules` and paste the complete output again. Live Cursor behavior, including subagent routing, skill loading, native isolation, and `/apply-worktree`, has not been exercised from this repository because no Cursor CLI is installed on the maintainer host.

## Integration Tests

Run the install contract tests from the repository root:

```bash
bash tests/test-install-contracts.sh
```

The test builds isolated repository fixtures in a temp directory — it never moves, deletes, or mutates repository source files. The EXIT trap only cleans up temp fixtures.
