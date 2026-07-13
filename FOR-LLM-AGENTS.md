# For LLM Agents

This document tells an Opencode agent how to set up this repository for a less technical operator.

Use it when the operator says things like:

- "Set this repo up as my Opencode config."
- "Install this custom Opencode profile for me."
- "Install the Cursor assets from this repo."
- "Read this repo and walk me through the setup."

## Operator Prompt

Give the agent this repository and this document, then say:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, preserve my existing AGENTS.md as the base document for any merge unless I explicitly approve full replacement, run the setup commands for me, and verify the final Opencode config.
```

If the request is only for Cursor assets, replace the final Opencode verification instruction with Cursor validation, install or dry-run, Rules paste guidance, and target-layout verification.

## What This Repo Actually Supports

Do not invent extra setup questions. This repository exposes the following real choices:

1. Which installable `AGENTS.md` profile to use:
   - `shared`
   - `personal-default`
   - `shared-context-improved`
   - `personal-context-improved`
2. Which Opencode config directory to install into:
   - default `~/.config/opencode`
   - a custom `OPENCODE_CONFIG_DIR`
3. Whether to enable the optional context-improved bundle:
   - none
   - `context-improved`
4. Whether to enable the optional `context7`-only MCP snippet when the full context-improved bundle is not being used:
   - none
   - `mcp-context7-enabled`
5. Whether to enable the optional `chrome-devtools` browser MCP:
   - none
   - `chrome-devtools`
6. Whether to install the optional Agent Hive / `oc-arkive` VS Code companion from the latest release `.vsix`.
7. Whether to install the separate Cursor prompt-level assets:
   - skip Cursor setup
   - validate and inspect the Cursor assets only
   - install the Cursor assets into `${CURSOR_CONFIG_DIR:-$HOME/.cursor}` or semicolon-separated `CURSOR_CONFIG_DIRS` targets and paste Rules manually

Some setup facts are not user choices:

- The default full install path is `./scripts/install-profile.sh`.
- The default repo profile uses non-fast `openai/gpt-5.6-sol` plus selected `opencode-go/*` models in `agent_hive.json`, and an `opencode-go/*` model for the base Opencode `explore` override in `opencode.json`.
- The base `opencode.json` also sets `agent.compaction` to `openai/gpt-5.5` with `variant: low`, while keeping top-level compaction `auto` and `prune` disabled.
- The base `opencode.json` also includes the `opencode-gpt-imagegen` plugin. It currently requires ChatGPT Plus or Pro OAuth and does not provide API-key image generation; no credentials are stored in this repository.
- OpenAI Hive roles always use exactly `openai/gpt-5.6-sol`, never a fast variant. Portable profiles do not import personal `xai/*` or `crof/*` models.
- Worker auto-load uses the canonical Hive skill name `verification-before-completion`. Custom agents use only supported `baseAgent` values from the current Hive contract.
- The published `oc-arkive@latest` plugin is installed by Opencode on first run.
- Updating this repository's profile files does not prove Opencode is using the latest cached `oc-arkive@latest` plugin. After a profile update, restart Opencode. If the Agent Hive commands or plugin manifest still match an older release, remove or refresh the cached `oc-arkive` plugin entry according to the local Opencode cache layout before starting Opencode again.
- The optional context-improved bundle adds `context-mode@latest`, local `ast_grep`, enabled `context7`, and a matching `agent_hive.json` overlay. The base Agent Hive config disables `context7` and `ast_grep` for Hive workers.
- `context7` is present in the base config but disabled by default.
- `cymbal` is not configured through `opencode.json`. It is a separate CLI tool that the context-improved AGENTS profiles know how to use when it is installed and available on `PATH`.
- The packaged `use-railway` skill needs the Railway CLI and Railway auth; without them it is unused.
- Direct `apm install -g ...` is not the right default for first-time setup because it does not install `opencode.json`, `agent_hive.json`, or `AGENTS.md`.
- This profile ships non-Hive prompt-backed commands `interview-drill-down` and `planning-prompt`. Hive workflow commands still come from the published `oc-arkive` plugin; the installer removes the old managed Hive command files from `commands/` after backing the directory up.
- Cursor setup is separate from Opencode setup. It does not install `opencode.json`, `agent_hive.json`, Opencode `AGENTS.md`, or `oc-arkive`.
- Cursor v1 is prompt-level behavior only. It installs Cursor assets under `${CURSOR_CONFIG_DIR:-$HOME/.cursor}` or every target in semicolon-separated `CURSOR_CONFIG_DIRS`, and requires manual paste into Cursor Settings -> Rules; it does not provide Agent Hive runtime/tool parity.
- Cursor asset setup must run from the repository root with `python3` and `scripts/cursor-assets.sh` available. Use `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom Cursor target, or `CURSOR_CONFIG_DIRS="/path/one;/path/two"` when Cursor needs multiple global config roots.
- Windows Cursor with WSL projects should normally install into both the WSL config root and the Windows config root, for example `CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor"` from WSL.
- If the operator asks only for Cursor assets, skip Opencode install, Opencode startup, and final Opencode verification. Stop after Cursor validation, optional install, Rules paste or paste instructions, and target-layout verification.
- When merging into an existing `AGENTS.md`, start from the user's file and reconcile the selected profile into it instead of replacing it by default.
- AGENTS profile selection changes operating rules, not just tool routing. Preserve the selected profile's parity-validation wording, failed-subagent retry policy, subagent final-response instructions, and resume-work guidance when merging.

To make it simple: use the repo scripts for the normal setup path, then offer the optional bundles only after the base profile is installed.

## Updating An Existing Install

Use this workflow when the operator already has an older version of this repository's config installed and wants to update it in place.

Start by explaining the update boundary: `curl -fsSL https://opencode.ai/install | bash` updates or installs the Opencode binary, but it does not update this repository's profile files. Updating the profile means updating the repository clone and rerunning this repo's installer against the active Opencode config directory.

Follow this safe order:

1. Identify the target config directory. Recommend `~/.config/opencode` unless the existing install clearly uses a custom `OPENCODE_CONFIG_DIR`. If uncertain, ask:

```text
I recommend updating the normal Opencode config at ~/.config/opencode. Is this the config you want updated, or do you use a custom OPENCODE_CONFIG_DIR?
```

2. Inspect the existing target before writing. Check whether `opencode.json`, `agent_hive.json`, `AGENTS.md`, `skills/`, `agents/`, or `commands/` exist. Read the existing `AGENTS.md` when present and note any local operator-specific instructions. If `commands/` contains the old Hive prompt command files, explain that this repo now removes those managed files because `oc-arkive` owns the command surface.
3. Update the repository clone with `git pull`. If the repository is not cloned, clone it first. If there are local changes in the repository clone, stop and ask before pulling or changing branches.
4. Choose the AGENTS profile. Recommend preserving the currently intended profile when it is evident from prior install notes or operator preference; otherwise recommend `shared` as the safest portable default. If uncertain, ask one question and include the recommendation.
5. Decide how to handle the existing `AGENTS.md`:
   - If the operator wants the current canonical profile and approves replacement, run the installer normally. It will back up the old `AGENTS.md` before replacing it.
   - If the existing `AGENTS.md` has local instructions or the operator is unsure, recommend preservation. Run the installer with `OPENCODE_AGENTS_MODE=skip`, then merge the selected profile guidance into the user's file manually after comparing both documents.
6. Run the installer with the selected `OPENCODE_CONFIG_DIR` and `OPENCODE_AGENTS_PROFILE` values.
7. Reapply optional bundles only when the operator wants them and prerequisites pass. Do not assume an older local optional setup still belongs in the updated config.
8. Restart Opencode so config and plugin resolution are reloaded. If Opencode still exposes an older Agent Hive command surface, remove or refresh the cached `oc-arkive` plugin entry according to the local Opencode cache layout, then start Opencode again.
9. Verify the result: validate `opencode.json` and `agent_hive.json` as JSON, run `opencode` or the smallest available Opencode startup check, confirm the `oc-arkive` plugin manifest or Agent Hive commands match the expected latest release, and report the backup directory printed by the installer.

Clean replacement example:

```bash
git pull
./scripts/install-profile.sh
```

Preserve and manually merge an existing `AGENTS.md`:

```bash
git pull
OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh
```

Custom directory and selected profiles:

```bash
git pull
OPENCODE_CONFIG_DIR=/path/to/opencode-config OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Some notes:

- never use direct `apm install -g ...` as the update path for this full profile because it does not update `opencode.json`, `agent_hive.json`, or `AGENTS.md`
- never silently overwrite an existing hand-maintained `AGENTS.md`; preserve it by default when uncertain
- do not delete `.backup/` directories during an update
- if `git pull` fails because the repository clone has local edits, stop and ask whether to preserve, commit, stash, or discard those edits
- when updating from a much older config, prefer asking one focused question with a recommendation over presenting every install option again

## Files To Read First

Before making changes, read these files from this repository:

- `README.md`
- `profiles/agents/README.md`
- `profiles/optional/README.md`
- `scripts/install-profile.sh`
- `scripts/enable-optional.sh`
- `CURSOR.md` when the operator asks for Cursor setup
- `scripts/cursor-assets.sh` when the operator asks for Cursor setup

## Interview Rules

- Ask one setup question at a time.
- Explain each option in plain language.
- Recommend the safest default when the operator is unsure.
- Read the user's existing `AGENTS.md` before proposing any merge edits.
- Compare the user's `AGENTS.md` against the selected profile before writing anything.
- Add missing prescribed guidance into the user's structure instead of overwriting it by default.
- Identify real conflicts before editing them.
- Ask permission before consolidating, rewriting, or deleting conflicting instructions.
- Do not push optional tooling unless the operator wants it and the machine can support it.
- Use the repository scripts instead of manually copying files.
- If a prerequisite is missing, ask whether the operator wants you to install it or skip the related optional feature.
- If the operator wants the context-improved workflow, explain that the matching `shared-context-improved` or `personal-context-improved` profile now applies the `context-improved` JSON overlays automatically during install.
- Make it clear that `cymbal` is an optional CLI dependency, not a bundled config entry. If it is missing, the context-improved profile can still work, but agents will fall back to the other available search tools.
- When the operator wants `cymbal`, install it with Homebrew using `brew install 1broseidon/tap/cymbal` if Homebrew is available on the machine.
- Keep the operator informed about what you are about to run.
- Treat AGENTS profile choice as an operating-policy choice too, not only a toolchain choice.
- During AGENTS merges, preserve the selected profile's parity-validation wording, new-session retry rule for failed subagents, explicit subagent final-response instructions, and resume-work guidance.

## Recommended Defaults

Use these defaults unless the operator asks for something else:

- Install into `~/.config/opencode`.
- Use the `shared` AGENTS profile.
- Skip optional MCP snippets unless there is a clear need.
- Install the VS Code companion extension only if the operator uses VS Code.
- Skip Cursor setup unless the operator explicitly wants Cursor prompt-level assets.

When the operator explicitly wants the richer local search and context workflow, recommend this pair together:

- `shared-context-improved` as the AGENTS profile
- `context-improved` as the optional JSON overlay

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

Also verify that the operator has OpenAI access available before running `opencode auth login -p openai`.

If `opencode` is missing, the standard install command is:

```bash
curl -fsSL https://opencode.ai/install | bash
```

If the operator wants the richer local navigation workflow and `cymbal` is missing, install it with:

```bash
brew install 1broseidon/tap/cymbal
```

Only do that when Homebrew is available. If `brew` is missing, explain that `cymbal` stays optional and continue with the base install unless the operator asks you to stop and install Homebrew first.

If the repository is not already cloned, clone it before continuing.

### 3. Authenticate Opencode

Ask:

```text
Have you already signed Opencode into OpenAI on this machine, or should I do that now?
```

If needed, run:

```bash
opencode auth login -p openai
```

### 4. Choose the AGENTS profile

Ask:

```text
Do you want the neutral shared profile, the personal-default profile with the author's writing style, or one of the context-improved variants that assume the richer optional local toolchain is enabled too?
```

Explain the options like this:

- `shared`: the safest team-friendly default
- `personal-default`: the shared rules plus the author's writing voice and phrase patterns
- `shared-context-improved`: the shared profile plus strong routing rules for `context-mode`, `ast-grep`, `context7`, and optional `cymbal`
- `personal-context-improved`: the personal-default profile plus the same context-improved routing rules

Recommendation:

- Recommend `shared` unless the operator explicitly wants the author's style.
- Recommend `shared-context-improved` only when the operator wants that richer workflow and is willing to satisfy the extra dependencies.

### 5. Install the base profile

The repository root `agent_hive.json` is the sole Hive config. It uses non-fast `openai/gpt-5.6-sol` plus selected `opencode-go/*` roles. Confirm those providers are available before install.

Explain this before running the installer: it replaces the target directory's `opencode.json`, `agent_hive.json`, `AGENTS.md`, and `skills/` contents with this repo's versions; installs optional standalone `agents/` or prompt-backed `commands/` only when this repo packages them; removes the old managed Hive command prompt files from `commands/`; and writes timestamped backups under `<target>/.backup/` first when those paths already exist. For the `shared-context-improved` and `personal-context-improved` profiles, it also preflights `jq`, `context-mode`, `uvx`, and `CONTEXT7_API_KEY`, then auto-applies the matching `context-improved` overlays. This is the clean install path; when you are merging into an existing `AGENTS.md`, use the manual merge workflow below so the user's file stays the base.

Run one of these:

```bash
./scripts/install-profile.sh
```

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

If a custom config directory was chosen, include `OPENCODE_CONFIG_DIR=/path/to/dir` as well.

Do not use the APM-only install path for first-time setup unless the operator explicitly asks for it.

### Merge an existing `AGENTS.md` with the selected profile

When the target already has an `AGENTS.md`, follow this order:

1. Run `OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh` so the installer does not replace the user's file.
2. Read the user's current `AGENTS.md` and the selected profile from this repository.
3. Map the sections and instruction intent in both documents.
4. Add compatible missing guidance into the user's structure without overwriting user content by default. That includes the profile's parity-validation wording, failed-subagent retry policy, subagent final-response instructions, and `resume-tailoring` guidance when the selected profile includes it.
5. Stop when you find a real conflict and present it to the user.
6. Only consolidate, rewrite, or delete conflicting instructions after explicit approval.
7. Back up the user's `AGENTS.md` before writing the merged result.

### 6. Offer the optional context-improved bundle first

Ask:

```text
Do you want the richer local context and code-navigation workflow on this machine? That enables context-mode, local ast-grep, and context7 together, adds the matching Agent Hive overlay, and pairs best with the shared-context-improved or personal-context-improved AGENTS profile.
```

Only enable it if:

- the operator wants it
- `jq` is installed
- `context-mode` is on `PATH`
- `uvx` is on `PATH`
- `CONTEXT7_API_KEY` is set
- the machine can reach `https://mcp.context7.com/mcp`

Optional but recommended for the full navigation workflow:

- `cymbal` on `PATH`

If `cymbal` is missing and `brew` is available, install it with:

```bash
brew install 1broseidon/tap/cymbal
```

Explain this clearly:

- `cymbal` is a CLI tool the AGENTS profile can call when it is installed
- it is not configured in `opencode.json`
- if it is missing, the context-improved profile still works, but agents will fall back to the other available search tools

If the operator wants the context-improved bundle and the selected AGENTS profile is one of the context-improved variants, let `scripts/install-profile.sh` handle it automatically.

If the operator wants the context-improved bundle but the selected AGENTS profile is not one of the context-improved variants, offer to switch the AGENTS profile first.

If all conditions are met and the selected AGENTS profile is not one of the context-improved variants, run:

```bash
./scripts/enable-optional.sh context-improved
```

### 7. Offer the optional `context7` MCP when the full bundle is not being used

Ask:

```text
Do you want me to enable the optional context7 documentation MCP? It needs a CONTEXT7_API_KEY environment variable.
```

Only enable it if:

- the operator wants it
- the context-improved bundle was not already enabled
- `jq` is installed
- `CONTEXT7_API_KEY` is set
- the machine can reach `https://mcp.context7.com/mcp`

If all conditions are met, run:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Some notes:

- `scripts/enable-optional.sh` requires `jq`.
- `agent_hive.json` disables `context7` and `ast_grep` for Hive workers by default. That is part of this profile.
- the `context-improved` bundle also updates `agent_hive.json` for the enabled research tools.
- when `shared-context-improved` or `personal-context-improved` is selected, `scripts/install-profile.sh` applies that bundle automatically instead of requiring this separate step.

### 8. Offer the optional chrome-devtools browser MCP

Ask this first:

```text
Do you want interactive browser automation through chrome-devtools on this machine, or would you prefer to keep the setup minimal for now?
```

Before applying the bundle:

- check that `jq` is installed
- check that `npx` is on `PATH`
- explain that this is the canonical browser solution

Apply with:

```bash
./scripts/enable-optional.sh chrome-devtools
```

Do not apply the snippet before the base profile exists in the target directory.

### 9. Offer the optional VS Code extension

Ask:

```text
Do you use VS Code on this machine, and if so, do you want the optional Agent Hive / oc-arkive extension installed there too?
```

If yes and the `code` CLI is available, install the `.vsix` from the latest Agent Hive fork release:

```bash
curl -L -o vscode-arkive.vsix https://github.com/imarshallwidjaja/agent-hive/releases/latest/download/vscode-arkive.vsix
code --install-extension ./vscode-arkive.vsix
```

If the `code` CLI is not available, give the operator the latest release page and tell them to install the `vscode-arkive.vsix` asset manually:

```text
https://github.com/imarshallwidjaja/agent-hive/releases/latest
```

### 10. Offer the separate Cursor prompt-level assets

Ask:

```text
Do you also want the separate Cursor prompt-level assets installed for Cursor, or should we leave Cursor unchanged?
```

Before running commands, verify that you are in the repository root, `python3` is available, and `scripts/cursor-assets.sh` exists. Use the default target `${HOME}/.cursor` unless the operator gives `CURSOR_CONFIG_DIR` for one target or `CURSOR_CONFIG_DIRS` for multiple targets. If the operator uses Windows Cursor with WSL projects, recommend dual install to both `$HOME/.cursor` and the Windows config path visible from WSL.

If the operator only wants to inspect the assets, run:

```bash
./scripts/cursor-assets.sh validate
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install --dry-run
./scripts/cursor-assets.sh print-rules
```

If the operator approves installation into the selected Cursor config target, run:

```bash
./scripts/cursor-assets.sh validate
./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

Then paste the printed Rules text into Cursor Settings -> Rules, or tell the operator exactly where to paste it if they prefer to do that part themselves.

Verify the installed layout by checking for:

- six files under `${CURSOR_CONFIG_DIR:-$HOME/.cursor}/agents/`
- seven files under `${CURSOR_CONFIG_DIR:-$HOME/.cursor}/commands/`
- twelve `SKILL.md` files under `${CURSOR_CONFIG_DIR:-$HOME/.cursor}/skills/*/`

If `CURSOR_CONFIG_DIRS` was used, check those three layout conditions under every target in the semicolon-separated list.

Do not ask the operator to install `oc-arkive` for Cursor v1. Do not use direct `apm install -g` as proof that global Cursor assets were installed.

If the operator asked only for Cursor assets, stop here and report the Cursor target, validation result, install or dry-run result, and whether Rules were pasted into Cursor Settings -> Rules or handed off for manual paste.

### 11. Start Opencode once

Run:

```bash
opencode
```

This allows Opencode to resolve `oc-arkive@latest` from `opencode.json` on first run.

If the context-improved bundle was enabled, this first run also needs to succeed without command-not-found errors for `context-mode` or the local MCP tooling.

Success signal:

- Opencode starts without reporting plugin-resolution or command-not-found errors for the base profile.

### 12. Verify the final state

Verify that the target config directory now contains:

- `opencode.json`
- `agent_hive.json`
- `AGENTS.md`
- `skills/`
- `agents/`
- `commands/` when present, especially legacy managed Hive prompt commands that the installer now removes

If optional snippets were enabled, verify that the relevant entries exist in `opencode.json`.

Concrete checks:

- if `context-improved` was enabled, verify `plugin` includes both `context-mode@latest` and `opencode-gpt-imagegen`
- if `context-improved` was enabled, verify `mcp.context-mode`, `mcp.ast_grep`, and `mcp.context7.enabled` exist in `opencode.json`
- if `context7` was enabled, verify `mcp.context7.enabled` is `true`
- if `chrome-devtools` was enabled, verify `mcp.chrome-devtools.command` is `["npx", "-y", "chrome-devtools-mcp@latest"]`
- verify `plugin` includes `opencode-gpt-imagegen`
- verify every OpenAI model in `agent_hive.json` is exactly `openai/gpt-5.6-sol` with no `-fast` suffix

If the operator wanted `cymbal`, verify that `cymbal` is available on `PATH` with a simple command such as:

```bash
which cymbal
```

If `brew` was used to install it, prefer confirming the installed formula too:

```bash
brew list --versions cymbal
```

Then report back with:

- the install directory used
- the AGENTS profile selected
- whether the context-improved bundle was enabled
- whether `context7` was enabled
- whether `chrome-devtools` was enabled
- whether `cymbal` is installed as a CLI on this machine
- whether the VS Code extension was installed
- whether Cursor assets were skipped, inspected only, or installed; if installed, whether Rules were pasted into Cursor Settings -> Rules
- any skipped options and why

## Decision Inventory From The Repo Audit

Use this as the source of truth for the interview.

| Decision | Choices | Default | Requirements |
|---|---|---|---|
| AGENTS merge strategy | preserve the user's `AGENTS.md` as the base, or replace it only with explicit approval | preserve the user's file | explicit approval required before full replacement or conflict consolidation |
| AGENTS profile | `shared`, `personal-default`, `shared-context-improved`, `personal-context-improved` | `shared` | none |
| Config directory | `~/.config/opencode` or custom path | `~/.config/opencode` | none |
| Context-improved bundle | enable or skip | skip | `jq`, `context-mode`, `uvx`, `CONTEXT7_API_KEY`, network access; `cymbal` optional CLI |
| `context7` MCP only | enable or skip | skip | `jq`, `CONTEXT7_API_KEY`, network access |
| chrome-devtools MCP | enable or skip | skip | `jq`, `npx`, network for first `npx` download |
| VS Code companion extension | install or skip | skip unless operator uses VS Code | VS Code and usually `code` CLI; latest Agent Hive fork release `.vsix` |
| Cursor prompt-level assets | skip, inspect only, or install into the selected Cursor config target | skip unless operator asks for Cursor | `python3`; manual paste into Cursor Settings -> Rules |

## Commands The Agent Will Usually Need

Base install:

```bash
./scripts/install-profile.sh
```

Base install with the personal profile:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh
```

