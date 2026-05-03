# Optional MCP, LSP, And Workflow Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the base profile by default.

## Operating model

Each bundle is led by a partial `opencode.json` fragment and may also include a matching `agent_hive.json` overlay when Hive-specific behavior must change.

Purpose:

- keep the base profile safe on a fresh machine
- make local dependencies explicit
- let a human or agent enable only the integrations that the machine can actually support

These snippets are usually applied manually. The exception is `context-improved`, which `scripts/install-profile.sh` now auto-applies when the selected AGENTS profile is `shared-context-improved` or `personal-context-improved` and the listed prerequisites are present.

## Bundles

### `opencode.context-improved.json`

Purpose: Enables the portable context-improved overlay in one merge.

It adds:

- the published `context-mode` plugin alongside `opencode-hive@latest`
- a local `context-mode` MCP launched from `PATH`
- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry already present in the base profile
- the matching `agent_hive.context-improved.json` overlay so Hive workers keep `ast_grep` disabled while the main Opencode session can use it

Prerequisites:

- `context-mode` available on `PATH`
- `uvx` available on `PATH`
- network access to `https://mcp.context7.com/mcp`
- `CONTEXT7_API_KEY` set in the environment

Verification:

- `context-mode --help`
- `uvx --help`
- `printenv CONTEXT7_API_KEY`

Some notes:

- this bundle normalizes the live local setup into portable `PATH`-based commands and environment variables
- this bundle updates both `opencode.json` and `agent_hive.json`
- the installer auto-applies this bundle for the `shared-context-improved` and `personal-context-improved` AGENTS profiles after preflighting the same prerequisites
- install `cymbal` with `brew install 1broseidon/tap/cymbal` when the machine uses Homebrew and you want the full local navigation workflow
- `cymbal` is a separate CLI tool for local code navigation, but it is not wired through `opencode.json`; the AGENTS profiles use it when the current Opencode environment exposes it
- this bundle supersedes `opencode.mcp-context7-enabled.json` on machines that want the full tool stack
- pair it with `profiles/agents/shared-context-improved.md` or `profiles/agents/personal-context-improved.md` so the installed `AGENTS.md` assumes the same capabilities the config actually enables
- when the AGENTS guidance is being reconciled, merge the added routing rules into the existing hand-maintained `AGENTS.md` structurally; do not treat the profile as a wholesale replacement for that file

Portability:

- medium
- suitable when the local Node and `uv` runtimes are already installed and the operator wants the context and structural-search toolchain enabled together

### `opencode.mcp-context7-enabled.json`

Purpose: Enables the remote `context7` MCP entry already defined in the base profile.

Prerequisites:

- network access to `https://mcp.context7.com/mcp`
- `CONTEXT7_API_KEY` set in the environment

Verification:

- `printenv CONTEXT7_API_KEY`

Portability:

- high
- no local binary required

### `opencode.lsp-all-recommended.json`

Purpose: Adds all four recommended LSPs in one snippet: `marksman`, `vtsls`, `ruff`, and `ty`.

Prerequisites:

- `marksman` available on `PATH`
- `vtsls` available on `PATH`
- `ruff` available on `PATH`
- `ty` available on `PATH`
- for `vtsls`, a working Node.js runtime is expected

Install guidance:

- `vtsls`: install Node.js LTS, then run `npm install -g @vtsls/language-server`
- `ruff`: install `uv`, then run `uv tool install ruff@latest`
- `ty`: install `uv`, then run `uv tool install ty@latest`
- `marksman`: use the official package-manager or release-binary instructions at `https://github.com/artempyanykh/marksman/blob/main/docs/install.md`

Verification:

- `marksman --help`
- `vtsls --stdio`
- `ruff server --help`
- `ty server --help`

Portability:

- medium
- suitable once all four binaries are installed and discoverable on `PATH`

### `opencode.lsp-markdown-typescript.json`

Purpose: Adds `marksman` for Markdown and `vtsls` for TypeScript and JavaScript.

Prerequisites:

- `marksman` available on `PATH`
- `vtsls` available on `PATH`
- for `vtsls`, a working Node.js runtime is expected

Verification:

- `marksman --help`
- `vtsls --stdio`

Some notes:

- `vtsls --stdio` will wait for LSP traffic. The important part is that the command exists and starts.
- This bundle is portable only when the target machine already has these binaries installed through its preferred package manager or runtime tool.

### `opencode.lsp-python.json`

Purpose: Adds `ruff` and `ty` language servers for Python work.

Prerequisites:

- `ruff` available on `PATH`
- `ty` available on `PATH`

Verification:

- `ruff server --help`
- `ty server --help`

Portability:

- medium
- portable when the target machine already has the Python tooling installed

## Merge workflow

The merge workflow involves the following:

1. Pick a snippet from this directory.
2. Verify the listed dependencies on the target machine.
3. Merge the relevant JSON object into `opencode.json`, plus the matching `agent_hive.json` overlay when the bundle includes one.
4. Start Opencode and confirm the integration loads without command-not-found errors.

For `AGENTS.md`, keep the existing file and fold in the new routing rules structurally instead of replacing it.

## Automated merge

Use `scripts/enable-optional.sh` to validate prerequisites and merge a snippet into the active config.

```bash
./scripts/enable-optional.sh context-improved
```

Other examples:

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

Some notes:

- the script requires `jq`
- it creates a timestamped backup of the current `opencode.json`, and `agent_hive.json` when the bundle includes an Agent Hive overlay, before replacing them
- it refuses to apply a snippet if the listed binaries or environment variables are missing

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- keep local LSPs documented but opt-in
- avoid absolute paths
- prefer command names resolved through `PATH`
- record environment variables near the bundle that uses them
