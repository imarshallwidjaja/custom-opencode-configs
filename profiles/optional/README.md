# Optional MCP And Workflow Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the `profiles/base/` payloads by default.

These optional bundles are Opencode-only. Cursor v1 has no optional MCP bundle in this repository, and Cursor setup does not alter these snippets. Use `CURSOR.md` and `./scripts/cursor-assets.sh` only for the separate Cursor prompt-level asset flow. Cursor agents and skills never assume these MCP servers or the Hive tools; they use the tools the Cursor session exposes and report a missing capability as an evidence gap.

## Operating model

Each bundle is a partial `opencode.json` fragment. Optional bundles leave `agent_hive.json` unchanged.

The AGENTS profiles' UI and motion guidance requires `impeccable` and `animate` for matching work. These are separate skill dependencies; the MCP bundles do not install them. Report missing capabilities and obtain authorization before installing tools or skills, including MarkItDown conversion dependencies.

The accompanying profile targets OpenCode v1 >= 1.18.30 only and pins `oc-arkive@5.2.0`. Ownership and skill inventory were checked against `oc-arkive` 5.2.0. Check `opencode --version` before updating the plugin or profile and restarting its host process.

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
- this bundle updates `opencode.json`; `oc-arkive` no longer configures research MCPs or bundles an `ast-grep` skill. These operator-configured `ast_grep` and `context7` servers work independently of skill availability
- `oc-arkive` rejects `agent_hive.json` files containing the removed `disableMcps`, `sandbox`, `dockerImage`, or `persistentContainers` fields. Before restarting, replace or update that file to remove those fields (rerun `./scripts/install-profile.sh --apply` for the base config). A rejected file falls back to defaults, losing agents, customAgents, council, and model routing; repository and worktree tools can also fail with an invalid-config error. Applying this bundle alone leaves Hive config untouched
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
- the bundle does not pass `--headless`, so Chrome opens a visible window; isolated runs do not keep logins or cookies between sessions. On a machine without a display, add `"--headless"` to the merged `command` array yourself; the bundle keeps the visible window so an operator can watch and take over a run

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

### `opencode.railway.json`

Purpose: Enables the Railway MCP server through the Railway CLI.

It adds:

- a local `railway` MCP that runs `railway mcp`, which connects to `mcp.railway.com` over stdio and signs each request with the Railway CLI login

Prerequisites:

- the Railway CLI on `PATH`; connecting to `mcp.railway.com` needs Railway CLI 5.44.0 or later
- a Railway account signed in with `railway login`

Verification:

- `railway --version`
- `railway whoami`
- after enable, confirm `mcp.railway.command` is `["railway", "mcp"]`

Some notes:

- the bundle stores no Railway credentials; the CLI keeps and refreshes its own login
- `enable-optional.sh railway` refuses to merge when `railway` is not on `PATH`
- the Railway CLI also installs and maintains its own `use-railway` agent skill through `railway setup agent` / `railway skills`; this repository does not package or install it

Portability:

- medium
- needs the Railway CLI and a signed-in Railway account on each machine

### `opencode.atlassian.json`

Purpose: Enables the Atlassian Rovo MCP server for Jira, Confluence, and other Atlassian Cloud products.

It adds:

- a remote `atlassian` MCP at `https://mcp.atlassian.com/v2/mcp`, enabled on merge, with no stored credentials

Prerequisites:

- an Atlassian Cloud site and an account with access to the products you want agents to use
- network access to `https://mcp.atlassian.com`
- a browser on the machine for the OAuth 2.1 sign-in; a site admin may need to allow the Rovo MCP app first

Verification:

- after enable, run `opencode mcp auth atlassian` and complete the sign-in in the browser
- `opencode mcp list` shows `atlassian` as connected after the next Opencode start

Some notes:

- Opencode stores the OAuth tokens itself; the bundle and this repository hold no Atlassian credentials
- the packaged `working-with-atlassian`, `connecting-atlassian-tools`, and `managing-work-in-jira` skills operate this server's tools

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
./scripts/enable-optional.sh railway
./scripts/enable-optional.sh atlassian
```

Some notes:

- the script requires `jq`
- it backs up the current `opencode.json` before replacing it, into a new `.backup/<timestamp>.<suffix>/` directory per run, so two snippets applied in the same second keep separate backups. `OPENCODE_OPTIONAL_SKIP_BACKUP=1` skips the backup
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