Base install with the shared context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh
```

Base install with the personal context-improved profile:

```bash
CONTEXT7_API_KEY=... OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh
```

Base install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config ./scripts/install-profile.sh
```

Enable the context-improved bundle:

```bash
./scripts/enable-optional.sh context-improved
```

Use that command when the install already used `shared` or `personal-default` and you want to add the richer bundle afterward.

Enable `context7` only:

```bash
./scripts/enable-optional.sh mcp-context7-enabled
```

Enable chrome-devtools browser MCP:

```bash
./scripts/enable-optional.sh chrome-devtools
```

Install the VS Code companion extension:

```bash
curl -L -o vscode-arkive.vsix https://github.com/imarshallwidjaja/agent-hive/releases/latest/download/vscode-arkive.vsix
code --install-extension ./vscode-arkive.vsix
```

Validate and inspect Cursor assets:

```bash
./scripts/cursor-assets.sh validate
CURSOR_CONFIG_DIR=/path/to/temp ./scripts/cursor-assets.sh install --dry-run
./scripts/cursor-assets.sh print-rules
```

Install Cursor assets:

```bash
./scripts/cursor-assets.sh validate
./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

Install Cursor assets into Windows and WSL global config roots from WSL:

```bash
./scripts/cursor-assets.sh validate
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install --dry-run
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

## What Not To Do

- Do not ask the operator to choose model IDs from this repo. Those defaults are already encoded.
- Do not select a mixed-provider Agent Hive profile unless the operator confirms the named providers are available.
- Do not default to direct `apm install -g` for first-time setup.
- Do not treat AGENTS merge as a blind append.
- Do not silently overwrite the user's existing `AGENTS.md` during merge.
- Do not silently clean up conflicts by deleting or rewriting instructions.
- Do not enable optional snippets without first checking their prerequisites.
- Do not enable the context-improved bundle without also checking whether the chosen `AGENTS.md` profile matches that capability set.
- Do not assume `personal-default` is appropriate for every operator.
- Do not describe `cymbal` as a bundled MCP or JSON config entry. It is a separate CLI dependency.
- Do not treat Cursor setup as Opencode setup; it does not install `opencode.json`, `agent_hive.json`, Opencode `AGENTS.md`, or `oc-arkive`.
- Do not claim Cursor v1 has Agent Hive runtime/tool parity.
- Do not document undocumented Cursor settings-file writes; use Cursor Settings -> Rules for the printed Rules text.
- Do not overwhelm the operator with all questions at once.
