#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
TARGET_JSON="${TARGET_DIR}/opencode.json"
SNIPPET_NAME="${1:-}"

usage() {
  printf 'Usage: %s <snippet-name>\n' "$(basename "$0")" >&2
  printf 'Available snippets:\n' >&2
  for snippet_file in "${REPO_ROOT}"/profiles/optional/opencode.*.json; do
    basename "${snippet_file}" | sed 's/^opencode\.\(.*\)\.json$/  \1/' >&2
  done
}

if [[ -z "${SNIPPET_NAME}" ]]; then
  usage
  exit 1
fi

SNIPPET_FILE="${REPO_ROOT}/profiles/optional/opencode.${SNIPPET_NAME}.json"
if [[ ! -f "${SNIPPET_FILE}" ]]; then
  printf 'Unknown snippet: %s\n' "${SNIPPET_NAME}" >&2
  usage
  exit 1
fi

if [[ ! -f "${TARGET_JSON}" ]]; then
  printf 'Target config not found: %s\n' "${TARGET_JSON}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq is required to merge optional snippets.\n' >&2
  exit 1
fi

check_command() {
  local binary="$1"
  if ! command -v "${binary}" >/dev/null 2>&1; then
    printf 'Missing prerequisite on PATH: %s\n' "${binary}" >&2
    exit 1
  fi
}

case "${SNIPPET_NAME}" in
  context-improved)
    check_command context-mode
    check_command uvx
    if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
      printf 'CONTEXT7_API_KEY is not set.\n' >&2
      exit 1
    fi
    ;;
  lsp-all-recommended)
    check_command marksman
    check_command vtsls
    check_command ruff
    check_command ty
    ;;
  lsp-markdown-typescript)
    check_command marksman
    check_command vtsls
    ;;
  lsp-python)
    check_command ruff
    check_command ty
    ;;
  mcp-context7-enabled)
    if [[ -z "${CONTEXT7_API_KEY:-}" ]]; then
      printf 'CONTEXT7_API_KEY is not set.\n' >&2
      exit 1
    fi
    ;;
esac

BACKUP_DIR="${TARGET_DIR}/.backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "${BACKUP_DIR}"
cp -a "${TARGET_JSON}" "${BACKUP_DIR}/opencode.json"

tmpfile="$(mktemp)"
jq -s '.[0] * .[1]' "${TARGET_JSON}" "${SNIPPET_FILE}" > "${tmpfile}"
install -m 0644 "${tmpfile}" "${TARGET_JSON}"
rm -f "${tmpfile}"

printf 'Applied %s to %s\n' "${SNIPPET_NAME}" "${TARGET_JSON}"
printf 'Backed up the previous config to %s\n' "${BACKUP_DIR}"
