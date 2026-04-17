#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
AGENTS_PROFILE="${OPENCODE_AGENTS_PROFILE:-shared}"
AGENTS_SOURCE="${REPO_ROOT}/profiles/agents/${AGENTS_PROFILE}.md"

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
install -m 0644 "${REPO_ROOT}/agent_hive.json" "${TARGET_DIR}/agent_hive.json"
install -m 0644 "${AGENTS_SOURCE}" "${TARGET_DIR}/AGENTS.md"
cp -a "${REPO_ROOT}/.apm/skills/." "${TARGET_DIR}/skills/"
cp -a "${REPO_ROOT}/.apm/agents/." "${TARGET_DIR}/agents/"

shopt -s nullglob
for prompt_file in "${REPO_ROOT}"/.apm/prompts/*.prompt.md; do
  prompt_name="$(basename "${prompt_file}" ".prompt.md")"
  install -m 0644 "${prompt_file}" "${TARGET_DIR}/commands/${prompt_name}.md"
done

printf 'Installed Opencode profile into %s\n' "${TARGET_DIR}"
printf 'Installed AGENTS profile: %s\n' "${AGENTS_PROFILE}"
if [[ -n "${BACKUP_DIR}" ]]; then
  printf 'Backed up replaced config into %s\n' "${BACKUP_DIR}"
fi
