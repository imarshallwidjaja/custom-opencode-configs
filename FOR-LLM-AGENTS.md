# For LLM Agents

This document tells an Opencode agent how to set up this repository for a less technical operator.

Use it when the operator says things like:

- "Set this repo up as my Opencode config."
- "Install this custom Opencode profile for me."
- "Read this repo and walk me through the setup."

## Operator Prompt

Give the agent this repository and this document, then say:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

## What This Repo Actually Supports

Do not invent extra setup questions. This repository exposes the following real choices:

1. Which installable `AGENTS.md` profile to use:
   - `shared`
   - `personal-default`
2. Which Opencode config directory to install into:
   - default `~/.config/opencode`
   - a custom `OPENCODE_CONFIG_DIR`
3. Whether to enable the optional `context7` MCP snippet.
4. Whether to enable one optional LSP snippet:
   - none
   - `lsp-markdown-typescript`
   - `lsp-python`
   - `lsp-all-recommended`
5. Whether to install the optional VS Code `tctinh.vscode-hive` extension.

Some setup facts are not user choices:

- The default full install path is `./scripts/install-profile.sh`.
- The repo uses remote GitHub Copilot models in `opencode.json` and `agent_hive.json`.
- The published `opencode-hive@latest` plugin is installed by Opencode on first run.
- `context7` is present in the base config but disabled by default.
- No LSP snippet is enabled by default.
- Direct `apm install -g ...` is not the right default for first-time setup because it does not install `opencode.json`, `agent_hive.json`, or `AGENTS.md`.

To make it simple: use the repo scripts for the normal setup path, then offer the optional bundles only after the base profile is installed.

## Files To Read First

Before making changes, read these files from this repository:

- `README.md`
- `profiles/agents/README.md`
- `profiles/optional/README.md`
- `scripts/install-profile.sh`
- `scripts/enable-optional.sh`

## Interview Rules

- Ask one setup question at a time.
- Explain each option in plain language.
- Recommend the safest default when the operator is unsure.
- Do not push optional tooling unless the operator wants it and the machine can support it.
- Use the repository scripts instead of manually copying files.
- If a prerequisite is missing, ask whether the operator wants you to install it or skip the related optional feature.
- Keep the operator informed about what you are about to run.

## Recommended Defaults

Use these defaults unless the operator asks for something else:

- Install into `~/.config/opencode`.
- Use the `shared` AGENTS profile.
- Skip optional MCP and LSP snippets unless there is a clear need.
- Install the VS Code Hive extension only if the operator uses VS Code.

## Interview And Setup Workflow

Follow this order.

### 1. Confirm the target location

Ask:

```text
Do you want this installed into the normal Opencode config directory at ~/.config/opencode, or do you want a custom config directory?
```

Recommendation:

- Recommend `~/.config/opencode` unless the operator already uses a custom config layout.

If they choose a custom location, use `OPENCODE_CONFIG_DIR=/path/to/dir` for both install scripts.

### 2. Check the required base prerequisites

Verify or install the local tools:

- `git`
- `curl`
- `opencode`

Also verify that the operator has GitHub Copilot access available on their GitHub account before running `opencode auth login -p github-copilot`.

If `opencode` is missing, the standard install command is:

```bash
curl -fsSL https://opencode.ai/install | bash
```

If the repository is not already cloned, clone it before continuing.

### 3. Authenticate Opencode

Ask:

```text
Have you already signed Opencode into GitHub Copilot on this machine, or should I do that now?
```

If needed, run:

```bash
opencode auth login -p github-copilot
```

### 4. Choose the AGENTS profile

Ask:

```text
Do you want the neutral shared profile, or the personal-default profile that also makes the agent write in this repository author's preferred style?
```

Explain the options like this:

- `shared`: the safest team-friendly default
- `personal-default`: the shared rules plus the author's writing voice and phrase patterns

Recommendation:

- Recommend `shared` unless the operator explicitly wants the author's style.

### 5. Install the base profile

Explain this before running the installer: it replaces the target directory's `opencode.json`, `agent_hive.json`, `AGENTS.md`, `skills/`, `agents/`, and `commands/` contents with this repo's versions, and it writes timestamped backups under `<target>/.backup/` first when those paths already exist.

Run one of these:

```bash
./scripts/install-profile.sh
```

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

If a custom config directory was chosen, include `OPENCODE_CONFIG_DIR=/path/to/dir` as well.

Do not use the APM-only install path for first-time setup unless the operator explicitly asks for it.

### 6. Offer the optional `context7` MCP

Ask:

```text
Do you want me to enable the optional context7 documentation MCP? It needs a CONTEXT7_API_KEY environment variable.
```

Only enable it if:

- the operator wants it
- `CONTEXT7_API_KEY` is set
- the machine can reach `https://mcp.context7.com/mcp`

