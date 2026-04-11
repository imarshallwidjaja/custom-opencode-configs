#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"

mkdir -p "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}/skills" "${TARGET_DIR}/agents" "${TARGET_DIR}/commands"

install -m 0644 "${REPO_ROOT}/opencode.json" "${TARGET_DIR}/opencode.json"
install -m 0644 "${REPO_ROOT}/agent_hive.json" "${TARGET_DIR}/agent_hive.json"
install -m 0644 "${REPO_ROOT}/AGENTS.md" "${TARGET_DIR}/AGENTS.md"
cp -a "${REPO_ROOT}/.apm/skills/." "${TARGET_DIR}/skills/"
cp -a "${REPO_ROOT}/.apm/agents/." "${TARGET_DIR}/agents/"

shopt -s nullglob
for prompt_file in "${REPO_ROOT}"/.apm/prompts/*.prompt.md; do
  prompt_name="$(basename "${prompt_file}" ".prompt.md")"
  install -m 0644 "${prompt_file}" "${TARGET_DIR}/commands/${prompt_name}.md"
done

printf 'Installed Opencode profile into %s\n' "${TARGET_DIR}"
