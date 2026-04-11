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

## Recommended policy

For a shareable profile:

- keep remote MCPs preferred over local MCPs
- keep local LSPs documented but opt-in
- avoid absolute paths
- prefer command names resolved through `PATH`
- record environment variables near the bundle that uses them
