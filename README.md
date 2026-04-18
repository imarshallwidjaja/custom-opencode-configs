# custom-opencode-configs

This repository versions a portable Opencode profile and packages the shared markdown assets through Microsoft's APM.

## What is here

- `opencode.json`: the base Opencode config. It uses the published `opencode-hive@latest` plugin instead of a local checkout.
- `agent_hive.json`: the starting `agent-hive` layout, kept on remote-only GitHub Copilot models.
- `AGENTS.md`: repository instructions for maintaining this repo.
- `profiles/agents/`: installable `AGENTS.md` profiles for Opencode.
- `profiles/optional/`: optional MCP, LSP, and workflow merge snippets.
- `.apm/`: portable `skills`, `agents`, and prompt-backed commands that APM can install into an Opencode config directory.

## Command index

- [`/council-directive`](#prompt-backed-commands): shape a council session before running it
- [`/council`](#prompt-backed-commands): run a read-only council and get one synthesized recommendation
- [`/interview`](#prompt-backed-commands): clarify an under-defined problem before planning or council review

## Why the layout is split

APM's OpenCode target installs markdown primitives such as `skills`, `agents`, and `commands`. It does not copy arbitrary files like `opencode.json` or `agent_hive.json`.

Because of that, this repo keeps the JSON profile files at the root and installs the markdown assets through `.apm/`.

## Included vs excluded

Included:

- Shared skills migrated from the previous Claude Code skill directory
- Shared skills already living in `~/.config/opencode/skill`
- Shared commands from `~/.config/opencode/commands`
- The `simplicity-reviewer` agent definition
- Portable AGENTS guidance for validation language, subagent workflow, and tool routing

Excluded from the base profile:

- Local provider proxy definitions
- Embedded API keys and account files
- Absolute filesystem paths
- Machine-specific local MCP and plugin paths
- Bundled personal or domain-specific skills such as `resume-tailoring` and `poraki-phase2-forecast-operator`

Some notes:

- the installable `AGENTS.md` profiles can still instruct agents to use optional external skills such as `resume-tailoring` when those skills are available in the running environment
- those references do not mean this repository packages those skills in `.apm/`

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

- `git`
- `curl`
- `opencode`
- `jq` if you want to use `scripts/enable-optional.sh`
- GitHub Copilot access for the `github-copilot/*` models used by `agent_hive.json`

Optional:

- `CONTEXT7_API_KEY` if you want to enable the bundled `context7` remote MCP entry in `opencode.json`
- `context-mode` on `PATH`, `uvx` on `PATH`, and optionally the `cymbal` CLI on `PATH` if you want the `context-improved` overlay and the full local navigation workflow

## For LLM agents

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository.

Short copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document:

- inventories the real setup decisions this repo exposes
- tells the agent which files to read first
- gives the interview order for choosing an `AGENTS.md` profile and optional context-improved, MCP, or LSP bundles
- treats `AGENTS.md` reconciliation as an additive-first agent workflow built around `OPENCODE_AGENTS_MODE=skip`, not as a normal installer path
- treats AGENTS profile selection as operating-policy selection too, not only a toolchain choice
- tells the agent which commands to run and what to verify at the end

### Copy-paste quick start

For a fresh machine with the shared AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p github-copilot
./scripts/install-profile.sh
opencode
```

For a fresh machine with the sanitized personal-default AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p github-copilot
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
opencode
```

For a machine where you want the context-improved overlay and matching AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p github-copilot
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
opencode
```

Where:

- the repository clone requires GitHub access to the private repo
- `opencode auth login -p github-copilot` requires a GitHub account with Copilot access
- the first `opencode` run should fetch `opencode-hive@latest` automatically from the plugin config

### Fresh machine setup

1. Install OpenCode:

```bash
curl -fsSL https://opencode.ai/install | bash
```

2. Clone this repository:

```bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
```

3. Authenticate OpenCode to GitHub Copilot:

```bash
opencode auth login -p github-copilot
```

4. Install the base profile:

```bash
./scripts/install-profile.sh
```

To install the sanitized personal-default AGENTS profile instead:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

To install the shared context-improved AGENTS profile instead:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

To install the personal context-improved AGENTS profile instead:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

Those two context-improved profile installs also require `jq`, `context-mode`, and `uvx` on `PATH`. The installer preflights those dependencies and auto-applies the matching `context-improved` overlay when they are present.

5. Optional but recommended with OpenCode: install the Agent Hive VS Code extension for plan review, sidebar status, and comments:

```bash
code --install-extension tctinh.vscode-hive
```

If the `code` CLI is not available, install `Agent Hive` from the VS Code marketplace manually.

6. Start OpenCode once and let it resolve the plugin from `opencode.json`:

```bash
opencode
```

7. If you want optional MCP or LSP bundles, install their prerequisites first and then apply the relevant snippet with `scripts/enable-optional.sh`.

### Optional context-improved bundle

The repository now includes `profiles/optional/opencode.context-improved.json` plus a matching `profiles/optional/agent_hive.context-improved.json` overlay for the local context and structural-search toolchain.

Purpose:

- keep the base profile portable and remote-first
- let an operator opt into `context-mode`, local `ast_grep`, and enabled `context7` in one additive snippet merge
- keep the base Agent Hive profile portable while disabling `ast_grep` for Hive workers only when the context-improved bundle is enabled
- normalize local absolute paths into portable `PATH`-based commands and environment variables

Prerequisites:

- `context-mode` available on `PATH`
- `uvx` available on `PATH`
- `CONTEXT7_API_KEY` set in the environment

Enable it with:

```bash
./scripts/enable-optional.sh context-improved
```

Use that command when you want to add the bundle after a plain `shared` or `personal-default` install. If you install `shared-context-improved` or `personal-context-improved`, `scripts/install-profile.sh` applies this bundle automatically after preflighting the same prerequisites.

Some notes:

- the context-improved overlay replaces the live machine's absolute local plugin and MCP paths with portable command names
- `./scripts/enable-optional.sh context-improved` updates both `opencode.json` and `agent_hive.json`
- `scripts/install-profile.sh` auto-applies the same overlay when `OPENCODE_AGENTS_PROFILE` is `shared-context-improved` or `personal-context-improved`
- the Agent Hive sidecar keeps the base profile on `disableMcps: ["context7"]` and adds `ast_grep` only for the context-improved bundle
- `cymbal` is a separate CLI tool, not an `opencode.json` entry; the packaged AGENTS profiles instruct agents to use it when the running Opencode environment exposes it
- if you only want the remote docs MCP, the narrower `mcp-context7-enabled` snippet still exists
- pair this overlay with `shared-context-improved` or `personal-context-improved` so the installed `AGENTS.md` matches the enabled toolchain; selecting one of those profiles during install now handles the pairing automatically

## AGENTS profiles

The installer does not use the repository root `AGENTS.md` as the global Opencode profile. It installs one of the profiles from `profiles/agents/`.

All four installable profiles share the same baseline quality and delegation rules. That includes the expected-versus-validated parity wording, the new-session retry rule for failed subagents, the requirement that subagents always return a final response before finishing, and the document-writing guidance that points resume work at `resume-tailoring` when that skill is available.

Available profiles:

- `shared`: the portable default
- `personal-default`: the shared baseline plus a sanitized version of the author's preferred operating and writing voice
- `shared-context-improved`: the shared baseline plus strong routing rules for the optional context-improved toolchain
- `personal-context-improved`: the personal-default profile plus the same context-improved routing rules

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

1. Copies `opencode.json`, `agent_hive.json`, and the selected `AGENTS.md` profile into the target Opencode config directory.
2. Copies the packaged `.apm/skills`, `.apm/agents`, and `.apm/prompts` payload into the same config tree.

If the target directory already contains config, the installer creates a timestamped backup under `<target config dir>/.backup/` before replacing the files in that target directory.

After install, the target directory should contain:

- `opencode.json`
- `agent_hive.json`
- `AGENTS.md`
- `skills/`
- `agents/`
- `commands/`

The direct copy is intentional. APM does not install arbitrary JSON files, and `apm install -g` does not accept a local package path. That means a cloned checkout needs a small installer layer even though the repo itself is still a valid APM package.

The installed `opencode.json` follows the upstream Agent Hive OpenCode setup and uses:

```json
{
  "plugin": ["opencode-hive@latest"]
}
```

OpenCode handles the plugin install from there. No manual npm install is needed for the normal user path.

Once the repo is published and tagged, you can also install the markdown primitives through APM directly:

```bash
apm install -g owner/custom-opencode-configs#v0.1.0
```

That APM path installs the packaged `skills`, `agents`, and command prompts. You still need to copy `opencode.json`, `agent_hive.json`, and `AGENTS.md` into your Opencode config directory.

## Prompt-backed commands

This profile installs prompt-backed slash commands into `commands/`.

For the council workflow, the relevant commands are:

- `/council-directive`: turn a rough request into a reusable council directive
- `/council`: run a read-only council of subagents and synthesize one recommendation
- `/interview`: optional discovery flow when the problem itself is still fuzzy

Prerequisites:

- run `./scripts/install-profile.sh`
- start `opencode` once so it resolves `opencode-hive@latest`
- open a chat session in OpenCode

No setup command is required before `/council`. Use `/council-directive` when the question is still loose, when you want a paste-ready brief for a new chat, or when you want to control the council shape explicitly.

### Council workflow

Use `/council` directly when the question is already clear.

Example:

```text
/council Should we add a council command without plugin overhead?
```

Use `/council-directive` first when you need to shape the session.

Example:

```text
/council-directive We need a design review on how to expose a council workflow as prompt-backed commands.
```

That command will collect the minimum useful details, then return:

- a `Council Directive` block
- a recommendation for running `/council` in the current chat or a new chat
- a compact `/council` invocation
- a paste-ready new-chat prompt when a fresh session is the better fit

Once the directive is ready, run `/council` with either the original problem or the directive.

Example:

```text
/council
objective: design a lightweight council workflow for OpenCode
direction: preserve strong review quality without plugin runtime overhead
include: design
constraints: prompt-backed commands only, read-only council members, portable base profile
desired output: recommended command design, risks, and operator workflow
```

### Council options

`/council` accepts either a plain English prompt or a structured directive.

The main directive fields are:

- `objective`: the question the council must answer
- `direction`: the lens or stance to take
- `include`: a council alias or an explicit list of councillors
- `constraints`: boundaries, non-goals, and compatibility requirements
- `context`: relevant repo, product, or session context
- `assumptions needing validation`: what still needs checking
- `desired output`: what the operator wants back

Available council aliases:

- `design`: `scout-researcher`, `architect-planner`, `hygienic-reviewer`, `forager-smart`
- `decision`: `scout-researcher`, `architect-planner`, `hygienic-reviewer-ultrabrain`, `forager-smart`
- `minimal-change`: `scout-researcher`, `simplicity-reviewer`, `hygienic-reviewer`, `forager-simple`
- `documents`: `scout-researcher`, `forager-documents`, `hygienic-reviewer-documents`

You can also name councillors directly.

Example:

```text
/council
objective: assess whether this refactor should be split further
direction: bias toward the smallest safe change
include: scout-researcher, simplicity-reviewer, hygienic-reviewer, forager-simple
desired output: go/no-go recommendation plus main risks
```

If you mention a `worker` seat without naming one, the command defaults to:

- `forager-simple` for clearly minimal-change work
- otherwise `forager-smart`

### Read-only behavior

The council commands are designed for analysis, not execution.

Each councillor is instructed to:

- use read, search, and research tools when needed
- avoid all file changes
- avoid `apply_patch`, commits, branches, PRs, plans, and worktrees
- return analysis, tradeoffs, risks, and recommendations only

This is a prompt-level contract, not a hard runtime sandbox. It is intended to preserve the strengths of council-style review without introducing another plugin dependency.

### Operator prompts

Common operator patterns:

- direct question: `/council Should we use option A or B for this feature?`
- guided setup: `/council-directive Help me set up a council for this API design decision`
- structured directive: paste a `Council Directive` block under `/council`
- new-session handoff: run `/council-directive`, then paste its `Paste Into New Chat` block into a fresh session

Use `/interview` before council when the problem itself is still under-defined. Use `/council-directive` when the problem is known but the council shape, direction, or output still needs tightening.

## VS Code companion

`vscode-hive` is recommended as the visual companion for this profile when you use OpenCode from VS Code.

Install it with:

```bash
code --install-extension tctinh.vscode-hive
```

Use it for:

- reviewing Hive plan files and context files
- seeing feature and task status in the sidebar
- adding review comments while OpenCode remains the execution harness

## Extending the profile

The current baseline is intentionally conservative. It gives you a working remote `agent-hive` setup without assuming local proxies or a multi-provider model matrix.

To extend it later:

1. Add provider definitions to `opencode.json`.
2. Point `agent_hive.json` roles at those provider/model pairs.
3. Document any required environment variables or binaries in this README.

## Optional MCP and LSP bundles

Optional merge snippets live under `profiles/optional/`.

- `profiles/optional/opencode.mcp-context7-enabled.json`
- `profiles/optional/opencode.lsp-all-recommended.json`
- `profiles/optional/opencode.lsp-markdown-typescript.json`
- `profiles/optional/opencode.lsp-python.json`

These files are partial JSON snippets intended to be merged into `opencode.json`. They are not standalone configs.

The operator guide for those bundles lives at `profiles/optional/README.md`. It documents:

- what each bundle enables
- which binaries or environment variables must exist first
- how to verify the dependencies are available
- when the bundle is suitable for a portable profile

Apply a snippet with:

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

That script validates prerequisites, backs up the current `opencode.json`, and merges the chosen snippet into the active config.

## Recommended LSP stack

If you want the full recommended LSP stack, install the binaries first, then install the profile, then apply the `lsp-all-recommended` snippet.

Recommended toolchain:

- `vtsls`: install Node.js LTS, then run `npm install -g @vtsls/language-server`
- `ruff`: install `uv`, then run `uv tool install ruff@latest`
- `ty`: install `uv`, then run `uv tool install ty@latest`
- `marksman`: install it from the official package manager or release-binary instructions at `https://github.com/artempyanykh/marksman/blob/main/docs/install.md`

Recommended order:

1. Install the LSP binaries.
2. Verify they are on `PATH`.
3. Run `./scripts/install-profile.sh`.
4. Run `./scripts/enable-optional.sh lsp-all-recommended`.

Copy-paste example:

```bash
npm install -g @vtsls/language-server
uv tool install ruff@latest
uv tool install ty@latest
# install marksman using its official instructions first
./scripts/install-profile.sh
./scripts/enable-optional.sh lsp-all-recommended
```

Verification commands:

- `marksman --help`
- `vtsls --stdio`
- `ruff server --help`
- `ty server --help`

## Notes on skill migration

The previous setup mixed a Claude Code skill directory and `~/.config/opencode/skill`. This repo normalizes the shared parts into one APM-installable Opencode package under `.apm/skills`.

Some skill text still refers to Hive-specific skills such as `writing-plans` or `verification-before-completion`. Those are provided by `opencode-hive`, not by this repo.
