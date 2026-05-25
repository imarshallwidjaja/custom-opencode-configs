# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@latest` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

`./scripts/install-profile.sh` installs these files into your Opencode config directory:

- `opencode.json`: base Opencode config with `oc-arkive@latest`
- `agent_hive.json`: Agent Hive role and model configuration
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`, `agents/`, and `commands/`: shared markdown assets used by Opencode

If the target config directory already contains files with those names, the installer writes a timestamped backup under `<target>/.backup/` before replacing them.

## Requirements

Base setup requires:

- `git`
- `curl`
- `opencode`
- OpenAI access for the `openai/*` models used by the default `agent_hive.json`
- `opencode-go/*` provider access for the base `opencode.json` agent overrides and default Agent Hive scout/helper roles

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- `CONTEXT7_API_KEY` for the optional `context7` MCP entry
- `context-mode`, `uvx`, and optionally `cymbal` for the context-improved workflow
- LSP binaries if you enable an LSP bundle
- VS Code if you want the companion extension

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

- `default`: installs the repository root `agent_hive.json`, matching the OpenAI plus `opencode-go` model selection
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

This profile installs prompt-backed slash commands into `commands/`.

Command index:

- `/council-directive`: shape a council session before running it
- `/council`: run a read-only council and get one synthesized recommendation
- `/interview`: clarify an under-defined problem before planning or council review

Before using them:

1. Run `./scripts/install-profile.sh`.
2. Start `opencode` once so it resolves `oc-arkive@latest`.
3. Open a chat session in Opencode.

Use `/council` directly when the question is already clear:

```text
/council Should we add a council command without plugin overhead?
```

Use `/council-directive` first when the council needs tighter framing:

```text
/council-directive We need a design review on how to expose a council workflow as prompt-backed commands.
```

Use `/interview` before council when the problem itself is still under-defined.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
