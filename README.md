# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@latest` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

`./scripts/install-profile.sh` installs these files into your Opencode config directory:

- `opencode.json`: base Opencode config with `oc-arkive@latest`
- `agent_hive.json`: Agent Hive role and model configuration
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`: shared markdown skills used by Opencode
- `commands/`: non-Hive prompt-backed commands packaged under `.apm/prompts/` (`interview-drill-down`, `planning-prompt`)
- `agents/`: installed only when this repository packages standalone Opencode agents

If the target config directory already contains files with those names, the installer writes a timestamped backup under `<target>/.backup/` before replacing them. Set `OPENCODE_AGENTS_MODE=skip` when you want to update the profile files but keep an existing `AGENTS.md` in place for a manual merge.

## Requirements

Base setup requires:

- `git`
- `curl`
- `opencode`
- OpenAI access for the non-fast `openai/gpt-5.6-sol` model used by the default `agent_hive.json`
- OpenAI access for the base `opencode.json` `agent.compaction` override (`openai/gpt-5.5`, `variant: low`)
- `opencode-go/*` provider access for the base `opencode.json` `explore` override and selected Agent Hive Scout, simple-worker, UI, and capable-research roles
- OpenAI auth also covers the base `opencode-gpt-imagegen` plugin when you want image generation tools
- `railway` CLI plus Railway auth when you want the packaged `use-railway` skill to operate Railway infrastructure

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- `CONTEXT7_API_KEY` for the optional `context7` MCP entry
- `context-mode`, `uvx`, and optionally `cymbal` for the context-improved workflow
- `npx` (Node.js) for the optional `chrome-devtools` browser MCP
- VS Code if you want the companion extension

Cursor prompt-level assets have a separate setup path. They are validated and installed by `./scripts/cursor-assets.sh` from the repository root, not by the Opencode profile installer. That helper requires `python3`, defaults to `${HOME}/.cursor`, accepts `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, and accepts semicolon-separated `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for dual installs.

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
OPENCODE_CONFIG_DIR=/path/to/opencode-config ./scripts/install-profile.sh
```

### AGENTS profiles

The installer uses `profiles/agents/shared.md` by default. Select another profile with `OPENCODE_AGENTS_PROFILE`.

Available profiles:

- `shared`: portable default for shared machines and team use
- `personal-default`: shared baseline plus the author's operator-writing style
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

The two `*-context-improved` profiles require `jq`, `context-mode`, `uvx`, and `CONTEXT7_API_KEY`. The installer preflights those dependencies and applies the matching `context-improved` overlay automatically.

### Agent Hive config

The installer copies the repository root `agent_hive.json`. It is the sole canonical Hive config and uses OpenAI `gpt-5.6-sol` plus selected `opencode-go` roles. The target Opencode environment must resolve every provider and model it names. The installer does not add provider credentials, local proxy plugins, or provider shims to `opencode.json`. OpenAI roles always use non-fast `openai/gpt-5.6-sol`.

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

This repository also ships a Cursor v1 asset bundle for prompt-level behavior. It installs reusable Cursor subagents, commands, and skills under the selected Cursor config directory, then prints default-Agent Rules that you paste into Cursor Settings -> Rules.

Cursor v1 is not Agent Hive runtime parity. It does not install `oc-arkive`, Hive tools, `opencode.json`, `agent_hive.json`, or an Opencode `AGENTS.md` profile.

Prerequisites:

- run commands from this repository root
- `python3`
- executable `scripts/cursor-assets.sh`
- default target `${HOME}/.cursor`, `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, or `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for multiple targets
- `railway` CLI plus Railway auth when using the packaged `use-railway` skill

Quick inspection flow:

```bash
./scripts/cursor-assets.sh validate
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install --dry-run
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

After install, paste the printed Rules text into Cursor Settings -> Rules.

See `CURSOR.md` for the asset list, exclusions, verification steps, and the reason this repo uses a thin helper instead of claiming direct APM global Cursor deployment.

## Optional context-improved workflow

The context-improved workflow adds the local context and structural-search toolchain.

It enables:

- the published `context-mode` plugin alongside `oc-arkive@latest`
- a local `context-mode` MCP launched from `PATH`
- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry
- Scout navigation rules for `cymbal`, `ast-grep`, and `context-mode`

Prerequisites:

- `jq`
- `context-mode` available on `PATH`
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

`opencode-gpt-imagegen` currently uses ChatGPT Plus or Pro OAuth from Opencode. It does not provide an API-key image path. No credentials are embedded in this repository.

## Prompt-backed commands

This profile ships two non-Hive prompt-backed commands from `.apm/prompts/`:

- `interview-drill-down`
- `planning-prompt`

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

Reusable non-Hive behavior also remains packaged as skills under `.apm/skills/`. Skills that overlap with `oc-arkive` are kept here only when this profile intentionally forks them (`brainstorming`, `systematic-debugging`, `test-driven-development`). Near-duplicate plugin skills such as `ast-grep` are not packaged here. The `use-railway` skill is included by explicit request; it needs the Railway CLI and auth, and is otherwise inert.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository. That document covers both the Opencode profile setup and the separate Cursor prompt-level asset setup.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
