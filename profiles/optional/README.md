# Optional MCP And Workflow Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the `profiles/base/` payloads by default.

These optional bundles are Opencode-only. Cursor v1 has no optional MCP bundle in this repository, and Cursor setup does not alter these snippets. Use `CURSOR.md` and `./scripts/cursor-assets.sh` only for the separate Cursor prompt-level asset flow.

## Operating model

Each bundle is a partial `opencode.json` fragment. Optional bundles leave `agent_hive.json` unchanged.

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

Prerequisites:

- `uvx` available on `PATH`
- network access to `https://mcp.context7.com/mcp`
- a non-blank `secrets/context7` file in the target Opencode config directory; write it with `./scripts/write-secret.sh context7`

Verification:

- `uvx --help`
- `LC_ALL=C grep -q '[^[:space:]]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present`

Some notes:

- this bundle normalizes the live local setup into portable `PATH`-based commands and config-relative secret files
- this bundle updates `opencode.json`; Hive Scout skill loading comes from the base Hive config. `oc-arkive` releases newer than 2.5.0 bundle no research MCPs, so these entries are the only `ast_grep` and `context7` servers loaded
- if an earlier install set `disableMcps` in `agent_hive.json`, rerun `./scripts/install-profile.sh --apply` to replace that config with the current base profile. Newer `oc-arkive` releases ignore an `agent_hive.json` that still has `disableMcps`, and applying this bundle alone leaves an existing Hive config untouched
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
- a non-blank `secrets/context7` file in the target Opencode config directory; write it with `./scripts/write-secret.sh context7`

Verification:

- `LC_ALL=C grep -q '[^[:space:]]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present`

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
- a Keenable API key in a non-blank `secrets/keenable` file in the target Opencode config directory; write it with `./scripts/write-secret.sh keenable`

Verification:

- `LC_ALL=C grep -q '[^[:space:]]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/keenable" && echo present`
- after enable, confirm `mcp.keenable.headers["X-API-Key"]` is `{file:secrets/keenable}`

Some notes:

- Keenable also answers without a key on a shared public tier limited per IP address. This bundle requires a key on purpose so agent traffic uses your account's limits instead of that shared pool

Portability:

- high
- no local binary required

## Merge workflow

The merge workflow involves the following:

1. Pick a snippet from this directory.
2. Verify the listed dependencies on the target machine.
3. Merge the relevant JSON object into `opencode.json`.
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
- it creates a timestamped backup of the current `opencode.json` before replacing it
- it refuses to apply a snippet if a listed binary is missing, or if a secret file the snippet references is missing, unreadable, or blank; it checks secret files under the selected `OPENCODE_CONFIG_DIR`
- it never creates, copies, or backs up `secrets/`; `scripts/write-secret.sh` writes key files
- installing the base profile again replaces `opencode.json` and drops merged snippets, so reapply them after each base reinstall

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- avoid absolute paths
- prefer command names resolved through `PATH`
- read API keys through `{file:secrets/<name>}` relative to the config directory, never inline and never from a tracked file, and record the secret file next to the bundle that uses it
- keep secret-file references out of `profiles/base/`; Opencode refuses to start when a referenced file is missing
