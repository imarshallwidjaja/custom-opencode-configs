# Optional MCP And Workflow Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the `profiles/base/` payloads by default.

These optional bundles are Opencode-only. Cursor v1 has no optional MCP bundle in this repository, and Cursor setup does not alter these snippets. Use `CURSOR.md` and `./scripts/cursor-assets.sh` only for the separate Cursor prompt-level asset flow.

## Operating model

Each bundle is led by a partial `opencode.json` fragment and may also include a matching `agent_hive.json` overlay when Hive-specific behavior must change.

Purpose:

- keep the base profile safe on a fresh machine
- make local dependencies explicit
- let a human or agent enable only the integrations that the machine can actually support

These snippets are usually applied manually. The exception is `context-improved`, which `scripts/install-profile.sh --apply` auto-applies when the selected AGENTS profile is `shared-context-improved` or `personal-context-improved` and the listed prerequisites are present.

Running `./scripts/install-profile.sh` with no arguments previews without changes or hooks. Use `--apply` to install immediately, or `--help` for usage.

## Bundles

### `opencode.context-improved.json`

Purpose: Enables the portable context-improved overlay in one merge.

It adds:

- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry already present in the base profile, enabled with a `CONTEXT7_API_KEY` header read from `{file:secrets/context7}`
- the matching `agent_hive.context-improved.json` overlay, which writes `disableMcps` to `context7` and `ast_grep` on the target Hive config. The base Hive config sets no `disableMcps`, so an `oc-arkive` release that bundles research MCPs would register its own `context7` and `ast_grep` and replace this bundle's entries; the overlay stops that. It replaces any previous `disableMcps` list on the target. Scout skill loading comes from the base Hive config.

Prerequisites:

- `uvx` available on `PATH`
- network access to `https://mcp.context7.com/mcp`
- a non-empty `secrets/context7` file in the target Opencode config directory

Verification:

- `uvx --help`
- `test -s "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present`

Some notes:

- this bundle normalizes the live local setup into portable `PATH`-based commands and config-relative secret files
- this bundle updates both `opencode.json` and `agent_hive.json`; Hive Scout skills stay on the base config. The Hive overlay writes `disableMcps` to `context7` and `ast_grep`, replacing any previous list on the target, so Hive's same-named built-ins cannot replace the MCP entries this bundle enables
- the installer auto-applies this bundle for the `shared-context-improved` and `personal-context-improved` AGENTS profiles after preflighting the same prerequisites
- install `cymbal` with `brew install 1broseidon/tap/cymbal` when the machine uses Homebrew and you want the full local navigation workflow
- `cymbal` is a separate optional CLI tool for local code navigation; when it is on `PATH`, both `scripts/install-profile.sh` and this bundle attempt to install its supported OpenCode hook into the selected `OPENCODE_CONFIG_DIR`, and a hook failure warns without failing the install
- this bundle supersedes `opencode.mcp-context7-enabled.json` on machines that want the full tool stack
- pair it with `profiles/agents/shared-context-improved.md` or `profiles/agents/personal-context-improved.md` so the installed `AGENTS.md` assumes the same capabilities the config actually enables
- when the AGENTS guidance is being reconciled, merge the added routing rules into the existing hand-maintained `AGENTS.md` structurally; do not treat the profile as a wholesale replacement for that file

Portability:

- medium
- suitable when the local Node and `uv` runtimes are already installed and the operator wants the context and structural-search toolchain enabled together

### `opencode.mcp-context7-enabled.json`

Purpose: Enables the remote `context7` MCP entry already defined in the base profile and adds its `CONTEXT7_API_KEY` header from `{file:secrets/context7}`.

Prerequisites:

- network access to `https://mcp.context7.com/mcp`
- a non-empty `secrets/context7` file in the target Opencode config directory

Verification:

- `test -s "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present`

Portability:

- high
- no local binary required

### `opencode.chrome-devtools.json`

Purpose: Enables the portable Chrome DevTools MCP as the canonical interactive browser solution.

It adds:

- a local `chrome-devtools` MCP launched through `npx` with a non-absolute command
- `chrome-devtools-mcp@latest` resolved at runtime
- `--isolated=true`, which gives each run a temporary browser profile that is deleted when the browser closes
- `--category-extensions=true`, which exposes the browser-extension tools; upstream supports them only when the MCP launches Chrome itself

Prerequisites:

- `npx` available on `PATH` (Node.js/npm toolchain)
- network access the first time `npx` downloads `chrome-devtools-mcp@latest`
- a Chrome/Chromium browser available for the MCP to control

Verification:

- `npx --version`
- after enable, confirm `mcp.chrome-devtools.command` is `["npx", "-y", "chrome-devtools-mcp@latest", "--isolated=true", "--category-extensions=true"]`

Some notes:

- AGENTS profiles route interactive browser work to `chrome-devtools`
- keep the command PATH-based; do not embed absolute Node or home-directory paths
- the bundle does not pass `--headless`, so Chrome opens a visible window; isolated runs do not keep logins or cookies between sessions

Portability:

- medium
- suitable when Node.js is installed and the operator wants interactive browser automation

### `opencode.keenable.json`

Purpose: Enables the remote Keenable web search and page-fetch MCP.

It adds:

- a remote `keenable` MCP at `https://api.keenable.ai/mcp`, enabled on merge
- an `X-API-Key` header read from `{file:secrets/keenable}`

Prerequisites:

- network access to `https://api.keenable.ai/mcp`
- a Keenable API key in a non-empty `secrets/keenable` file in the target Opencode config directory

Verification:

- `test -s "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/keenable" && echo present`
- after enable, confirm `mcp.keenable.headers["X-API-Key"]` is `{file:secrets/keenable}`

Portability:

- high
- no local binary required

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
./scripts/enable-optional.sh keenable
```

Some notes:

- the script requires `jq`
- it creates a timestamped backup of the current `opencode.json`, and `agent_hive.json` when the bundle includes an Agent Hive overlay, before replacing them
- it refuses to apply a snippet if a listed binary is missing, or if a secret file the snippet references is missing, unreadable, or blank; it checks secret files under the selected `OPENCODE_CONFIG_DIR`
- it never creates, copies, or backs up `secrets/`

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- avoid absolute paths
- prefer command names resolved through `PATH`
- read API keys through `{file:secrets/<name>}` relative to the config directory, never inline and never from a tracked file, and record the secret file next to the bundle that uses it
- keep secret-file references out of `profiles/base/`; Opencode refuses to start when a referenced file is missing
