# Optional MCP And Workflow Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the base profile by default.

These optional bundles are Opencode-only. Cursor v1 has no optional MCP bundle in this repository, and Cursor setup does not alter these snippets. Use `CURSOR.md` and `./scripts/cursor-assets.sh` only for the separate Cursor prompt-level asset flow.

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

- the published `context-mode` plugin while preserving the base plugins, including `oc-arkive@latest` and `opencode-gpt-imagegen`
- a local `context-mode` MCP launched from `PATH`
- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry already present in the base profile
- the matching `agent_hive.context-improved.json` overlay, which keeps `ast_grep` and `context7` disabled for Hive workers while loading `cymbal`, `ast-grep`, and `context-mode` for Scout research

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
- this bundle updates both `opencode.json` and `agent_hive.json`, including Scout skill loading for the local navigation workflow
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

### `opencode.chrome-devtools.json`

Purpose: Enables the portable Chrome DevTools MCP as the canonical interactive browser solution.

It adds:

- a local `chrome-devtools` MCP launched through `npx` with a non-absolute command
- `chrome-devtools-mcp@latest` resolved at runtime

Prerequisites:

- `npx` available on `PATH` (Node.js/npm toolchain)
- network access the first time `npx` downloads `chrome-devtools-mcp@latest`
- a Chrome/Chromium browser available for the MCP to control

Verification:

- `npx --version`
- after enable, confirm `mcp.chrome-devtools.command` is `["npx", "-y", "chrome-devtools-mcp@latest"]`

Some notes:

- AGENTS profiles route interactive browser work to `chrome-devtools`
- keep the command PATH-based; do not embed absolute Node or home-directory paths

Portability:

- medium
- suitable when Node.js is installed and the operator wants interactive browser automation

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
./scripts/enable-optional.sh chrome-devtools
```

Some notes:

- the script requires `jq`
- it creates a timestamped backup of the current `opencode.json`, and `agent_hive.json` when the bundle includes an Agent Hive overlay, before replacing them
- it refuses to apply a snippet if the listed binaries or environment variables are missing

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- avoid absolute paths
- prefer command names resolved through `PATH`
- record environment variables near the bundle that uses them
