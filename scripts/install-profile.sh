#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
AGENTS_PROFILE="${OPENCODE_AGENTS_PROFILE:-shared}"
AGENTS_SOURCE="${REPO_ROOT}/profiles/agents/${AGENTS_PROFILE}.md"
AGENT_HIVE_PROFILE="${OPENCODE_AGENT_HIVE_PROFILE:-default}"
if [[ "${AGENT_HIVE_PROFILE}" == "default" ]]; then
  AGENT_HIVE_SOURCE="${REPO_ROOT}/agent_hive.json"
else
  AGENT_HIVE_SOURCE="${REPO_ROOT}/profiles/agent-hive/${AGENT_HIVE_PROFILE}.json"
fi
ENABLE_OPTIONAL_SCRIPT="${SCRIPT_DIR}/enable-optional.sh"

check_command() {
  local binary="$1"
  if ! command -v "${binary}" >/dev/null 2>&1; then
    printf 'Missing prerequisite on PATH: %s\n' "${binary}" >&2
    exit 1
  fi
}

profile_needs_context_improved() {
  case "${AGENTS_PROFILE}" in
    shared-context-improved|personal-context-improved)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

preflight_context_improved() {
  check_command jq
  check_command context-mode
  check_command uvx
  if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
    printf 'CONTEXT7_API_KEY is not set. It is required for %s.\n' "${AGENTS_PROFILE}" >&2
    exit 1
  fi
}

list_agents_profiles() {
  local profile_file
  for profile_file in "${REPO_ROOT}"/profiles/agents/*.md; do
    basename "${profile_file}" ".md"
  done | sort
}

list_agent_hive_profiles() {
  printf 'default\n'
  local profile_file
  for profile_file in "${REPO_ROOT}"/profiles/agent-hive/*.json; do
    [[ -e "${profile_file}" ]] || continue
    basename "${profile_file}" ".json"
  done | sort
}

if [[ ! -f "${AGENTS_SOURCE}" ]]; then
  printf 'Unknown AGENTS profile: %s\n' "${AGENTS_PROFILE}" >&2
  printf 'Available profiles:\n' >&2
  while IFS= read -r profile_name; do
    printf '  %s\n' "${profile_name}" >&2
  done < <(list_agents_profiles)
  exit 1
fi

if [[ ! -f "${AGENT_HIVE_SOURCE}" ]]; then
  printf 'Unknown Agent Hive profile: %s\n' "${AGENT_HIVE_PROFILE}" >&2
  printf 'Available profiles:\n' >&2
  while IFS= read -r profile_name; do
    printf '  %s\n' "${profile_name}" >&2
  done < <(list_agent_hive_profiles)
  exit 1
fi

if profile_needs_context_improved; then
  preflight_context_improved
fi

BACKUP_DIR=""

backup_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    if [[ -z "${BACKUP_DIR}" ]]; then
      BACKUP_DIR="${TARGET_DIR}/.backup/$(date +%Y%m%d-%H%M%S)"
      mkdir -p "${BACKUP_DIR}"
    fi
    cp -a "${path}" "${BACKUP_DIR}/$(basename "${path}")"
  fi
}

mkdir -p "${TARGET_DIR}"

backup_path "${TARGET_DIR}/opencode.json"
backup_path "${TARGET_DIR}/agent_hive.json"
backup_path "${TARGET_DIR}/AGENTS.md"
backup_path "${TARGET_DIR}/skills"
backup_path "${TARGET_DIR}/agents"
backup_path "${TARGET_DIR}/commands"

mkdir -p "${TARGET_DIR}/skills" "${TARGET_DIR}/agents" "${TARGET_DIR}/commands"

install -m 0644 "${REPO_ROOT}/opencode.json" "${TARGET_DIR}/opencode.json"
install -m 0644 "${AGENT_HIVE_SOURCE}" "${TARGET_DIR}/agent_hive.json"
install -m 0644 "${AGENTS_SOURCE}" "${TARGET_DIR}/AGENTS.md"
cp -a "${REPO_ROOT}/.apm/skills/." "${TARGET_DIR}/skills/"
cp -a "${REPO_ROOT}/.apm/agents/." "${TARGET_DIR}/agents/"

shopt -s nullglob
for prompt_file in "${REPO_ROOT}"/.apm/prompts/*.prompt.md; do
  prompt_name="$(basename "${prompt_file}" ".prompt.md")"
  install -m 0644 "${prompt_file}" "${TARGET_DIR}/commands/${prompt_name}.md"
done

if profile_needs_context_improved; then
  OPENCODE_CONFIG_DIR="${TARGET_DIR}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 "${ENABLE_OPTIONAL_SCRIPT}" context-improved
fi

printf 'Installed Opencode profile into %s\n' "${TARGET_DIR}"
printf 'Installed AGENTS profile: %s\n' "${AGENTS_PROFILE}"
printf 'Installed Agent Hive profile: %s\n' "${AGENT_HIVE_PROFILE}"
if profile_needs_context_improved; then
  printf 'Auto-applied optional bundle: context-improved\n'
fi
if [[ -n "${BACKUP_DIR}" ]]; then
  printf 'Backed up replaced config into %s\n' "${BACKUP_DIR}"
fi
