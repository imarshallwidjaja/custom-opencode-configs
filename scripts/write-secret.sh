#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s <name>\n' "$(basename "$0")" >&2
  printf 'Writes an API key to ${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode}/secrets/<name> with mode 600.\n' >&2
  printf 'Reads the key without echo from a terminal, or from the first line of standard input.\n' >&2
}

if (( $# != 1 )); then
  usage
  exit 2
fi
NAME="$1"
if [[ ! "${NAME}" =~ ^[a-z0-9-]+$ ]]; then
  printf 'Secret name must match [a-z0-9-]+: %s\n' "${NAME}" >&2
  exit 2
fi

SECRETS_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}/secrets"
SECRET_PATH="${SECRETS_DIR}/${NAME}"

key=""
if [[ -t 0 ]]; then
  read -rs -p "API key for secrets/${NAME}: " key || true
  printf '\n' >&2
else
  IFS= read -r key || true
fi
if [[ -z "${key//[[:space:]]/}" ]]; then
  printf 'No key entered; %s was not changed.\n' "${SECRET_PATH}" >&2
  exit 1
fi

umask 077
mkdir -p "${SECRETS_DIR}"
chmod 700 "${SECRETS_DIR}"
if [[ -d "${SECRET_PATH}" || ( -e "${SECRET_PATH}" && ! -f "${SECRET_PATH}" && ! -L "${SECRET_PATH}" ) ]]; then
  printf 'Secret target is not a file: %s\n' "${SECRET_PATH}" >&2
  exit 1
fi
# Write a fresh 0600 file and rename it over the old one, so rotating a key
# never puts the new value into an existing inode with looser permissions.
tmp="$(mktemp "${SECRETS_DIR}/.${NAME}.XXXXXX")"
trap 'rm -f "${tmp}"' EXIT
chmod 600 "${tmp}"
printf '%s\n' "${key}" > "${tmp}"
mv -f "${tmp}" "${SECRET_PATH}"
trap - EXIT
printf 'Wrote %s (mode 600)\n' "${SECRET_PATH}"
