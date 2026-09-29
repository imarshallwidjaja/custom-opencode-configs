# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@latest` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

Running `./scripts/install-profile.sh` with no arguments previews the install without changes or hooks. Add `--apply` to install immediately, or `--help` for usage.

`./scripts/install-profile.sh --apply` installs these files into your Opencode config directory:

- `profiles/base/opencode.json` -> `opencode.json`: base Opencode config with `oc-arkive@latest`. It turns off Opencode's internal file-change snapshots (`snapshot: false`), so agent edits cannot be rolled back through the Opencode UI, and startup self-updates (`autoupdate: false`), so update Opencode yourself. It also disables the built-in `explore` agent so read-only research goes to Hive's `scout-researcher`
- `profiles/base/agent_hive.json` -> `agent_hive.json`: Agent Hive role and model configuration
- `profiles/base/plugins/dcg-guard.js` -> `plugins/dcg-guard.js`: Destructive Command Guard adapter, auto-loaded from the Opencode plugins directory
- `profiles/base/plugins/shell-agents.js` -> `plugins/shell-agents.js`: nested `AGENTS.md` discovery for Bash tool calls, auto-loaded from the same directory (see [Base plugins](#base-plugins))
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`: OpenCode-local skill (`writing-skills`). The installer replaces that name in place from `.apm/skills/`, removes leftover copies of the shared canonical skills, leftover Hive-owned skill names, and leftover retired OpenCode-local skills (`using-git-worktrees`, `finishing-a-development-branch`, `consolidate-test-suites`, `root-cause-finder`, `context-mode`), and leaves other existing skill directories in place (for example `impeccable` from `npx impeccable install`).
- `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`: shared canonical skills used by both OpenCode and Cursor, plus personal skills from `profiles/personal/skills/` when the selected AGENTS profile is `personal-default` or `personal-context-improved`. Override the destination with `AGENTS_SKILLS_DIR`. Tests and other installer runs that keep the real `$HOME` must set this to a temp directory so they do not mutate `~/.agents/skills`.
- `commands/`: non-Hive prompt-backed commands packaged under `.apm/prompts/` (`interview-drill-down`, `planning-prompt`, `reflect`)
- `agents/`: installed only when this repository packages standalone Opencode agents

If those target paths already exist, the installer writes a timestamped backup under `<target>/.backup/` before replacing managed files. In `skills/` it replaces the OpenCode-local skill, removes leftover shared canonical, Hive-owned, and retired OpenCode-local skill names, and leaves other existing skill directories in place. In `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, it backs up `working-with-atlassian`, `managing-work-in-jira`, and `connecting-atlassian-tools`, which earlier versions of this profile installed, into `<target>/.backup/<timestamp>/agents-skills/` and then removes them, including dangling symlinks with those names. Other skills there are left alone. Set `OPENCODE_AGENTS_MODE=skip` when you want to update the profile files but keep an existing `AGENTS.md` in place for a manual merge.

## Requirements

Base setup requires:

- `git`
- `curl`
- `opencode`
- OpenAI access for `openai/gpt-6-luna-fast`, `openai/gpt-6-sol`, `openai/gpt-6-astra`, and `openai/gpt-5.6-sol` (primary orchestration seats only), used by the default `agent_hive.json`; the base `opencode.json` runs the `compaction` agent on `openai/gpt-6-luna-fast`
- OpenAI auth also covers the base `opencode-gpt-imagegen` plugin when you want image generation tools
- Railway CLI with auth installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it
- `uv` plus the draw.io desktop CLI when you want the packaged `drawio-skill` to generate or export diagrams; Graphviz (`dot`) is optional for auto-layout
- Node.js when you want `frontend-slides` PDF export or Vercel deploy helpers; `uv` when converting PPTX

The installer also copies `plugins/dcg-guard.js`. That plugin stays inactive until the `dcg` CLI is on `PATH`. Install Destructive Command Guard with:

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --easy-mode
```

See the upstream project: [Dicklesworthstone/destructive_command_guard](https://github.com/dicklesworthstone/destructive_command_guard). The plugin does not need extra Node packages; Opencode loads it from `plugins/` at startup.

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- a Context7 API key in `secrets/context7` under the Opencode config directory for the optional `context7` MCP entry, and a Keenable API key in `secrets/keenable` for the optional `keenable` MCP (see [MCP API keys](#mcp-api-keys))
- `uvx` and optionally the `cymbal` CLI for the context-improved workflow
- `npx` (Node.js) for the optional `chrome-devtools` browser MCP
- VS Code if you want the companion extension

Cursor prompt-level assets have a separate setup path. They are validated and installed by `./scripts/cursor-assets.sh` from the repository root, not by the Opencode profile installer. It requires `python3`, defaults to `${HOME}/.cursor`, accepts `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, and accepts semicolon-separated `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for dual installs. `CURSOR_INSTALL_IVAN_WRITING` accepts only unset/empty (opt-out) or exact `1` (opt-in); the skill is installed into the agents dir and backed up and removed on opt-out only when a helper-owned marker file exists. Shared canonical skills use `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`; the Cursor installer also backs up and removes the three formerly packaged Atlassian skills there, like the Opencode installer. See `CURSOR.md` for details.

Install Opencode if it is not already present:

```bash
curl -fsSL https://opencode.ai/install | bash
```

## Quick start

Fresh machine with the shared AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
./scripts/install-profile.sh --apply
opencode
```

Fresh machine with the sanitized personal-default AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
opencode
```

Fresh machine with the context-improved AGENTS profile and overlay:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
./scripts/write-secret.sh context7
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh --apply
opencode
```

Where:

- the repository clone requires GitHub access to this repo
- `opencode auth login -p openai` opens the ChatGPT OAuth flow; `opencode-gpt-imagegen` currently requires a ChatGPT Plus or Pro subscription through that OAuth path
- if Homebrew is available and you want the optional `cymbal` navigation CLI, run `brew install 1broseidon/tap/cymbal` separately
- the first `opencode` run should resolve `oc-arkive@latest` automatically from `opencode.json`

## Updating an existing install

To update an older install in place, update this repository clone and rerun the installer against the same Opencode config directory:

```bash
git pull
./scripts/install-profile.sh --apply
```

Use the same profile environment variables the install should keep, for example:

```bash
git pull
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
```

Use `OPENCODE_AGENTS_MODE=skip` when the target already has a hand-maintained `AGENTS.md` that should stay as the base document for a manual merge:

```bash
git pull
OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh --apply
```

Some notes:

- the installer replaces `opencode.json` with the base profile, which drops any optional bundle you enabled earlier. Reapply each one with `./scripts/enable-optional.sh <name>`; the `*-context-improved` profiles reapply `context-improved` themselves
- this profile no longer reads the Context7 key from `CONTEXT7_API_KEY`. Before reinstalling or reapplying a Context7 bundle, move it into the target config directory: `printf '%s\n' "$CONTEXT7_API_KEY" | OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}" ./scripts/write-secret.sh context7`. Remove the export from shell startup files, then `unset CONTEXT7_API_KEY` in the current shell
- restart every Opencode process that uses this config directory, including a long-lived `opencode serve`; Opencode reads config and plugins only at startup
- with a custom `OPENCODE_CONFIG_DIR`, Agent Hive still reads `$HOME/.config/opencode/agent_hive.json` (see [Target config directory](#target-config-directory))
- `curl -fsSL https://opencode.ai/install | bash` updates or installs the Opencode binary; it does not update this profile
- Opencode may keep using a cached copy of `oc-arkive@latest` after these files are updated; restart Opencode after installing the profile, and if the command surface still matches an older release, remove or refresh the cached `oc-arkive` plugin entry according to the local Opencode cache layout before starting Opencode again
- after restart, verify the loaded plugin manifest or available Agent Hive commands match the expected latest `oc-arkive` release
- the installer writes timestamped backups under `<target>/.backup/` before replacing managed files
- prefer preserving an existing customized `AGENTS.md` when unsure, then merge the selected profile guidance manually

## Install options

### Target config directory

Install into the default Opencode config directory:

```bash
./scripts/install-profile.sh --apply
```

Install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config AGENTS_SKILLS_DIR=/path/to/agents-skills ./scripts/install-profile.sh --apply
```

Shared canonical skills default to `$HOME/.agents/skills`. Set `AGENTS_SKILLS_DIR` when the installer must not write that live directory.

Agent Hive reads its config only from `$HOME/.config/opencode/agent_hive.json`, whatever `OPENCODE_CONFIG_DIR` says, and writes a default file there when none exists. A custom-directory install copies `agent_hive.json` into the custom directory and warns that Hive will not read it. Every Opencode config on the machine shares the default-location Hive file. Before replacing it, inspect it and preserve any routing you need; back up the actual destination if it exists:

```bash
hive_config="$HOME/.config/opencode/agent_hive.json"
ls -ld "$hive_config"  # inspect the existing file; a missing file is expected on a fresh install
if [[ -f "$hive_config" ]]; then less "$hive_config"; fi  # review existing routing
if [[ -e "$hive_config" || -L "$hive_config" ]]; then
  backup_dir="$(mktemp -d "$HOME/.config/opencode/.hive-backup.XXXXXX")"
  cp -a "$hive_config" "$backup_dir/agent_hive.json"
fi
cp -a "${OPENCODE_CONFIG_DIR:?set OPENCODE_CONFIG_DIR}/agent_hive.json" "$hive_config"
```

Use this workflow only after deciding that the installed Hive routing should replace the shared destination. If the destination is a directory, resolve that first; do not copy into it.

### AGENTS profiles

The installer uses `profiles/agents/shared.md` by default. Select another profile with `OPENCODE_AGENTS_PROFILE`. All four profiles include request-over-skill defaults, source citations for skill-driven pauses, and a stopping condition after required verification gates; preserve `Request And Skill Precedence` when merging into an existing profile. See `profiles/agents/README.md` for the operating-policy details and `CURSOR.md` for the equivalent manually pasted Cursor Rules.

Available profiles:

- `shared`: portable default for shared machines and team use
- `personal-default`: shared baseline plus Ivan's voice skill; that voice is selected only for prose published, submitted, or sent as Ivan, and internal reports stay neutral unless requested
- `shared-context-improved`: shared baseline plus routing rules for the optional context-improved toolchain
- `personal-context-improved`: personal-default plus the same context-improved routing rules

Install examples:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
```

```bash
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh --apply
```

```bash
OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh --apply
```

The two `*-context-improved` profiles require `jq`, `uvx`, and a non-blank `secrets/context7` file in the target Opencode config directory (see [MCP API keys](#mcp-api-keys)). The installer preflights those dependencies before changing anything and applies the matching `context-improved` overlay automatically.

### Agent Hive config

The installer copies `profiles/base/agent_hive.json`, the sole canonical Hive config. It uses `openai/gpt-6-luna-fast`, `openai/gpt-6-sol`, and `openai/gpt-6-astra`, plus `openai/gpt-5.6-sol` for the three primary-only orchestration seats (`hive-master`, `swarm-orchestrator`, and `hive-builder`) because `gpt-6-sol` is unsuitable for orchestration. Confirm the target environment resolves all four with `opencode models openai --verbose`; model listing does not prove inference access. As checked on September 29, 2026, `opencode models openai` lists `openai/gpt-6-luna-fast` while the models.dev enum referenced by the `opencode.json` `$schema` omits it; editors using that enum may flag the selected model until the schema catches up. The installer adds no credentials, local proxies, or provider shims. Personal `ivan-writing` and `impeccable` skill auto-loads stay out of the portable Hive config.

Routing uses cost-conscious effort defaults:

- Luna (`openai/gpt-6-luna-fast`) `high`: the sole `scout-researcher`, `forager-documents`, and `adversarial-documentation-reviewer`. Luna `medium`: `hive-helper` and the task-trace summarizer.
- Sol (`openai/gpt-6-sol`) `medium`: ordinary `forager-worker` and `plan-reviewer`. Sol `high`: `forager-capable`, `forager-ui`, `approach-advisor`, `ui-design-advisor`, and the adversarial plan, code, simplicity, and approach reviewers.
- Orchestration Sol (`openai/gpt-5.6-sol`) `high`: `hive-master`. Orchestration Sol `medium`: `swarm-orchestrator` and `hive-builder`.
- Astra (`openai/gpt-6-astra`) `medium`: `forager-smart` and `code-reviewer`. Astra `high`: `architect-planner` and `vulnerability-reviewer`. Astra `low`: UI, documentation, and simplicity first-pass reviewers. Astra `xhigh`: the boundary-changing `approach-advisor-xhigh-reasoning` seat.

`forager-worker` is the default for features, fixes, refactors, and integrations that follow established patterns. Choose `forager-capable` up front for coupled invariants, subtle state or concurrency behavior, and difficult cross-component diagnosis, and prefer it when genuinely unsure between the two. `forager-smart` is the rescue worker after a prior attempt hits a substantive technical dead end. Research is consolidated into `scout-researcher`; plan and code review each have one first-pass role. Adversarial passes supplement that first pass when the risk calls for them: `adversarial-code-reviewer` when a change touches public contracts, persistence, authorization, concurrency, state transitions, destructive behavior, or other failure-sensitive logic, or when the first review leaves correctness risk unresolved; `adversarial-simplicity-reviewer` when a change introduces or expands abstractions, configuration, flags, adapters, validation layers, fallback paths, or branching, or is materially larger than the request needs. Routine, localized changes with focused verification skip the adversarial code pass. The `minimal-change` council group pairs `simplicity-reviewer` with `adversarial-simplicity-reviewer`. The planner, swarm, and builder load `background-delegation` alongside their orchestration skills; only the ordinary worker's configured `autoLoadSkills` in this profile include `verification`. Agent Hive may prepend built-in defaults before these configured additions. Only the document-focused roles (`forager-documents`, `documentation-reviewer`, and `adversarial-documentation-reviewer`) auto-load `writing-policy`, together with `writing-for-humans`, `humanizer`, and `stop-slop`. Other seats load `writing-policy` on demand from its skill description and the AGENTS profile references. `hive-helper` is hardcoded to no auto-loaded skills. Personal `ivan-writing` stays out of this portable config.

An aligned `oc-arkive` release newer than 2.5.0 must publish before this repository is pushed; its version number is not known yet. It no longer bundles research MCPs, so `opencode.json` and the optional bundles supply those entries. The new Hive loader rejects the entire `agent_hive.json` when it contains the removed `disableMcps` or `sandbox` fields, then falls back to defaults; agents, customAgents, council, and model routing from that file are lost. Replace or update `agent_hive.json` to remove those fields before restarting Opencode. The base Hive config already omits them. Published 2.5.0 still registers its own research MCPs.

These defaults are a heuristic, not an experimentally optimal routing policy. The September 3, 2026 [DeepSWE](https://deepswe.datacurve.ai/) results supplied for this choice report Astra `xhigh` at 74 +/- 3% and $6.52, Sol `max` at 73 +/- 3% and $6.46, and Luna `max` at 67 +/- 4% and $0.61. Their confidence intervals overlap, and those runs do not establish performance at the lower efforts used here. Output tokens and steps are not wall-clock latency. Validate changes against representative repository tasks and mergeability criteria such as correctness, tests, scope, and style, as used by [FrontierCode](https://cognition.com/frontiercode), before promoting a default.

## VS Code companion extension

The Agent Hive / `oc-arkive` VS Code companion is distributed as a `.vsix` asset on the latest Agent Hive fork release:

- <https://github.com/imarshallwidjaja/agent-hive/releases/latest>

Install it with the VS Code CLI:

```bash
curl -L -o vscode-arkive.vsix https://github.com/imarshallwidjaja/agent-hive/releases/latest/download/vscode-arkive.vsix
code --install-extension ./vscode-arkive.vsix
```

Use the extension for:

- reviewing Hive plan files and context files
- seeing feature and task status in the sidebar
- adding review comments while Opencode remains the execution harness

## Cursor prompt-level assets

This repository also ships a Cursor v1 asset bundle for prompt-level behavior. Its default parent Agent uses Hive-Builder-like ad-hoc orchestration with Cursor-native named subagents: non-trivial work is delegated, while the parent owns lane coordination, diff inspection, combined verification, review, synthesis, and integration. The bundle installs reusable Cursor subagents, seven Cursor-specific commands, the shared canonical `/reflect` command, eight managed Cursor skills including `agents-md-mastery` into the selected Cursor config `skills/` directory, and sixteen shared canonical skills into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, then prints default-Agent Rules that you paste into Cursor Customize -> Rules -> User Rules. The vendored Engineering Judgment snapshot is provenance-pinned to oc-arkive 2.3.5. OpenCode receives Engineering Judgment from the installed plugin, without a second local copy in this repository's profiles or config surfaces. Cursor continues to use that vendored snapshot because Cursor cannot load the plugin prompt directly.

Delegation is a strong prompt policy, but Cursor routing is heuristic and not runtime-guaranteed. The parent has a bounded direct-work exception for coordination, setup, trivial conversation, and at most one bounded read, one bounded write or patch, and one cheap focused check. Separate context does not isolate files in a shared checkout. Overlapping writers require explicit worktrees or isolated project copies; otherwise children must own disjoint paths or run serially.

The printed Rules (`.apm/cursor/rules/default-agent.md`) carry a `## Prose Finish Gate` section. It is an always-on draft, audit, fix loop for human-facing prose. `writing-policy` owns routing and delegated propagation. Because User Rules do not reliably reach children, each of the six agent definitions under `.apm/cursor/agents/` requires the child to load and apply `writing-policy`, and the `subagent-delegation` skill requires handoffs to restate artifact, audience, voice, and any additional depth or domain writing skills.

Cursor v1 is not Agent Hive runtime parity. It has no Hive tools, state, task DAG, board, or worktree lifecycle, and it does not install `oc-arkive`, `opencode.json`, `agent_hive.json`, or an OpenCode `AGENTS.md` profile.

Prerequisites:

- run commands from this repository root
- `python3`
- Git and a local Agent Hive checkout containing the selected ref are required only for maintainer sync
- executable `scripts/cursor-assets.sh`
- default target `${HOME}/.cursor`, `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, or `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for multiple targets
- Railway CLI with auth installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it
- `uv` plus the draw.io desktop CLI when using `drawio-skill`; Graphviz (`dot`) is optional for auto-layout
- Node.js when using `frontend-slides` PDF export or Vercel deploy; `uv` when converting PPTX

Quick inspection flow:

```bash
./scripts/cursor-assets.sh validate
cursor_temp="$(mktemp -d)"
agents_temp="$(mktemp -d)"
CURSOR_CONFIG_DIR="$cursor_temp" AGENTS_SKILLS_DIR="$agents_temp" ./scripts/cursor-assets.sh install --dry-run
./scripts/cursor-assets.sh print-rules
```

Actual install:

```bash
./scripts/cursor-assets.sh validate
./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

Windows Cursor with WSL projects may need both the WSL config root and the Windows config root because Cursor can resolve file-based agents, commands, and skills differently for WSL workspaces. From WSL, use a dual install like this:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install --dry-run
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

After install, paste the printed Rules text into Cursor Customize -> Rules -> User Rules. When the vendored snapshot hash changes, rerun `print-rules` and repaste the complete output. User Rules apply to Agent Chat, not Inline Edit. Project `.cursor/rules/*.mdc` remains a separate opt-in mechanism and is not installed by this helper.

See `CURSOR.md` for the asset list, exclusions, verification steps, and the reason this repo uses a thin helper instead of claiming direct APM global Cursor deployment.

## Optional context-improved workflow

The context-improved workflow adds the local context and structural-search toolchain.

It enables:

- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry, with its API key read from `secrets/context7`
- Scout navigation rules for `cymbal` and `ast-grep`

Prerequisites:

- `jq`
- `uvx` available on `PATH`
- a non-blank `secrets/context7` file in the Opencode config directory
- `cymbal` on `PATH` if you want that navigation tool available to agents

Install `cymbal` with Homebrew when you want that tool:

```bash
brew install 1broseidon/tap/cymbal
```

Enable the context-improved overlay after a plain install:

```bash
./scripts/enable-optional.sh context-improved
```

If you select `shared-context-improved` or `personal-context-improved` during install, `scripts/install-profile.sh` applies this overlay automatically after checking the same prerequisites.

`cymbal` remains optional. When it is on `PATH`, `scripts/install-profile.sh` and the context-improved bundle both attempt to install its OpenCode hook into the selected `OPENCODE_CONFIG_DIR` with `cymbal hook install opencode --scope user`. That writes `plugins/cymbal-opencode.js`; this repository does not vendor that generated file. A hook failure warns without failing the install.

## Optional MCP bundles

Optional merge snippets live under `profiles/optional/`:

- `opencode.context-improved.json`
- `opencode.mcp-context7-enabled.json`
- `opencode.chrome-devtools.json`
- `opencode.keenable.json`

Apply a snippet with:

```bash
./scripts/enable-optional.sh chrome-devtools
```

The script validates prerequisites, backs up the current config file, and merges the chosen snippet into the active config.

`chrome-devtools` is the canonical interactive browser solution. It requires `npx` on `PATH` and launches `chrome-devtools-mcp@latest` with a non-absolute command, `--isolated=true` (a temporary browser profile that is deleted when the browser closes), and `--category-extensions=true` (browser-extension tools). It does not pass `--headless`, so Chrome opens a visible window.

`keenable` adds the remote Keenable web search and page-fetch MCP at `https://api.keenable.ai/mcp`. It sends the key from `secrets/keenable` as the `X-API-Key` header. Keenable also answers without a key on a shared public tier limited per IP address; this profile requires a key on purpose so agent traffic runs on your account's limits instead of that shared pool.

Useful checks:

```bash
npx --version
jq '.mcp["chrome-devtools"]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/opencode.json"
```

### MCP API keys

Optional MCP bundles read API keys from files under `secrets/` in the Opencode config directory. Their snippets use `{file:secrets/<name>}`, which Opencode resolves relative to the directory that holds `opencode.json`, so a custom `OPENCODE_CONFIG_DIR` keeps its own keys. Opencode refuses to start when a referenced file is missing. For that reason the base `opencode.json` references no secret file, and `scripts/enable-optional.sh` and the context-improved install stop before changing any config unless the file exists, is readable, and is not blank. The installers never create, copy, or back up `secrets/`; only `scripts/write-secret.sh` writes there. This repository ignores `secrets/` so a key cannot be committed by accident.

| Bundle | Secret file | Sent as |
| --- | --- | --- |
| `context-improved`, `mcp-context7-enabled` | `secrets/context7` | `CONTEXT7_API_KEY` header |
| `keenable` | `secrets/keenable` | `X-API-Key` header |

Write a key file from the repository root:

```bash
./scripts/write-secret.sh context7
./scripts/write-secret.sh keenable
```

The script prompts without echoing the key, so the key stays out of shell history, and it runs under Bash whatever your login shell is. It writes to `secrets/<name>` under `${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}`, sets the `secrets/` directory to mode 700, writes the key to a new mode-600 file, and renames that file over any existing one, so rotating a key never leaves the new value in a file with looser permissions. It refuses a blank key and leaves the old file in place. When stdin is not a terminal, it reads the first line of stdin instead, for example to move a key out of an environment variable.

Check a key file the same way the installers do, without printing the key:

```bash
LC_ALL=C grep -q '[^[:space:]]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present
```

## Base plugins

The base `opencode.json` installs:

- `oc-arkive@latest` for Agent Hive
- `opencode-gpt-imagegen` for OpenAI image generation tools

The installer also copies `plugins/dcg-guard.js`, which Opencode auto-loads from the config plugins directory. It intercepts `bash` tool calls when `dcg` is on `PATH`, and is a no-op when `dcg` is missing.

It also copies `plugins/shell-agents.js`. Opencode already attaches a nested `AGENTS.md` when the `read` tool opens a file below it. This plugin does the same for `bash`: when a command's working directory is a subdirectory of the project, it appends every non-empty `AGENTS.md` between that directory and the project root (the root file is excluded because Opencode loads it natively) as a system reminder on the command output. It skips any file already visible in the system prompt or in earlier tool output that compaction has not removed, and it applies the same deduplication to `read` reminders. Symlinks that resolve outside the project are ignored. If loading fails, the command output gets a short diagnostic reminder instead of failing the tool call. It uses Opencode's `experimental.chat.messages.transform` and `experimental.chat.system.transform` hooks, so an Opencode upgrade that changes those hooks can break it.

Opencode loads plugins only at startup. After installing or updating either plugin, restart every running Opencode process that uses this config directory, including a long-lived `opencode serve`. To check the plugin from this repository, run `bun test tests/shell-agents.test.js`; it needs Bun on `PATH` but no packages.

`opencode-gpt-imagegen` currently uses ChatGPT Plus or Pro OAuth from Opencode. It does not provide an API-key image path. No credentials are embedded in this repository.

## Prompt-backed commands

This profile ships three non-Hive prompt-backed commands from `.apm/prompts/`:

- `interview-drill-down`
- `planning-prompt`
- `reflect`

`.apm/prompts/reflect.prompt.md` is the only tracked `/reflect` source for both Opencode and Cursor. It reviews the current session for durable learnings, keeps provisional cross-project workflow and personification preferences in the user's existing scratchpad, and promotes them to global instructions only after repeated evidence and explicit operator approval. In Cursor, it can also return an approved `cursor-user-rules:manual` change for manual paste when the current User Rules text was supplied or visible; it never claims to read or edit Cursor Settings. The prompt contains no user-specific paths or fixed personal preferences.

Hive workflow commands still come from the published `oc-arkive` plugin, including `/interview`, `/implementation-brief`, `/hive-plan`, `/approve-sync-plan`, `/start-execution`, `/council-directive`, `/council`, and `/compact-summary`. Do not keep local copies of those Hive-owned command files in the Opencode config directory.

During install, `scripts/install-profile.sh` copies `.apm/prompts/*.prompt.md` into `commands/` and removes the old profile-managed Hive command names from the target `commands/` directory after backing that directory up. It removes only these Hive-owned legacy names:

- `approve-sync-plan`
- `compact-summary`
- `council-directive`
- `council`
- `hive-plan`
- `implementation-planning-prompt`
- `interview`
- `start-execution`

Reusable non-Hive behavior remains packaged as skills under `.apm/skills/`. OpenCode does not package Hive-overlapping skills; also does not package `context-mode`, `using-git-worktrees`, `finishing-a-development-branch`, `consolidate-test-suites`, or `root-cause-finder`. Hive/`oc-arkive` owns worktrees and merge and ships `brainstorming`, `systematic-debugging`, `test-driven-development`, `verification`, and `ast-grep`. Cursor keeps `using-git-worktrees` and `finishing-a-development-branch` because it has no Hive runtime, and still installs the overlapping names except `ast-grep`. Test placement is default Engineering Judgment / Quality Gates, not a separate skill. Shared Cursor copies of `brainstorming`, `systematic-debugging`, `test-driven-development`, and `verification` are provenance-pinned from Agent Hive with a Cursor-runtime rewrite. `agents-md-mastery` remains a Cursor-specific adaptation under `.apm/cursor/skills/` so it does not shadow Agent Hive's generated OpenCode skill. The sixteen shared canonical skills are `aero-design`, `cymbal`, `decomposing-work`, `drawio-skill`, `frontend-slides`, `hard-cut`, `humanizer`, `react-best-practices`, `resume-tailoring`, `running-agile-delivery`, `stop-design-slop`, `stop-slop`, `web-design-guidelines`, `writing-for-humans`, `writing-policy`, and `writing-work-items`. Both installers upsert those names into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` and leave them out of harness `skills/` directories. OpenCode prefers `~/.config/opencode/skills` over `~/.agents/skills` when both exist, so a leftover shared copy in the OpenCode skills directory would keep serving the stale tree; `scripts/install-profile.sh` removes leftover copies of those shared names, leftover Hive-owned skill names, and leftover retired OpenCode-local skill names from OpenCode `skills/` on install. Other existing skill directories stay. Personal OpenCode profiles also remove a leftover `skills/ivan-writing` after copying that skill into the agents dir. Cursor and OpenCode also scan `~/.claude/skills`, so shared skills must not be left there either. The Railway CLI, with auth, installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it. `drawio-skill` needs `uv` plus draw.io, and `frontend-slides` needs Node.js/`uv` for export helpers; both are otherwise inert. `aero-design` (Aero-inspired direction for data-rich interfaces such as dashboards, analytics, and tables) and the three agile theory skills (`decomposing-work`, `writing-work-items`, `running-agile-delivery`) have no prerequisites. Earlier versions of this profile also installed `working-with-atlassian`, `managing-work-in-jira`, and `connecting-atlassian-tools` into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`. Both installers now back those names up under their target's `.backup/` directory and remove them; other skills in that directory stay. The optional personal `ivan-writing` skill is installed into the agents dir for personal OpenCode profiles, and for Cursor only when `CURSOR_INSTALL_IVAN_WRITING=1`.

`writing-policy` is the compact router for human-facing prose. `writing-for-humans` remains the depth skill for substantial docs, plans, reports, reviews, and explanations. `stop-slop` (cadence and structure) and `humanizer` (vocabulary, register, attribution, formatting tells, chat artefacts) load only for matching rewrite problems. `stop-design-slop` ships `scripts/contrast_check.py` next to `scripts/audit_ui.py` for computed WCAG contrast ratios (`python3 scripts/contrast_check.py "#FFFFFF" "#777777"`, or `--selftest`); both need only `python3`.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository. That document covers both the Opencode profile setup and the separate Cursor prompt-level asset setup.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
