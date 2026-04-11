# custom-opencode-configs

This repository versions a portable Opencode profile and packages the shared markdown assets through Microsoft's APM.

## What is here

- `opencode.json`: the base Opencode config. It uses the published `opencode-hive` plugin instead of a local checkout.
- `agent_hive.json`: the starting `agent-hive` layout, kept on remote-only GitHub Copilot models.
- `AGENTS.md`: the shared global instruction file for this profile.
- `.apm/`: portable `skills`, `agents`, and prompt-backed commands that APM can install into an Opencode config directory.

## Why the layout is split

APM's OpenCode target installs markdown primitives such as `skills`, `agents`, and `commands`. It does not copy arbitrary files like `opencode.json` or `agent_hive.json`.

Because of that, this repo keeps the JSON profile files at the root and installs the markdown assets through `.apm/`.

## Included vs excluded

Included:

- Shared skills migrated from `~/.claude/skills`
- Shared skills already living in `~/.config/opencode/skill`
- Shared commands from `~/.config/opencode/commands`
- The `simplicity-reviewer` agent definition

Excluded from the base profile:

- Local provider proxy definitions
- Embedded API keys and account files
- Absolute filesystem paths
- Personal or domain-specific skills such as `resume-tailoring` and `poraki-phase2-forecast-operator`

## Dependency model

This profile is intentionally split into two layers.

Base layer:

- works with remote-only models
- avoids local proxy assumptions
- avoids MCP and LSP entries that would fail on a fresh machine

Optional layer:

- adds MCP or LSP snippets only when their runtime dependencies are present
- documents the required executables, environment variables, and verification commands
- keeps activation explicit so a human or agent can decide what to enable on a given machine

To make it simple: the base profile should be safe to install anywhere, and local tooling should be added only after its prerequisites are present.

## Install

Prerequisites:

- `opencode`
- `apm`
- GitHub Copilot access for the `github-copilot/*` models used by `agent_hive.json`

Optional:

- `CONTEXT7_API_KEY` if you want to enable the bundled `context7` remote MCP entry in `opencode.json`

Install into the default global config directory:

```bash
git clone <your-repo-url> custom-opencode-configs
cd custom-opencode-configs
./scripts/install-profile.sh
```

Install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config ./scripts/install-profile.sh
```

The installer does two things:

1. Copies `opencode.json`, `agent_hive.json`, and `AGENTS.md` into the target Opencode config directory.
2. Copies the packaged `.apm/skills`, `.apm/agents`, and `.apm/prompts` payload into the same config tree.

The direct copy is intentional. APM does not install arbitrary JSON files, and `apm install -g` does not accept a local package path. That means a cloned checkout needs a small installer layer even though the repo itself is still a valid APM package.

Once the repo is published and tagged, you can also install the markdown primitives through APM directly:

```bash
apm install -g owner/custom-opencode-configs#v0.1.0
```

That APM path installs the packaged `skills`, `agents`, and command prompts. You still need to copy `opencode.json`, `agent_hive.json`, and `AGENTS.md` into your Opencode config directory.

## Extending the profile

The current baseline is intentionally conservative. It gives you a working remote `agent-hive` setup without assuming local proxies or a multi-provider model matrix.

To extend it later:

1. Add provider definitions to `opencode.json`.
2. Point `agent_hive.json` roles at those provider/model pairs.
3. Document any required environment variables or binaries in this README.

## Optional MCP and LSP bundles

Optional merge snippets live under `profiles/optional/`.

- `profiles/optional/opencode.mcp-context7-enabled.json`
- `profiles/optional/opencode.lsp-markdown-typescript.json`
- `profiles/optional/opencode.lsp-python.json`

These files are partial JSON snippets intended to be merged into `opencode.json`. They are not standalone configs.

The operator guide for those bundles lives at `profiles/optional/README.md`. It documents:

- what each bundle enables
- which binaries or environment variables must exist first
- how to verify the dependencies are available
- when the bundle is suitable for a portable profile

## Notes on skill migration

The previous setup mixed `~/.claude/skills` and `~/.config/opencode/skill`. This repo normalizes the shared parts into one APM-installable Opencode package under `.apm/skills`.

Some skill text still refers to Hive-specific skills such as `writing-plans` or `verification-before-completion`. Those are provided by `opencode-hive`, not by this repo.