If all conditions are met, run:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Some notes:

- `scripts/enable-optional.sh` requires `jq`.
- `agent_hive.json` still disables `context7` for Hive workers by default. That is part of this profile.

### 7. Offer the optional LSP bundles

Ask this first:

```text
Do you want optional local language servers enabled for this machine, or would you prefer to keep the setup minimal for now?
```

If they want LSPs, ask:

```text
Which best matches your work on this machine: Markdown and TypeScript, Python, all of them, or none?
```

Map their answer to the bundle:

- Markdown and TypeScript: `lsp-markdown-typescript`
- Python: `lsp-python`
- Both or full recommended stack: `lsp-all-recommended`

Before applying a bundle:

- check that `jq` is installed
- check that the required binaries are on `PATH`

Bundle prerequisites:

- `lsp-markdown-typescript`: `marksman`, `vtsls`
- `lsp-python`: `ruff`, `ty`
- `lsp-all-recommended`: `marksman`, `vtsls`, `ruff`, `ty`

Recommended install guidance when binaries are missing:

- `vtsls`: install Node.js LTS, then run `npm install -g @vtsls/language-server`
- `ruff`: install `uv`, then run `uv tool install ruff@latest`
- `ty`: install `uv`, then run `uv tool install ty@latest`
- `marksman`: install it using the official instructions at `https://github.com/artempyanykh/marksman/blob/main/docs/install.md`

Apply the chosen bundle with:

```bash
./scripts/enable-optional.sh <snippet-name>
```

Do not apply an LSP snippet before the base profile exists in the target directory.

### 8. Offer the optional VS Code extension

Ask:

```text
Do you use VS Code on this machine, and if so, do you want the optional Agent Hive extension installed there too?
```

If yes and the `code` CLI is available, run:

```bash
code --install-extension tctinh.vscode-hive
```

If the `code` CLI is not available, tell the operator to install `Agent Hive` from the VS Code marketplace manually.

### 9. Start Opencode once

Run:

```bash
opencode
```

This allows Opencode to resolve `opencode-hive@latest` from `opencode.json` on first run.

Success signal:

- Opencode starts without reporting plugin-resolution or command-not-found errors for the base profile.

### 10. Verify the final state

Verify that the target config directory now contains:

- `opencode.json`
- `agent_hive.json`
- `AGENTS.md`
- `skills/`
- `agents/`
- `commands/`

If optional snippets were enabled, verify that the relevant entries exist in `opencode.json`.

Concrete checks:

- if `context7` was enabled, verify `mcp.context7.enabled` is `true`
- if an LSP bundle was enabled, verify the expected `lsp.<name>.command` entries exist for the selected servers
- if `lsp-markdown-typescript` was enabled, verify `lsp.typescript.disabled` is `true`
- if `lsp-python` or `lsp-all-recommended` was enabled, verify `lsp.pyright.disabled` and `lsp.basedpyright.disabled` are `true`

Then report back with:

- the install directory used
- the AGENTS profile selected
- whether `context7` was enabled
- which LSP bundle, if any, was enabled
- whether the VS Code extension was installed
- any skipped options and why

## Decision Inventory From The Repo Audit

Use this as the source of truth for the interview.

| Decision | Choices | Default | Requirements |
|---|---|---|---|
| AGENTS profile | `shared`, `personal-default` | `shared` | none |
| Config directory | `~/.config/opencode` or custom path | `~/.config/opencode` | none |
| `context7` MCP | enable or skip | skip | `jq`, `CONTEXT7_API_KEY`, network access |
| LSP bundle | none, `lsp-markdown-typescript`, `lsp-python`, `lsp-all-recommended` | none | `jq` plus required binaries |
| VS Code Hive extension | install or skip | skip unless operator uses VS Code | VS Code and usually `code` CLI |

## Commands The Agent Will Usually Need

Base install:

```bash
./scripts/install-profile.sh
```

Base install with the personal profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Base install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config ./scripts/install-profile.sh
```

Enable `context7`:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Enable Markdown and TypeScript LSPs:

```bash
./scripts/enable-optional.sh lsp-markdown-typescript
```

Enable Python LSPs:

```bash
./scripts/enable-optional.sh lsp-python
```

Enable all recommended LSPs:

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

Install the VS Code Hive extension:

```bash
code --install-extension tctinh.vscode-hive
```

## What Not To Do

- Do not ask the operator to choose model IDs from this repo. Those defaults are already encoded.
- Do not default to direct `apm install -g` for first-time setup.
- Do not enable optional snippets without first checking their prerequisites.
- Do not enable LSP snippets before `./scripts/install-profile.sh` has created the target `opencode.json`.
- Do not assume `personal-default` is appropriate for every operator.
- Do not overwhelm the operator with all questions at once.
