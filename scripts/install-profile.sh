#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
AGENTS_PROFILE="${OPENCODE_AGENTS_PROFILE:-shared}"
AGENTS_SOURCE="${REPO_ROOT}/profiles/agents/${AGENTS_PROFILE}.md"
AGENTS_MODE="${OPENCODE_AGENTS_MODE:-install}"
AGENT_HIVE_SOURCE="${REPO_ROOT}/agent_hive.json"
ENABLE_OPTIONAL_SCRIPT="${SCRIPT_DIR}/enable-optional.sh"
LEGACY_PROMPT_COMMANDS=(
  approve-sync-plan
  compact-summary
  council-directive
  council
  hive-plan
  implementation-planning-prompt
  interview-drill-down
  interview
  planning-prompt
  start-execution
)

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

if [[ ! -f "${AGENTS_SOURCE}" ]]; then
  printf 'Unknown AGENTS profile: %s\n' "${AGENTS_PROFILE}" >&2
  printf 'Available profiles:\n' >&2
  while IFS= read -r profile_name; do
    printf '  %s\n' "${profile_name}" >&2
  done < <(list_agents_profiles)
  exit 1
fi

case "${AGENTS_MODE}" in
  install|skip)
    ;;
  *)
    printf 'Unknown OPENCODE_AGENTS_MODE: %s\n' "${AGENTS_MODE}" >&2
    printf 'Expected one of: install, skip\n' >&2
    exit 1
    ;;
esac

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
if [[ "${AGENTS_MODE}" == "install" ]]; then
  backup_path "${TARGET_DIR}/AGENTS.md"
fi
backup_path "${TARGET_DIR}/skills"
backup_path "${TARGET_DIR}/agents"
backup_path "${TARGET_DIR}/commands"

rm -rf -- "${TARGET_DIR}/skills"
mkdir -p "${TARGET_DIR}/skills" "${TARGET_DIR}/agents"

install -m 0644 "${REPO_ROOT}/opencode.json" "${TARGET_DIR}/opencode.json"
install -m 0644 "${AGENT_HIVE_SOURCE}" "${TARGET_DIR}/agent_hive.json"
if [[ "${AGENTS_MODE}" == "install" ]]; then
  install -m 0644 "${AGENTS_SOURCE}" "${TARGET_DIR}/AGENTS.md"
fi
cp -a "${REPO_ROOT}/.apm/skills/." "${TARGET_DIR}/skills/"
if [[ -d "${REPO_ROOT}/.apm/agents" ]]; then
  cp -a "${REPO_ROOT}/.apm/agents/." "${TARGET_DIR}/agents/"
fi

shopt -s nullglob
prompt_files=("${REPO_ROOT}"/.apm/prompts/*.prompt.md)
if (( ${#prompt_files[@]} > 0 || ${#LEGACY_PROMPT_COMMANDS[@]} > 0 )); then
  mkdir -p "${TARGET_DIR}/commands"
fi
for prompt_name in "${LEGACY_PROMPT_COMMANDS[@]}"; do
  rm -f "${TARGET_DIR}/commands/${prompt_name}.md"
done
for prompt_file in "${prompt_files[@]}"; do
  prompt_name="$(basename "${prompt_file}" ".prompt.md")"
  install -m 0644 "${prompt_file}" "${TARGET_DIR}/commands/${prompt_name}.md"
done

if profile_needs_context_improved; then
  OPENCODE_CONFIG_DIR="${TARGET_DIR}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 "${ENABLE_OPTIONAL_SCRIPT}" context-improved
fi

printf 'Installed Opencode profile into %s\n' "${TARGET_DIR}"
if [[ "${AGENTS_MODE}" == "install" ]]; then
  printf 'Installed AGENTS profile: %s\n' "${AGENTS_PROFILE}"
else
  printf 'Skipped AGENTS.md replacement; selected profile for manual merge: %s\n' "${AGENTS_PROFILE}"
fi
printf 'Installed canonical Agent Hive config\n'
if profile_needs_context_improved; then
  printf 'Auto-applied optional bundle: context-improved\n'
fi
if [[ -n "${BACKUP_DIR}" ]]; then
  printf 'Backed up replaced config into %s\n' "${BACKUP_DIR}"
fi
