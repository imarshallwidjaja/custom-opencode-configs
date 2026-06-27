# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@latest` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

`./scripts/install-profile.sh` installs these files into your Opencode config directory:

- `opencode.json`: base Opencode config with `oc-arkive@latest`
- `agent_hive.json`: Agent Hive role and model configuration
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`: shared markdown skills used by Opencode; `commands/` and `agents/` are installed only when this repository packages standalone assets for them

If the target config directory already contains files with those names, the installer writes a timestamped backup under `<target>/.backup/` before replacing them. Set `OPENCODE_AGENTS_MODE=skip` when you want to update the profile files but keep an existing `AGENTS.md` in place for a manual merge.

## Requirements

Base setup requires:

- `git`
- `curl`
- `opencode`
- OpenAI access for the `openai/*` fast models used by the default `agent_hive.json`
- `opencode-go/*` provider access for the base `opencode.json` `explore` override and selected Agent Hive Scout, simple-worker, UI, and capable-research roles

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- `CONTEXT7_API_KEY` for the optional `context7` MCP entry
- `context-mode`, `uvx`, and optionally `cymbal` for the context-improved workflow
- LSP binaries if you enable an LSP bundle
- VS Code if you want the companion extension

Cursor prompt-level assets have a separate setup path. They are validated and installed by `./scripts/cursor-assets.sh`, not by the Opencode profile installer.

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
opencode auth login -p github-copilot
./scripts/install-profile.sh
opencode
```

Fresh machine with the sanitized personal-default AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p github-copilot
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
opencode
```

Fresh machine with the context-improved AGENTS profile and overlay:

```bash
curl -fsSL https://opencode.ai/install | bash
brew install 1broseidon/tap/cymbal
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p github-copilot
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
opencode
```

Where:

- the repository clone requires GitHub access to this repo
- `opencode auth login -p github-copilot` requires a GitHub account with Copilot access
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
OPENCODE_AGENTS_PROFILE=personal-default OPENCODE_AGENT_HIVE_PROFILE=copilot-opencode-go ./scripts/install-profile.sh
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

### Agent Hive model profiles

The installer uses the repository root `agent_hive.json` by default. Alternate full Agent Hive profiles live under `profiles/agent-hive/` and can be selected with `OPENCODE_AGENT_HIVE_PROFILE`.

Available Agent Hive profiles:

- `default`: installs the repository root `agent_hive.json`, matching the OpenAI fast plus `opencode-go` model selection
- `openai-opencode-go`: installs the named copy at `profiles/agent-hive/openai-opencode-go.json`
- `copilot-opencode-go`: installs `profiles/agent-hive/copilot-opencode-go.json`

Install with the OpenAI plus `opencode-go` profile:

```bash
OPENCODE_AGENT_HIVE_PROFILE=openai-opencode-go ./scripts/install-profile.sh
```

Install with the Copilot plus `opencode-go` profile:

```bash
OPENCODE_AGENT_HIVE_PROFILE=copilot-opencode-go ./scripts/install-profile.sh
```

Use alternate model profiles only when the target Opencode environment can resolve every provider and model named in the selected profile. These profiles change only `agent_hive.json`; they do not add provider credentials, local proxy plugins, or provider shims to `opencode.json`.

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

This repository also ships a Cursor v1 asset bundle for prompt-level behavior. It installs reusable Cursor subagents, commands, and skills under global `~/.cursor`, then prints default-Agent Rules that you paste into Cursor Settings -> Rules.

Cursor v1 is not Agent Hive runtime parity. It does not install `oc-arkive`, Hive tools, `opencode.json`, `agent_hive.json`, or an Opencode `AGENTS.md` profile.

The helper selects `.apm/cursor` by default. If APM validation later requires the fallback, it also supports a top-level `cursor-assets/` root.

Quick inspection flow:

```bash
./scripts/cursor-assets.sh validate
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install --dry-run
./scripts/cursor-assets.sh print-rules
```

Actual global install:

```bash
./scripts/cursor-assets.sh install
```

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

## Optional MCP and LSP bundles

Optional merge snippets live under `profiles/optional/`:

- `opencode.context-improved.json`
- `opencode.mcp-context7-enabled.json`
- `opencode.lsp-all-recommended.json`
- `opencode.lsp-markdown-typescript.json`
- `opencode.lsp-python.json`

Apply a snippet with:

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

The script validates prerequisites, backs up the current config file, and merges the chosen snippet into the active config.

For the full recommended LSP stack, install the binaries first:

- `vtsls`: install Node.js LTS, then run `npm install -g @vtsls/language-server`
- `ruff`: install `uv`, then run `uv tool install ruff@latest`
- `ty`: install `uv`, then run `uv tool install ty@latest`
- `marksman`: install it from the official package manager or release-binary instructions at <https://github.com/artempyanykh/marksman/blob/main/docs/install.md>

Then apply the bundle:

```bash
./scripts/install-profile.sh
./scripts/enable-optional.sh lsp-all-recommended
```

Useful checks:

```bash
marksman --help
vtsls --stdio
ruff server --help
ty server --help
```

## Prompt-backed commands

This profile currently does not ship prompt-backed commands under `.apm/prompts/`.

The old Hive-related prompt commands were removed from this profile after they were absorbed into `oc-arkive`'s built-in command surface. Use the plugin commands from Agent Hive instead, including `/interview`, `/implementation-brief`, `/hive-plan`, `/approve-sync-plan`, `/start-execution`, `/council-directive`, `/council`, and `/compact-summary`.

During install, `scripts/install-profile.sh` removes the legacy managed command files from the target `commands/` directory after backing that directory up. It removes only the old profile-managed names:

- `approve-sync-plan`
- `compact-summary`
- `council-directive`
- `council`
- `hive-plan`
- `implementation-planning-prompt`
- `interview-drill-down`
- `interview`
- `planning-prompt`
- `start-execution`

Reusable non-Hive behavior remains packaged as skills under `.apm/skills/`. If this repository later adds non-Hive prompt-backed commands that are not better expressed through Agent Hive config or `oc-arkive`, the installer will copy `.apm/prompts/*.prompt.md` into `commands/`.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository. That document covers both the Opencode profile setup and the separate Cursor prompt-level asset setup.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
