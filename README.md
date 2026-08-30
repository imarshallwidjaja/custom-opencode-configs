# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@latest` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

`./scripts/install-profile.sh` installs these files into your Opencode config directory:

- `profiles/base/opencode.json` -> `opencode.json`: base Opencode config with `oc-arkive@latest`
- `profiles/base/agent_hive.json` -> `agent_hive.json`: Agent Hive role and model configuration
- `profiles/base/plugins/dcg-guard.js` -> `plugins/dcg-guard.js`: Destructive Command Guard adapter, auto-loaded from the Opencode plugins directory
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`: OpenCode-local skills (`context-mode`, `writing-skills`). The installer replaces those two names in place from `.apm/skills/`, removes leftover copies of the shared canonical skills, leftover Hive-owned skill names, and leftover retired OpenCode-local skills (`using-git-worktrees`, `finishing-a-development-branch`, `consolidate-test-suites`, `root-cause-finder`), and leaves other existing skill directories in place (for example `impeccable` from `npx impeccable install`).
- `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`: shared canonical skills used by both OpenCode and Cursor, plus personal skills from `profiles/personal/skills/` when the selected AGENTS profile is `personal-default` or `personal-context-improved`. Override the destination with `AGENTS_SKILLS_DIR`. Tests and other installer runs that keep the real `$HOME` must set this to a temp directory so they do not mutate `~/.agents/skills`.
- `commands/`: non-Hive prompt-backed commands packaged under `.apm/prompts/` (`interview-drill-down`, `planning-prompt`, `reflect`)
- `agents/`: installed only when this repository packages standalone Opencode agents

If those target paths already exist, the installer writes a timestamped backup under `<target>/.backup/` before replacing managed files. In `skills/` it replaces the two OpenCode-local names, removes leftover shared canonical, Hive-owned, and retired OpenCode-local skill names, and leaves other existing skill directories in place. Set `OPENCODE_AGENTS_MODE=skip` when you want to update the profile files but keep an existing `AGENTS.md` in place for a manual merge.

## Requirements

Base setup requires:

- `git`
- `curl`
- `opencode`
- OpenAI access for the non-fast `openai/gpt-5.6-sol` and `openai/gpt-5.6-luna` models used by the default `agent_hive.json` and the base `opencode.json` `explore` / `compaction` overrides
- OpenAI auth also covers the base `opencode-gpt-imagegen` plugin when you want image generation tools
- `railway` CLI plus Railway auth when you want the packaged `use-railway` skill to operate Railway infrastructure
- `uv` plus the draw.io desktop CLI when you want the packaged `drawio-skill` to generate or export diagrams; Graphviz (`dot`) is optional for auto-layout
- Node.js when you want `frontend-slides` PDF export or Vercel deploy helpers; `uv` when converting PPTX

The installer also copies `plugins/dcg-guard.js`. That plugin stays inactive until the `dcg` CLI is on `PATH`. Install Destructive Command Guard with:

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --easy-mode
```

