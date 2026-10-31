# custom-opencode-configs

Portable Opencode configuration for running Agent Hive with the published `oc-arkive@5.2.0` plugin.

This repo is for installing a ready-to-use Opencode profile. It keeps secrets, local proxy URLs, absolute home-directory paths, and machine-specific tools out of the base config.

## What gets installed

Running `./scripts/install-profile.sh` with no arguments previews the install without changes or hooks. A preview that finds a conflict or an unversioned skill prints the same `decision needed` lines as an install and exits 1. A clean preview exits 0. Add `--apply` to install immediately, or `--help` for usage.

`./scripts/install-profile.sh --apply` installs these files into your Opencode config directory:

- `profiles/base/opencode.json` -> `opencode.json`: base Opencode config with three pinned plugins, `oc-arkive@5.2.0`, `oc-multi-imagegen@1.0.0`, and `arkive-compact@1.3.0` (see [Base plugins](#base-plugins)). It turns off Opencode's internal file-change snapshots (`snapshot: false`), so agent edits cannot be rolled back through the Opencode UI, and startup self-updates (`autoupdate: false`), so update Opencode yourself. It disables the built-in `explore` agent so read-only research goes to Hive's `scout-researcher`, and disables the `amazon-bedrock` provider. `small_model`, the native `compaction` agent, and the `magic-compact-summarizer` agent run on `openai/gpt-6.1-sol`, the two agents at `variant: low`. Native compaction stays manual (`compaction.auto` and `compaction.prune` are `false`). The OpenAI provider waits up to 60 seconds for response headers and up to 30 minutes between streamed chunks (`headerTimeout: 60000`, `chunkTimeout: 1800000`); the Opencode default for each is 5 minutes
- `profiles/base/agent_hive.json` -> `agent_hive.json`: Agent Hive role and model configuration
- `profiles/base/tui.json` -> `tui.json`: merged, not replaced. The installer manages only the `arkive-compact` TUI plugin entry. It adds `arkive-compact@1.3.0`, or replaces an older `arkive-compact` entry or the local Magic Compact checkout entry (a file URL, absolute, Windows, or `./`-relative path ending in `magic-compact/packages/opencode-plugin/src/tui.ts`) in place, keeps any `[name, options]` options, and drops later duplicates. Other keys and plugin entries, including other local paths, stay as they are. When the file nests settings under a `tui` object, Opencode reads the top-level `plugin` array if there is one and the nested `tui.plugin` array otherwise; the installer edits the same array and leaves a shadowed nested array untouched, so it never activates plugins Opencode was ignoring. It refuses before writing anything when `tui.json` is a symlink or not a regular file, cannot be read, is not a strict JSON object (comments, trailing commas, `NaN`, and `Infinity` are not supported), has a `plugin` value that is not an array of names or `[name, options]` pairs, or holds `arkive-compact` entries with different options (`true` and `1` count as different), and when a `tui.jsonc` file exists in the same directory. A reinstall that finds the pinned entry already present leaves the file untouched
- `profiles/base/plugins/dcg-guard.js` -> `plugins/dcg-guard.js`: Destructive Command Guard adapter, auto-loaded from the Opencode plugins directory
- `profiles/base/plugins/shell-agents.js` -> `plugins/shell-agents.js`: nested `AGENTS.md` discovery for Bash tool calls, auto-loaded from the same directory (see [Base plugins](#base-plugins))
- `AGENTS.md`: the selected operating profile for Opencode agents
- `skills/`: OpenCode-local skill (`writing-skills`). The installer replaces that name in place from `.apm/skills/`. It preserves and reports a leftover shared canonical name, any of the 29 current Hive-bundled names, and retired names including the legacy aliases `code-reviewer`, `docker-mastery`, `verification-before-completion`, and `verification-reviewer`, plus `writing-policy`, `ast-grep`, `using-git-worktrees`, `finishing-a-development-branch`, `consolidate-test-suites`, `root-cause-finder`, and `context-mode`. Each is one `decision needed` line on stderr; the installer exits 1 after the rest of the install finishes. Other existing skill directories stay in place (for example `impeccable` from `npx impeccable install`) and are not reported.
- `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`: fifteen shared canonical skills used by both OpenCode and Cursor (`aero-design`, `connecting-atlassian-tools`, `cymbal`, `decomposing-work`, `drawio-skill`, `frontend-slides`, `hard-cut`, `managing-work-in-jira`, `react-best-practices`, `resume-tailoring`, `running-agile-delivery`, `ui-mockups`, `web-design-guidelines`, `working-with-atlassian`, and `writing-work-items`), installed once into this directory and not copied into Cursor `skills/` or the OpenCode config `skills/` directory, plus personal skills from `profiles/personal/skills/` when the selected AGENTS profile is `personal-default` or `personal-context-improved`. The installer replaces those managed names here. It preserves and reports all 29 current Hive-bundled names and retired names here too. Current Hive names are conflicts with Hive materialization; retired names, including the four legacy aliases listed above, are unversioned. Other skills are left alone and are not reported. Override the destination with `AGENTS_SKILLS_DIR`. Tests and other installer runs that keep the real `$HOME` must set this to a temp directory so they do not mutate `~/.agents/skills`.
- `commands/`: non-Hive prompt-backed commands packaged under `.apm/prompts/` (`interview-drill-down`, `planning-prompt`, `reflect`)
- `agents/`: installed only when this repository packages standalone Opencode agents

If those target paths already exist, the installer writes a timestamped backup under `<target>/.backup/` before replacing managed files. In `skills/` it replaces the OpenCode-local skill. A shared canonical name, Hive-owned name, Hive-bundled skill, or retired OpenCode-local skill already in that directory is left in place. In `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}`, it installs the fifteen shared canonical skills once for both Cursor and OpenCode, including `connecting-atlassian-tools`, `managing-work-in-jira`, and `working-with-atlassian`. Those skills are not copied into Cursor `skills/` or the OpenCode config `skills/` directory. A Hive-bundled skill already in the agents skills directory, including a dangling symlink, is left in place and reported as a conflict with `Hive materialization`. Other skills there are left alone. Each conflict or unversioned skill is one stderr line, `decision needed: conflict: <existing-path> is outside the managed install path <managed-path>; left in place` or `decision needed: unversioned: <existing-path> is not packaged by this install; left in place`. The installer finishes plugins, commands, the optional bundle, and warnings, then exits 1 when any of those lines was printed. A clean install exits 0. Set `OPENCODE_AGENTS_MODE=skip` when you want to update the profile files but keep an existing `AGENTS.md` in place for a manual merge.

## Requirements

Base setup requires:

- `git`
- `curl`
- OpenCode v1 >= 1.18.30. This profile targets OpenCode v1 only. Ownership and skill inventory were checked against `oc-arkive` 5.2.0, the version `opencode.json` pins.
- `python3` (standard library only) for `scripts/install-profile.sh`, which uses it to merge `tui.json`
- OpenAI access for `openai/gpt-6.1-sol` and `openai/gpt-6.1-terra`, used by `agent_hive.json` and `opencode.json`
- the same OpenAI ChatGPT sign-in for `oc-multi-imagegen` image tools; its default Codex backend needs no separate image API key
- Railway CLI with auth installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it
- `uv` plus the draw.io desktop CLI when you want the packaged `drawio-skill` to generate or export diagrams; Graphviz (`dot`) is optional for auto-layout
- Node.js when you want `frontend-slides` PDF export or Vercel deploy helpers; `uv` when converting PPTX
- `ui-mockups` needs an exposed image generation or editing tool that accepts reference images; it names no specific tool and reports a missing one before generating. Its layout references use Pillow, its storyboard helper runs through `uv` (`--with pillow --with numpy`) and needs `fc-match` from fontconfig unless font file paths are passed, and studying a named reference site needs a browser tool. Its transition storyboards also need an `animate` skill installed separately (for example at `~/.agents/skills/animate/SKILL.md`); this repository does not install it.

The installer also copies `plugins/dcg-guard.js`. That plugin stays inactive until the `dcg` CLI is on `PATH`. Install Destructive Command Guard with:

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --easy-mode
```

See the upstream project: [Dicklesworthstone/destructive_command_guard](https://github.com/dicklesworthstone/destructive_command_guard). The plugin does not need extra Node packages; Opencode loads it from `plugins/` at startup.

Optional features require their own tools:

- `jq` for `scripts/enable-optional.sh`
- a Context7 API key in `secrets/context7` under the Opencode config directory for the optional `context7` MCP entry, and a Keenable API key in `secrets/keenable` for the optional `keenable` MCP (see [MCP API keys](#mcp-api-keys))
- `uvx` and optionally the `cymbal` CLI for the context-improved workflow
- `npx` (Node.js) for the optional `chrome-devtools` browser MCP
- the Railway CLI with a `railway login` session for the optional `railway` MCP
- an Atlassian Cloud account and a browser for the optional `atlassian` MCP's OAuth sign-in
- VS Code if you want the companion extension

Cursor prompt-level assets have a separate setup path. They are validated and installed by `./scripts/cursor-assets.sh` from the repository root, not by the Opencode profile installer. It requires `python3`, defaults to `${HOME}/.cursor`, accepts `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, and accepts semicolon-separated `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for dual installs. `CURSOR_INSTALL_IVAN_WRITING` accepts only unset/empty (opt-out) or exact `1` (opt-in). Opt-in installs the skill into the agents dir and writes `ivan-writing/.cursor-managed`. On opt-out, a copy that still has that marker is left in place, reported as unversioned, and the installer exits 1; a copy with no marker is left untouched and is not reported. The fifteen shared canonical skills install once into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` for both Cursor and OpenCode and are not copied into Cursor `skills/` or the OpenCode config `skills/` directory. A Hive-bundled skill (`humanizer`, `stop-design-slop`, `stop-slop`, `unslop`, `writing-for-agents`, `writing-for-humans`) found in the agents dir during a Cursor install is left in place and reported as a conflict with the Cursor config `skills/<name>` path where this repo installs that skill. Those six skills are installed only into the Cursor config `skills/` directory; `stop-design-slop` is Cursor-only here because `oc-arkive` supplies it to OpenCode. Retired names `consolidate-test-suites`, `root-cause-finder`, and `writing-policy` found in Cursor `skills/` (or `writing-policy` in the agents dir) are left in place and reported as unversioned. Findings from every `CURSOR_CONFIG_DIRS` target are collected, and the installer exits 1 once at the end when any decision line was printed. A clean install exits 0. See `CURSOR.md` for details.

Check the host with `opencode --version`. Install or upgrade Opencode if it is missing or older than 1.18.30, then rerun the version check before installing this profile:

```bash
curl -fsSL https://opencode.ai/install | bash
```

## Quick start

Fresh machine with the shared AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
./scripts/install-profile.sh --apply
opencode
```

Fresh machine with the sanitized personal-default AGENTS profile:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
opencode
```

Fresh machine with the context-improved AGENTS profile and overlay:

```bash
curl -fsSL https://opencode.ai/install | bash
git clone git@github.com:imarshallwidjaja/custom-opencode-configs.git
cd custom-opencode-configs
opencode auth login -p openai
./scripts/write-secret.sh context7
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh --apply
opencode
```

Where:

- the repository clone requires GitHub access to this repo
- `opencode auth login -p openai` opens the ChatGPT OAuth flow; the Hive roles, the compaction agents, and the default `oc-multi-imagegen` Codex backend all use that sign-in
- if Homebrew is available and you want the optional `cymbal` navigation CLI, run `brew install 1broseidon/tap/cymbal` separately
- the first `opencode` run downloads the three pinned plugins named in `opencode.json`
- start Opencode with a listener (`opencode --port 0`, or `opencode serve` plus `opencode attach`) when you want the `/magic-compact` commands; see [Base plugins](#base-plugins)

## Updating an existing install

Before updating the plugin or profile, run `opencode --version` and confirm OpenCode >= 1.18.30. Upgrade an older host with `curl -fsSL https://opencode.ai/install | bash` and rerun the version check. Then update this repository clone and rerun the installer against the same Opencode config directory:

```bash
git pull
./scripts/install-profile.sh --apply
```

Use the same profile environment variables the install should keep, for example:

```bash
git pull
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
```

Use `OPENCODE_AGENTS_MODE=skip` when the target already has a hand-maintained `AGENTS.md` that should stay as the base document for a manual merge:

```bash
git pull
OPENCODE_AGENTS_MODE=skip ./scripts/install-profile.sh --apply
```

Some notes:

- the installer replaces `opencode.json` with the base profile, which drops any optional bundle you enabled earlier. Reapply each one with `./scripts/enable-optional.sh <name>`; the `*-context-improved` profiles reapply `context-improved` themselves. `tui.json` is merged instead, so other TUI plugins and settings survive a reinstall
- this profile no longer reads the Context7 key from `CONTEXT7_API_KEY`. Before reinstalling or reapplying a Context7 bundle, move it into the target config directory: `printf '%s\n' "$CONTEXT7_API_KEY" | OPENCODE_CONFIG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}" ./scripts/write-secret.sh context7`. Remove the export from shell startup files, then `unset CONTEXT7_API_KEY` in the current shell
- restart every Opencode process that uses this config directory, including a long-lived `opencode serve`; Opencode reads config and plugins only at startup
- with a custom `OPENCODE_CONFIG_DIR`, Agent Hive still reads `$HOME/.config/opencode/agent_hive.json` (see [Target config directory](#target-config-directory))
- `curl -fsSL https://opencode.ai/install | bash` updates or installs the Opencode binary; it does not update this profile
- the plugin pins change only when this repository changes them; restart Opencode after installing the profile so it loads the pinned versions. If the Agent Hive command surface still matches an older release, remove the cached `oc-arkive` package according to the local Opencode cache layout before starting Opencode again
- after restart, verify the loaded plugin manifest or available Agent Hive commands match `oc-arkive` 5.2.0
- the installer writes timestamped backups under `<target>/.backup/` before replacing managed files
- prefer preserving an existing customized `AGENTS.md` when unsure, then merge the selected profile guidance manually

## Install options

### Target config directory

Install into the default Opencode config directory:

```bash
./scripts/install-profile.sh --apply
```

Install into a custom config directory:

```bash
OPENCODE_CONFIG_DIR=/path/to/opencode-config AGENTS_SKILLS_DIR=/path/to/agents-skills ./scripts/install-profile.sh --apply
```

Shared canonical skills default to `$HOME/.agents/skills`. Set `AGENTS_SKILLS_DIR` when the installer must not write that live directory.

Agent Hive reads its config only from `$HOME/.config/opencode/agent_hive.json`, whatever `OPENCODE_CONFIG_DIR` says, and writes a default file there when none exists. A custom-directory install copies `agent_hive.json` into the custom directory and warns that Hive will not read it. Every Opencode config on the machine shares the default-location Hive file. Before replacing it, review and back up an existing regular file. Resolve a symlink or other non-regular destination manually:

```bash
(
  set -e
  hive_dir="$HOME/.config/opencode"
  hive_config="$hive_dir/agent_hive.json"
  mkdir -p "$hive_dir"
  if [[ -L "$hive_config" || ( -e "$hive_config" && ! -f "$hive_config" ) ]]; then
    printf 'Refusing to replace %s: resolve the symlink or non-regular target manually.\n' "$hive_config" >&2
    exit 1
  fi
  if [[ -f "$hive_config" ]]; then
    less "$hive_config"  # review existing routing
    backup_dir="$(mktemp -d "$hive_dir/.hive-backup.XXXXXX")"
    cp "$hive_config" "$backup_dir/agent_hive.json"
  fi
  cp "${OPENCODE_CONFIG_DIR:?set OPENCODE_CONFIG_DIR}/agent_hive.json" "$hive_config"
)
```

Use this workflow only after deciding that the installed Hive routing should replace the shared destination.

### AGENTS profiles

The installer uses `profiles/agents/shared.md` by default. Select another profile with `OPENCODE_AGENTS_PROFILE`. All four profiles include request-over-skill defaults and source citations for skill-driven pauses in `Request And Skill Precedence`, and a stopping condition after acceptance and required verification gates in `Quality Gates`; preserve both sections when merging into an existing profile. See `profiles/agents/README.md` for the operating-policy details and `CURSOR.md` for the equivalent manually pasted Cursor Rules.

All four AGENTS profiles reference `unslop` for human-facing prose and prose handoffs. It owns conditional depth-skill routing and child-load requirements; `writing-for-humans` owns drafting, the finish pass, and durable naming. OpenCode loads Hive's copies of these skills, `writing-for-agents`, `stop-slop`, and `humanizer`. The installer preserves and reports their local shadows in both skill roots along with every other current Hive name. `writing-policy` is retired and preserved/reportable as unversioned. Cursor installs its own copies into the Cursor config `skills/` directory and leaves an agents-dir copy in place with a conflict line. A leftover in `~/.claude/skills` still shadows the Hive bundle and is not reported by either installer. `CURSOR.md` explains the pinned Cursor imports and host separation.

All four carry the shared current operating policy: workflow corrections, bounded verification and failure evidence, prerequisite-scoped delegation, runtime provenance, published-history preservation, and evidence-based self-improvement. Personal and context-improved additions stay confined to their respective variants. Machine-specific AWS configuration, home paths, and service names are excluded.

Available profiles:

- `shared`: portable default for shared machines and team use
- `personal-default`: shared baseline plus `ivan-writing` for technical/product prose to or as Ivan and other prose published, submitted, or sent as Ivan. Register does not imply personal voice; internal reports stay neutral unless requested. PR and review drafts require explicit operator selection of personal voice under `pr-writing`
- `shared-context-improved`: shared baseline plus routing rules for the optional context-improved toolchain
- `personal-context-improved`: personal-default plus the same context-improved routing rules

Install examples:

```bash
OPENCODE_AGENTS_PROFILE=personal-default ./scripts/install-profile.sh --apply
```

```bash
OPENCODE_AGENTS_PROFILE=shared-context-improved ./scripts/install-profile.sh --apply
```

```bash
OPENCODE_AGENTS_PROFILE=personal-context-improved ./scripts/install-profile.sh --apply
```

The two `*-context-improved` profiles require `jq`, `uvx`, and a non-blank `secrets/context7` file in the target Opencode config directory (see [MCP API keys](#mcp-api-keys)). The installer preflights those dependencies before changing anything and applies the matching `context-improved` overlay automatically.

All four profiles require the UI skill `impeccable` for matching interface work and `animate` for motion, transitions, or storyboards. Install those skills separately when needed; this repository does not install them automatically. Image work uses the selected tool's companion skill, such as the `oc-multi-imagegen` skill shipped by that plugin. Missing skills must be reported, and installing a missing tool or skill requires authorization. These work-specific requirements do not add prerequisites to a base install.

### Agent Hive config

The installer copies `profiles/base/agent_hive.json`, the sole canonical Hive config. Every Hive model, including the task-trace summarizer, is exactly `openai/gpt-6.1-sol` or `openai/gpt-6.1-terra`; the profile uses no `-fast` or `-ultrafast` variants and no other provider. Its `$schema` points at the `v5.2.0` tag of the Agent Hive schema. Confirm the target environment lists both models and the configured efforts with `opencode models openai --verbose --refresh`; `--refresh` reloads the catalog from models.dev; in testing, Opencode 1.19.0 without a cached catalog listed neither model. Listing does not prove inference access. The installer adds no credentials, local proxies, or provider shims. Personal `ivan-writing` and `impeccable` skill auto-loads stay out of the portable Hive config; the `personal-*` AGENTS profiles load `ivan-writing` conditionally instead.

Seat models:

- Terra (`openai/gpt-6.1-terra`): `scout-researcher` `low`; `forager-backup`, `forager-documents`, `forager-ui`, `forager-browser`, and `documentation-reviewer` `medium`; `adversarial-plan-reviewer`, `ui-reviewer`, `adversarial-approach-advisor`, and `ui-design-advisor` `high`; `adversarial-code-reviewer` and `adversarial-simplicity-reviewer` `max`.
- Sol (`openai/gpt-6.1-sol`): the task-trace summarizer `low`; `forager-worker`, `hive-helper`, `simplicity-reviewer`, and `hive-builder` `medium`; `hive-master`, `architect-planner`, `swarm-orchestrator`, `forager-investigator`, `forager-capable`, `plan-reviewer`, `code-reviewer`, and `approach-advisor` `high`; `forager-smart`, `approach-advisor-xhigh-reasoning`, and `adversarial-documentation-reviewer` `xhigh`; `vulnerability-reviewer` `max`.

Every effort is a native OpenAI catalog value for its model: Sol accepts `low`, `medium`, `high`, `xhigh`, and `max`, and Terra also accepts `none`. `tests/test-install-contracts.sh` rejects any other model or effort.

`forager-worker` is the default for a named implementation, fix, refactor, integration, or review remediation, including the diagnosis and verification needed to finish it. `forager-investigator` owns standalone diagnosis, experiments, and verify-only work, and auto-loads `verification`. Use `forager-capable` for a named change that depends on coupled invariants or subtle state or concurrency; if unsure, use `forager-worker`. `forager-smart` is for exceptional difficulty with a nameable reasoning obstacle, or a substantive dead end from a prior attempt. `forager-browser` derives from `forager-investigator` and operates websites through the configured browser tools. `scout-researcher` is the search agent; fan independent questions out in parallel. Plan and code review each have one first-pass role. Adversarial passes supplement that first pass when the risk calls for them: `adversarial-code-reviewer` when a change touches public contracts, persistence, authorization, concurrency, state transitions, destructive behavior, or other failure-sensitive logic, or when the first review leaves correctness risk unresolved; `adversarial-simplicity-reviewer` when a change introduces or expands abstractions, configuration, flags, adapters, validation layers, fallback paths, or branching, or is materially larger than the request needs. Routine, localized changes with focused verification skip the adversarial code pass. The `minimal-change` council group pairs `simplicity-reviewer` with `adversarial-simplicity-reviewer`. Every council member derives from a read-only base role; `council.excludedAgents` keeps oc-arkive's mutable roles, including `forager-investigator`, plus `forager-backup`. The planner, swarm, and builder load `background-delegation` alongside their orchestration skills; `forager-worker` and `forager-investigator` auto-load `verification`. Agent Hive may prepend built-in defaults before these configured additions. Only the document-focused roles (`forager-documents`, `documentation-reviewer`, and `adversarial-documentation-reviewer`) auto-load `unslop` together with `writing-for-humans`; `humanizer` and `stop-slop` load conditionally through `unslop`. `adversarial-documentation-reviewer` also retains `adversarial-review`. Other seats load `unslop` on demand from its skill description and the AGENTS profile references. `hive-helper` is hardcoded to no auto-loaded skills.

`forager-backup` is a last-resort failover for infrastructure faults: confirmed provider outages, exhausted quotas, or orchestration faults that stop every other Forager. It runs on Terra while the other Foragers run on Sol or Terra, all through the same OpenAI account. It can therefore cover a fault or quota limit that affects one model, but not an outage, sign-in failure, or quota limit on the whole OpenAI account. Recovering from an account-wide outage needs a second provider, which this portable profile does not configure.

This profile targets OpenCode v1 >= 1.18.30 only and pins `oc-arkive@5.2.0`. Ownership and skill inventory were checked against `oc-arkive` 5.2.0. Hive no longer configures research MCPs or bundles an `ast-grep` skill; `opencode.json` and the optional bundles supply operator-configured research MCPs independently of skill availability. Hive rejects `agent_hive.json` files containing the removed `disableMcps`, `sandbox`, `dockerImage`, or `persistentContainers` fields. A rejected Hive file falls back to defaults; agents, customAgents, council, and model routing from that file are lost, and repository and worktree tools can also fail with an invalid-config error. Replace or update `agent_hive.json` to remove those fields before restarting Opencode. The base Hive config already omits them.

### Differences from the maintainer's local config

The base payloads follow the maintainer's working Hive role descriptions, council groups, custom agents, and effort levels. They are not a byte copy of that local config. The portable profile differs on purpose:

- every Hive and compaction model is Sol or Terra on the `openai` provider; the local config also routes roles through other providers and `-fast`/`-ultrafast` variants
- plugins are pinned npm packages instead of local build paths, and the local-only authentication and proxy plugins are left out
- no `permission` block: the profile keeps Opencode's default permission policy instead of a blanket allow
- `ivan-writing` and `impeccable` are not auto-loaded by any Hive role
- `forager-investigator` explicitly auto-loads `verification`, and `council.excludedAgents` also lists `forager-investigator`
- optional MCPs are opt-in bundles; Context7 and Keenable read their API keys from `secrets/` files, Railway uses the `railway login` session, and Atlassian uses Opencode's OAuth sign-in; the Atlassian server is named `atlassian`, `ast_grep` runs through `uvx`, and `chrome-devtools` opens a visible browser window instead of running headless
- the `documentation-reviewer` description reads "treat the docs as a contract"

## VS Code companion extension

The Agent Hive / `oc-arkive` VS Code companion is distributed as a `.vsix` asset on each Agent Hive fork release. Install the asset from the `v5.2.0` release so it matches the pinned `oc-arkive@5.2.0` plugin; an extension from another release can use a different `.hive` lock protocol than the plugin:

- <https://github.com/imarshallwidjaja/agent-hive/releases/tag/v5.2.0>

Install it with the VS Code CLI:

```bash
curl -L -o vscode-arkive.vsix https://github.com/imarshallwidjaja/agent-hive/releases/download/v5.2.0/vscode-arkive.vsix
code --install-extension ./vscode-arkive.vsix
```

Use the extension for:

- reviewing Hive plan files and context files
- seeing feature and task status in the sidebar
- adding review comments while Opencode remains the execution harness

## Cursor prompt-level assets

This repository also ships a Cursor v1 asset bundle for prompt-level behavior. Its default parent Agent uses Hive-Builder-like ad-hoc orchestration with Cursor-native named subagents: non-trivial work is delegated, while the parent owns lane coordination, diff inspection, combined verification, review, synthesis, and integration. Planning uses Cursor's Plan mode or a plan you supply; the parent settles integration authority and history intent before placing a lane and treats a worktree as no Git authority. The bundle installs eight Cursor subagents (`approach-advisor`, `code-reviewer`, `forager`, `investigator`, `plan-reviewer`, `scout`, `simplicity-reviewer`, and `vulnerability-reviewer`), each with the shared capability contract and the pinned Engineering Judgment appended; eight Cursor-specific commands plus the three shared canonical commands `/interview-drill-down`, `/planning-prompt`, and `/reflect` from `.apm/prompts/` (eleven installed); and twenty-five managed Cursor skills into the selected Cursor config `skills/` directory. [CURSOR.md](CURSOR.md#maintainer-sync) lists the skills and source-to-Cursor mapping. Nineteen skills and Engineering Judgment are pinned to Agent Hive commit `bce587395000ebdb4d381d2ad183b2673b374065` (tag `v5.2.0`, package version 5.2.0), with per-file skill hashes in `vendor/oc-arkive/cursor-skills/provenance.json`. These source pins do not attest the build loaded by a live OpenCode process.

The Cursor helper installs the fifteen shared canonical skills listed above once into `${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}` for both hosts, then prints default-Agent Rules for Cursor Customize -> Rules -> User Rules. Paste the complete `print-rules` output again whenever it changes; the helper never edits Cursor settings. Cursor keeps its imported skills and local adapters separate from OpenCode's runtime. Each installed agent file carries the vendored Engineering Judgment because Cursor cannot load the plugin prompt directly. OpenCode receives Engineering Judgment from the installed plugin.

Delegation is a strong prompt policy, but Cursor routing is heuristic and not runtime-guaranteed. The parent has a bounded direct-work exception for coordination, setup, and trivial conversation. Bounded direct reads and cheap parent checks stay with the parent. Non-trivial implementation, test, debug, refactor, integration, and review stay delegated. Separate context does not isolate files in a shared checkout. Parallel writing lanes, including overlapping writers, each get their own git worktree or isolated project copy. One writer may use the shared checkout when no other writer is active. If a separate placement cannot be created, report the blocker. Do not put two writers in one checkout, even on disjoint paths.

The printed Rules (`.apm/cursor/rules/default-agent.md`) carry a `## Prose Policy` section with a short always-on draft, audit, fix loop for human-facing prose; `unslop` owns routing. Because User Rules do not reliably reach children, each of the eight agent definitions under `.apm/cursor/agents/` requires the child to load `unslop`, every installed agent file carries the capability contract (required skills by exact name, capability-based tool selection, and missing-capability reporting), and the `subagent-delegation` skill requires handoffs to restate the governing workspace, authority, required skills, artifact, audience, and voice.

`investigator` runs standalone diagnosis, reproduction, scoped temporary experiments, verify-only checks, and source or evidence assessment, and returns evidence without a product change; `forager` keeps implementation. Reviews stay source reviews unless an operator instruction covers a runtime exercise. Every subagent uses `model: inherit`; [CURSOR.md](CURSOR.md#models) explains how to select Sol 6.1 or Terra 6.1 and an effort in Cursor, because Cursor publishes no matching model IDs.

Cursor documents subagents, native isolation, skills, Rules, Plan mode, and worktrees, but this package is validated statically and the Cursor CLI is not installed on the maintainer host. Live Cursor behavior is unvalidated; the Rules ask the parent to confirm placements instead of assuming them.

Cursor v1 is not Agent Hive runtime parity. It has no Hive tools, state, task DAG, board, or worktree lifecycle, and it does not install `oc-arkive`, `opencode.json`, `agent_hive.json`, or an OpenCode `AGENTS.md` profile.

Prerequisites:

- run commands from this repository root
- `python3`
- Git and a local Agent Hive checkout containing the selected ref are required only for maintainer sync
- executable `scripts/cursor-assets.sh`
- default target `${HOME}/.cursor`, `CURSOR_CONFIG_DIR=/path/to/cursor-config` for one custom target, or `CURSOR_CONFIG_DIRS="/path/one;/path/two"` for multiple targets
- Railway CLI with auth installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it
- `uv` plus the draw.io desktop CLI when using `drawio-skill`; Graphviz (`dot`) is optional for auto-layout
- Node.js when using `frontend-slides` PDF export or Vercel deploy; `uv` when converting PPTX

Quick inspection flow:

```bash
./scripts/cursor-assets.sh validate
cursor_temp="$(mktemp -d)"
agents_temp="$(mktemp -d)"
CURSOR_CONFIG_DIR="$cursor_temp" AGENTS_SKILLS_DIR="$agents_temp" ./scripts/cursor-assets.sh install --dry-run
./scripts/cursor-assets.sh print-rules
```

Actual install:

```bash
./scripts/cursor-assets.sh validate
./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

Windows Cursor with WSL projects may need both the WSL config root and the Windows config root because Cursor can resolve file-based agents, commands, and skills differently for WSL workspaces. From WSL, use a dual install like this:

```bash
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install --dry-run
CURSOR_CONFIG_DIRS="$HOME/.cursor;/mnt/c/Users/<WindowsUser>/.cursor" ./scripts/cursor-assets.sh install
./scripts/cursor-assets.sh print-rules
```

After install, paste the printed Rules text into Cursor Customize -> Rules -> User Rules. When the vendored snapshot hash changes, rerun `print-rules` and repaste the complete output. User Rules apply to Agent Chat, not Inline Edit. Project `.cursor/rules/*.mdc` remains a separate opt-in mechanism and is not installed by this helper.

See `CURSOR.md` for the asset list, exclusions, verification steps, and the reason this repo uses a thin helper instead of claiming direct APM global Cursor deployment.

## Optional context-improved workflow

The context-improved workflow adds the local context and structural-search toolchain.

It enables:

- a local `ast_grep` MCP launched through `uvx`
- the bundled remote `context7` MCP entry, with its API key read from `secrets/context7`
- Scout navigation rules for `cymbal` and `ast-grep`

Prerequisites:

- `jq`
- `uvx` available on `PATH`
- a non-blank `secrets/context7` file in the Opencode config directory
- `cymbal` on `PATH` if you want that navigation tool available to agents

Install `cymbal` with Homebrew when you want that tool:

```bash
brew install 1broseidon/tap/cymbal
```

Enable the context-improved overlay after a plain install:

```bash
./scripts/enable-optional.sh context-improved
```

If you select `shared-context-improved` or `personal-context-improved` during install, `scripts/install-profile.sh` applies this overlay automatically after checking the same prerequisites.

`cymbal` remains optional. When it is on `PATH`, `scripts/install-profile.sh` and the context-improved bundle both attempt to install its OpenCode hook into the selected `OPENCODE_CONFIG_DIR` with `cymbal hook install opencode --scope user`. That writes `plugins/cymbal-opencode.js`; this repository does not vendor that generated file. A hook failure warns without failing the install.

## Optional MCP bundles

Optional merge snippets live under `profiles/optional/`:

- `opencode.context-improved.json`
- `opencode.mcp-context7-enabled.json`
- `opencode.chrome-devtools.json`
- `opencode.keenable.json`
- `opencode.railway.json`
- `opencode.atlassian.json`

Apply a snippet with:

```bash
./scripts/enable-optional.sh chrome-devtools
```

The script validates prerequisites, backs up the current config file, and merges the chosen snippet into the active config.

`chrome-devtools` is the canonical interactive browser solution. It requires `npx` on `PATH` and launches `chrome-devtools-mcp@latest` with a non-absolute command, `--isolated=true` (a temporary browser profile that is deleted when the browser closes), and `--category-extensions=true` (browser-extension tools). It does not pass `--headless`, so Chrome opens a visible window.

`keenable` adds the remote Keenable web search and page-fetch MCP at `https://api.keenable.ai/mcp`. It sends the key from `secrets/keenable` as the `X-API-Key` header. Keenable also answers without a key on a shared public tier limited per IP address; this profile requires a key on purpose so agent traffic runs on your account's limits instead of that shared pool.

`railway` runs `railway mcp`, which connects to the Railway MCP server at `mcp.railway.com` and signs each request with the Railway CLI login. It needs the Railway CLI on `PATH` (5.44.0 or later for that connection) and a `railway login` session; `enable-optional.sh railway` refuses to merge without the CLI. The bundle stores no Railway credentials.

`atlassian` adds the remote Atlassian Rovo MCP server at `https://mcp.atlassian.com/v2/mcp` with no stored credentials. After enabling it, run `opencode mcp auth atlassian` and complete the OAuth sign-in in a browser; Opencode keeps the tokens. A site admin may need to allow the Rovo MCP app for your Atlassian Cloud site first.

Useful checks:

```bash
npx --version
jq '.mcp["chrome-devtools"]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/opencode.json"
```

### MCP API keys

The Context7 and Keenable bundles read API keys from files under `secrets/` in the Opencode config directory; the `railway` and `atlassian` bundles store no credentials and sign in through `railway login` and `opencode mcp auth atlassian` instead. The Context7 and Keenable snippets use `{file:secrets/<name>}`, which Opencode resolves relative to the directory that holds `opencode.json`, so a custom `OPENCODE_CONFIG_DIR` keeps its own keys. Opencode refuses to start when a referenced file is missing. For that reason the base `opencode.json` references no secret file, and `scripts/enable-optional.sh` and the context-improved install stop before changing any config unless the file exists, is readable, and is not blank. The installers never create, copy, or back up `secrets/`; only `scripts/write-secret.sh` writes there. This repository ignores `secrets/` so a key cannot be committed by accident.

| Bundle | Secret file | Sent as |
| --- | --- | --- |
| `context-improved`, `mcp-context7-enabled` | `secrets/context7` | `CONTEXT7_API_KEY` header |
| `keenable` | `secrets/keenable` | `X-API-Key` header |

Write a key file from the repository root:

```bash
./scripts/write-secret.sh context7
./scripts/write-secret.sh keenable
```

The script prompts without echoing the key, so the key stays out of shell history, and it runs under Bash whatever your login shell is. It writes to `secrets/<name>` under `${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}`, sets the `secrets/` directory to mode 700, writes the key to a new mode-600 file, and renames that file over any existing one, so rotating a key never leaves the new value in a file with looser permissions. It refuses a blank key and leaves the old file in place. When stdin is not a terminal, it reads the first line of stdin instead, for example to move a key out of an environment variable.

Check a key file the same way the installers do, without printing the key:

```bash
LC_ALL=C grep -q '[^[:space:]]' "${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/context7" && echo present
```

## Base plugins

The base `opencode.json` pins three published plugins. Opencode downloads each pinned version on first start; changing a version is a change to this repository:

- `oc-arkive@5.2.0` for Agent Hive
- `oc-multi-imagegen@1.0.0` for the `imagegen` image generation and editing tool
- `arkive-compact@1.3.0` for the `/magic-compact`, `/magic-trim`, `/magic-recover`, and `/magic-stats` commands; `tui.json` loads the same package into the TUI so a TUI showing a compacted session opens its successor

`oc-multi-imagegen` uses the Opencode ChatGPT sign-in through its default Codex backend, so it needs no separate image API key. The package ships its own `oc-multi-imagegen` skill for prompting, reference images, and checking results; this repository does not vendor a copy. Its OpenAI Images API and NanoGPT backends are optional and need their own keys; see the package's documentation.

`arkive-compact` notes:

- the commands talk to Opencode through its HTTP API, so start Opencode with a listener: `opencode --port 0` for the TUI, or `opencode serve --port <port>` and connect with `opencode attach`. A plain `opencode` start without `--port` has no listener, and the commands refuse with startup guidance
- `opencode.json` configures the hidden `magic-compact-summarizer` agent on `openai/gpt-6.1-sol` at `variant: low`. The plugin has no fallback model, so every per-turn summary uses this agent. `openai/gpt-6.1-sol` is one of the models whose protected reasoning handling Magic Compact has verified, so a summary request on Sol can be sent the protected reasoning that Sol turns recorded. Terra is not verified, and its protected reasoning stays unreadable to a Sol summarizer
- `/magic-trim --heuristic` and `/magic-compact --heuristic` are the path that needs no extra key. `--heuristic` skips task-aware retention: `/magic-trim --heuristic` makes no model call, and `/magic-compact --heuristic` still summarizes turns with the summarizer agent
- task-aware retention, the default without `--heuristic`, needs one decision-backend key in the environment of the Opencode server process: `TYPESAFE_API_KEY` for TypeSafe Jev (the default backend), or `MAGIC_COMPACT_OPENAI_DECISIONS_API_KEY` for the OpenAI Decisions API with `MAGIC_COMPACT_RETENTION_BACKEND=openai-decisions`. The OpenAI Decisions key is a separate plain OpenAI API key; the ChatGPT sign-in does not cover it. This profile stores neither key
- the plugin's own decision-backend models are set inside the package; this profile configures only the summarizer agent

The installer also copies `plugins/dcg-guard.js`, which Opencode auto-loads from the config plugins directory. It intercepts `bash` tool calls when `dcg` is on `PATH`, and is a no-op when `dcg` is missing.

It also copies `plugins/shell-agents.js`. Opencode already attaches a nested `AGENTS.md` when the `read` tool opens a file below it. This plugin does the same for `bash`: when a command's working directory is a subdirectory of the project, it appends every non-empty `AGENTS.md` between that directory and the project root (the root file is excluded because Opencode loads it natively) as a system reminder on the command output. It skips any file already visible in the system prompt or in earlier tool output that compaction has not removed, and it applies the same deduplication to `read` reminders. Symlinks that resolve outside the project are ignored. If loading fails, the command output gets a short diagnostic reminder instead of failing the tool call. It uses Opencode's `experimental.chat.messages.transform` and `experimental.chat.system.transform` hooks, so an Opencode upgrade that changes those hooks can break it.

The same file also carries an OpenCode 2 plugin; OpenCode 1 loads its `server` function and OpenCode 2 loads its `setup` function. On OpenCode 2 it covers the `shell` tool only: after a shell command returns, including one moved to the background, it appends the same nested `AGENTS.md` files, resolved from the command's `workdir` relative to the session directory, to the output the model sees next. Each file is wrapped in a `<shell-agents>` frame that records its path and length, with every line of the file quoted as `> `. A file counts as already delivered only while its complete frame is still in the model's active context, so a file that compaction removed or truncated is attached again on the next shell command. Native OpenCode 2 `read` keeps its own `AGENTS.md` handling, so the model can see one copy from `read` and one from a shell command. The plugin was tested in containers on OpenCode 1.18.30 and 2.0.26 with a scripted provider in place of a model, which checks what it attaches but not whether a real model follows those files. The rest of this profile still targets OpenCode 1, so this does not make the profile OpenCode 2 compatible. Check a different OpenCode 2 release before relying on it.

OpenCode 1 loads plugins only at startup, so after installing or updating either plugin, restart every running Opencode process that uses this config directory, including a long-lived `opencode serve`. OpenCode 2.0.26 watches the config directory and reloaded an updated `shell-agents.js` without a restart in testing; a change outside what it watches, such as an updated plugin dependency, may still need one. To check the plugin from this repository, run `bun test tests/shell-agents.test.js`; it needs Bun on `PATH` but no packages. Those tests run the plugin against stand-ins for both hosts, not against a real OpenCode process.

No credentials are embedded in this repository.

## Prompt-backed commands

This profile ships three non-Hive prompt-backed commands from `.apm/prompts/`:

- `interview-drill-down`
- `planning-prompt`
- `reflect`

`.apm/prompts/reflect.prompt.md` is the only tracked `/reflect` source for both Opencode and Cursor. It reviews the current session for durable learnings, keeps provisional cross-project workflow and personification preferences in the user's existing scratchpad, and promotes them to global instructions only after repeated evidence and explicit operator approval. In Cursor, it can also return an approved `cursor-user-rules:manual` change for manual paste when the current User Rules text was supplied or visible; it never claims to read or edit Cursor Settings. The prompt contains no user-specific paths or fixed personal preferences.

Hive workflow commands still come from the published `oc-arkive` plugin, including `/interview`, `/implementation-brief`, `/hive-plan`, `/approve-sync-plan`, `/start-execution`, `/council-directive`, `/council`, and `/compact-summary`. Do not keep local copies of those Hive-owned command files in the Opencode config directory.

During install, `scripts/install-profile.sh` copies `.apm/prompts/*.prompt.md` into `commands/` and removes the old profile-managed Hive command names from the target `commands/` directory after backing that directory up. It removes only these Hive-owned legacy names:

- `approve-sync-plan`
- `compact-summary`
- `council-directive`
- `council`
- `hive-plan`
- `implementation-planning-prompt`
- `interview`
- `start-execution`

All sixteen `.apm/skills/` trees remain packaged: fifteen shared skills plus OpenCode-local `writing-skills`. Third-party snapshots such as `web-design-guidelines`, `react-best-practices`, `drawio-skill`, and `resume-tailoring` remain repository-managed snapshots; their external upstreams are not plugins managed by this profile. Separately installed third-party skills stay under their own installer or operator's control. A local-only skill is not automatically a candidate for this portable package. The `oc-multi-imagegen` skill ships with the `oc-multi-imagegen` plugin and owns image-tool operations; `ui-mockups` owns screen sets, viewport scale, layout references, storyboard composition, and measured deliverables.

Hive/`oc-arkive` owns worktrees, merge, and its 29 bundled skills. The OpenCode installer classifies those names in `HIVE_BUNDLED_SKILLS` and preserves/reports same-name copies in both skill roots. Legacy Hive aliases and other retired OpenCode names remain preserved/reportable as unversioned. Cursor's imported skills and local adapters stay intentionally separate under `.apm/cursor/skills/`; their ownership and provenance are documented in [CURSOR.md](CURSOR.md#maintainer-sync). A leftover in `~/.claude/skills` can still shadow Hive and is not reported by either installer. Other existing skill directories stay and are not reported. Personal OpenCode profiles install `ivan-writing` into the agents dir and leave a leftover OpenCode `skills/ivan-writing` in place as a conflict. When any decision line was printed, the installer exits 1 after the rest of the install finishes.

The Railway CLI, with auth, installs and maintains its own `use-railway` agent skill via `railway setup agent` / `railway skills`; this repository does not package or install it. `drawio-skill` needs `uv` plus draw.io, and `frontend-slides` needs Node.js/`uv` for export helpers; both are otherwise inert. `aero-design` (Aero-inspired direction for data-rich interfaces such as dashboards, analytics, and tables) and the three agile theory skills (`decomposing-work`, `writing-work-items`, `running-agile-delivery`) have no prerequisites. The optional personal `ivan-writing` skill is installed into the agents dir for personal OpenCode profiles, and for Cursor only when `CURSOR_INSTALL_IVAN_WRITING=1`.

Both hosts use `unslop` as the compact prose router. `writing-for-humans` remains the depth skill for substantial docs, plans, reports, reviews, and explanations; `writing-for-agents` covers agent-consumed instructions. `stop-slop` (cadence and structure) and `humanizer` (vocabulary, register, attribution, formatting tells, chat artefacts) load only for matching rewrite problems. The Cursor copy of `stop-design-slop` ships `scripts/contrast_check.py` next to `scripts/audit_ui.py` for computed WCAG contrast ratios (`python3 scripts/contrast_check.py "#FFFFFF" "#777777"`, or `--selftest`); both need only `python3`.

## Assisted setup

If you want another Opencode agent to perform the setup for a less technical operator, point it to `FOR-LLM-AGENTS.md` in this repository. That document covers both the Opencode profile setup and the separate Cursor prompt-level asset setup.

Copy-paste prompt:

```text
Use FOR-LLM-AGENTS.md in this repository as the source of truth. Interview me one decision at a time, recommend the safest default when I am unsure, run the setup commands for me, and verify the final Opencode config.
```

That document tells the agent which setup decisions are real, which files to read first, what commands to run, and what to verify at the end.
