# Agent Hive Profiles

This directory contains alternate full `agent_hive.json` profiles for `scripts/install-profile.sh`.

The repository root `agent_hive.json` is the default OpenAI plus `opencode-go` profile. Use these files when the target machine should run a different named model mix while keeping the same installed `opencode.json`, `AGENTS.md`, skills, agents, and commands.

All Agent Hive profiles share the same agent names, descriptions, and non-model settings. Profiles should only differ by `model` and `variant`; `temperature` is intentionally omitted. Each profile includes `plan-reviewer`, `code-reviewer`, `simplicity-reviewer`, `approach-advisor`, and `hive-builder` for newer `oc-arkive` builds.

## Profiles

### `openai-opencode-go.json`

Purpose: Uses non-fast OpenAI-hosted GPT models for the main Hive planning, orchestration, worker, and review roles, with `opencode-go/*` models for Scout, simple-worker, UI, and capable-research roles.

Use this when:

- OpenAI model access is available in Opencode
- the machine also has the `opencode-go/*` provider available
- you want the local working profile from `~/.config/opencode/agent_hive.json`

### `copilot-opencode-go.json`

Purpose: Uses GitHub Copilot-hosted GPT models for the main Hive planning, orchestration, worker, and review roles, with `opencode-go/*` models for Scout, simple-worker, UI, and capable-research roles.

Use this when:

- GitHub Copilot model access is available in Opencode
- the machine also has the `opencode-go/*` provider available
- you want the Copilot-provider equivalent of the default Agent Hive profile

## Install Selection

Install the default root `agent_hive.json` profile:

```bash
./scripts/install-profile.sh
```

Install the OpenAI plus `opencode-go` Agent Hive profile:

```bash
OPENCODE_AGENT_HIVE_PROFILE=openai-opencode-go ./scripts/install-profile.sh
```

Install the Copilot plus `opencode-go` Agent Hive profile:

```bash
OPENCODE_AGENT_HIVE_PROFILE=copilot-opencode-go ./scripts/install-profile.sh
```

Some notes:

- this selection only changes the installed `agent_hive.json`
- it does not add provider credentials, local provider shims, or plugin entries to `opencode.json`
- choose a profile only when the target Opencode environment can resolve every provider/model named in that profile