See the upstream project: [Dicklesworthstone/destructive_command_guard](https://github.com/dicklesworthstone/destructive_command_guard). The plugin does not need extra Node packages; Opencode loads it from `plugins/` at startup.

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- `CONTEXT7_API_KEY` for the optional `context7` MCP entry
- `uvx` and optionally the `cymbal` CLI for the context-improved workflow; `context-mode` runs as a native OpenCode plugin
- `npx` (Node.js) for the optional `chrome-devtools` browser MCP
- VS Code if you want the companion extension

Cursor prompt-level assets have a separate setup path. They are validated and installed by `./scripts/cursor-assets.sh` from the repository root, not by the Opencode profile installer. It requires `python3`, defaults to `${HOME}/.cursor`, accepts `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, and accepts semicolon-separated `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for dual installs. `CURSOR_INSTALL_IVAN_WRITING` accepts only unset/empty (opt-out) or exact `1` (opt-in); the skill is installed into the agents dir and backed up and removed on opt-out only when a helper-owned marker file exists. Shared canonical skills use `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`. See `CURSOR.md` for details.

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
./scripts/install-profile.sh
opencode
```

Fresh machine with the sanitized personal-default AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
opencode
```

Fresh machine with the context-improved AGENTS profile and overlay:

```bash
curl -fsSL https://opencode.ai/install | bash
brew install 1broseidon/tap/cymbal
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
opencode
```

Where:

- the repository clone requires GitHub access to this repo
- `opencode auth login -p openai` opens the ChatGPT OAuth flow; `opencode-gpt-imagegen` currently requires a ChatGPT Plus or Pro subscription through that OAuth path
- `brew install 1broseidon/tap/cymbal` is only needed when you want the full context-improved local navigation workflow
- the first `opencode` run should resolve `oc-arkive@latest` automatically from `opencode.json`

## Updating an existing install

To update an older install in place, update this repository clone and rerun the installer against the same Opencode config directory:

```bash
git pull
./scripts/install-profile.sh
```

Use the same profile environment variables the install should keep, for example:

```bash
git pull
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Use `OPENCODE_AGENTS_MODE=skip` when the target already has a hand-maintained `AGENTS.md` that should stay as the base document for a manual merge:

```bash
git pull
OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh
```

Some notes:

- `curl -fsSL https://opencode.ai/install | bash` updates or installs the Opencode binary; it does not update this profile
- Opencode may keep using a cached copy of `oc-arkive@latest` after these files are updated; restart Opencode after installing the profile, and if the command surface still matches an older release, remove or refresh the cached `oc-arkive` plugin entry according to the local Opencode cache layout before starting Opencode again
- after restart, verify the loaded plugin manifest or available Agent Hive commands match the expected latest `oc-arkive` release
- the installer writes timestamped backups under `<target>/.backup/` before replacing managed files
- prefer preserving an existing customized `AGENTS.md` when unsure, then merge the selected profile guidance manually

## Install options

### Target config directory

Install into the default Opencode config directory:

```bash
./scripts/install-profile.sh
```

Install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config AGENTS_SKILLS_DIR=/path/to/agents-skills ./scripts/install-profile.sh
```

Shared canonical skills default to `$HOME/.agents/skills`. Set `AGENTS_SKILLS_DIR` when the installer must not write that live directory.

### AGENTS profiles

The installer uses `profiles/agents/shared.md` by default. Select another profile with `OPENCODE_AGENTS_PROFILE`.

Available profiles:

- `shared`: portable default for shared machines and team use
- `personal-default`: shared baseline plus the author's operator-writing style, loaded from the personal `ivan-writing` skill
- `shared-context-improved`: shared baseline plus routing rules for the optional context-improved toolchain
- `personal-context-improved`: personal-default plus the same context-improved routing rules

Install examples:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

The two `*-context-improved` profiles require `jq`, `uvx`, and `CONTEXT7_API_KEY`. The installer preflights those dependencies and applies the matching `context-improved` overlay automatically.

### Agent Hive config

The installer copies `profiles/base/agent_hive.json`. It is the sole canonical Hive config and uses only ChatGPT OAuth models a normal OpenAI login can see: non-fast `openai/gpt-5.6-sol` and `openai/gpt-5.6-luna`. Fast variants, `gpt-5.6-terra`, `opencode-go/*`, and personal `xai/*` models are not part of this profile. The target Opencode environment must resolve those two OpenAI models. The installer does not add provider credentials, local proxy plugins, or provider shims to `opencode.json`.

Sol is the default for planning, orchestration, review, UI, implementation, and other high-capability seats. Luna is reserved for scout, recovery, and explicitly fast mechanical work. Current routing uses Sol `medium` for `forager-worker`, Sol `high` for `forager-capable`, Luna `xhigh` for `forager-fast`, and Luna `xhigh` for `scout-researcher-capable`. Remapped seats preserve the live variant when Sol or Luna supports it: `forager-documents` remains Sol `high`, while `forager-ui`, `adversarial-plan-reviewer`, `adversarial-documentation-reviewer`, `adversarial-code-reviewer`, `adversarial-simplicity-reviewer`, `adversarial-approach-advisor`, `ui-design-advisor`, `scout-researcher-code`, `hive-helper`, and `vulnerability-reviewer` use Sol `max`. Other native OpenAI seats retain their intentional `high`, `xhigh`, or `max` effort. That split follows current [Artificial Analysis Intelligence Index](https://artificialanalysis.ai/#intelligence) and [DeepSWE](https://deepswe.datacurve.ai/) results.

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

This repository also ships a Cursor v1 asset bundle for prompt-level behavior. Its default parent Agent uses Hive-Builder-like ad-hoc orchestration with Cursor-native named subagents: non-trivial work is delegated, while the parent owns lane coordination, diff inspection, combined verification, review, synthesis, and integration. The bundle installs reusable Cursor subagents, seven Cursor-specific commands, the shared canonical `/reflect` command, eight managed Cursor skills including `agents-md-mastery` into the selected Cursor config `skills/` directory, and twelve shared canonical skills into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, then prints default-Agent Rules that you paste into Cursor Customize -> Rules -> User Rules. The current npm `oc-arkive@latest` is 2.3.5 and includes Engineering Judgment. OpenCode receives Engineering Judgment from the installed plugin, without a second local copy in this repository's profiles or config surfaces. Cursor continues to use the provenance-pinned vendored snapshot because Cursor cannot load the plugin prompt directly.

Delegation is a strong prompt policy, but Cursor routing is heuristic and not runtime-guaranteed. The parent has a bounded direct-work exception for coordination, setup, trivial conversation, and at most one bounded read, one bounded write or patch, and one cheap focused check. Separate context does not isolate files in a shared checkout. Overlapping writers require explicit worktrees or isolated project copies; otherwise children must own disjoint paths or run serially.

Cursor v1 is not Agent Hive runtime parity. It has no Hive tools, state, task DAG, board, or worktree lifecycle, and it does not install `oc-arkive`, `opencode.json`, `agent_hive.json`, or an OpenCode `AGENTS.md` profile.

Prerequisites:

- run commands from this repository root
- `python3`
- Git and a local Agent Hive checkout containing the selected ref are required only for maintainer sync
- executable `scripts/cursor-assets.sh`
- default target `${HOME}/.cursor`, `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, or `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for multiple targets
- `railway` CLI plus Railway auth when using the packaged `use-railway` skill
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

- the published `context-mode` native OpenCode plugin alongside `oc-arkive@latest`; it registers the `ctx_*` tools in-process
- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry
- Scout navigation rules for `cymbal`, `ast-grep`, and `context-mode`

Prerequisites:

- `jq`
- `uvx` available on `PATH`
- `CONTEXT7_API_KEY` set in the environment
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

Apply a snippet with:

```bash
./scripts/enable-optional.sh chrome-devtools
```

The script validates prerequisites, backs up the current config file, and merges the chosen snippet into the active config.

`chrome-devtools` is the canonical interactive browser solution. It requires `npx` on `PATH` and launches `chrome-devtools-mcp@latest` with a non-absolute command.

Useful checks:

```bash
npx --version
jq '.mcp["chrome-devtools"]' "$OPENCODE_CONFIG_DIR/opencode.json"
```

## Base plugins

The base `opencode.json` installs:

- `oc-arkive@latest` for Agent Hive
- `opencode-gpt-imagegen` for OpenAI image generation tools

The installer also copies `plugins/dcg-guard.js`, which Opencode auto-loads from the config plugins directory. It intercepts `bash` tool calls when `dcg` is on `PATH`, and is a no-op when `dcg` is missing.

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

Reusable non-Hive behavior remains packaged as skills under `.apm/skills/`. OpenCode does not package Hive-overlapping skills; also does not package `using-git-worktrees`, `finishing-a-development-branch`, `consolidate-test-suites`, or `root-cause-finder`. Hive/`oc-arkive` owns worktrees and merge and ships `brainstorming`, `systematic-debugging`, `test-driven-development`, `verification`, and `ast-grep`. Cursor keeps `using-git-worktrees` and `finishing-a-development-branch` because it has no Hive runtime, and still installs the overlapping names except `ast-grep`. Test placement is default Engineering Judgment / Quality Gates, not a separate skill. Shared Cursor copies of `brainstorming`, `systematic-debugging`, `test-driven-development`, and `verification` are provenance-pinned from Agent Hive with a Cursor-runtime rewrite. `agents-md-mastery` remains a Cursor-specific adaptation under `.apm/cursor/skills/` so it does not shadow Agent Hive's generated OpenCode skill. The twelve shared canonical skills are `cymbal`, `drawio-skill`, `frontend-slides`, `hard-cut`, `humanizer`, `react-best-practices`, `resume-tailoring`, `stop-design-slop`, `stop-slop`, `use-railway`, `web-design-guidelines`, and `writing-for-humans`. Both installers upsert those names into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` and leave them out of harness `skills/` directories. OpenCode prefers `~/.config/opencode/skills` over `~/.agents/skills` when both exist, so a leftover shared copy in the OpenCode skills directory would keep serving the stale tree; `scripts/install-profile.sh` removes leftover copies of those shared names, leftover Hive-owned skill names, and leftover retired OpenCode-local skill names from OpenCode `skills/` on install. Other existing skill directories stay. Personal OpenCode profiles also remove a leftover `skills/ivan-writing` after copying that skill into the agents dir. Cursor and OpenCode also scan `~/.claude/skills`, so shared skills must not be left there either. The `use-railway` skill needs the Railway CLI and auth, and is otherwise inert. `drawio-skill` needs `uv` plus draw.io, and `frontend-slides` needs Node.js/`uv` for export helpers; both are otherwise inert. The optional personal `ivan-writing` skill is installed into the agents dir for personal OpenCode profiles, and for Cursor only when `CURSOR_INSTALL_IVAN_WRITING=1`.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository. That document covers both the Opencode profile setup and the separate Cursor prompt-level asset setup.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
