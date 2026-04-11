# Optional MCP And LSP Bundles

This directory contains merge snippets for machine-dependent integrations that should not be enabled in the base profile by default.

## Operating model

Each snippet is a partial `opencode.json` fragment.

Purpose:

- keep the base profile safe on a fresh machine
- make local dependencies explicit
- let a human or agent enable only the integrations that the machine can actually support

These snippets are not installed automatically. They are intended to be reviewed and merged into `opencode.json` when the listed prerequisites are present.

## Bundles

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
3. Merge the relevant JSON object into `opencode.json`.
4. Start Opencode and confirm the integration loads without command-not-found errors.

## Automated merge

Use `scripts/enable-optional.sh` to validate prerequisites and merge a snippet into the active config.

```bash
./scripts/enable-optional.sh lsp-all-recommended
```

Some notes:

- the script requires `jq`
- it creates a timestamped backup of the current `opencode.json` before replacing it
- it refuses to apply a snippet if the listed binaries or environment variables are missing

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- keep local LSPs documented but opt-in
- avoid absolute paths
- prefer command names resolved through `PATH`
- record environment variables near the bundle that uses them
