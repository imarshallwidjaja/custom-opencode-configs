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
  interview
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

allowed_entry() {
  local candidate="$1"
  local allowed
  for allowed in $2; do
    if [[ "${candidate}" == "${allowed}" ]]; then
      return 0
    fi
  done
  return 1
}

validate_frontmatter_value() {
  local value="$1"
  local key="$2"
  local label="$3"
  local rest c

  case "${value}" in
    \"*|\'*)
      printf 'ERROR: %s/SKILL.md %s has quoted scalar: %s\n' "${label}" "${key}" "${value}" >&2
      return 1
      ;;
  esac

  case "${value}" in *\\*)
    printf 'ERROR: %s/SKILL.md %s contains backslash: %s\n' "${label}" "${key}" "${value}" >&2
    return 1
    ;;
  esac

  case "${value}" in
    ' '*)
      printf 'ERROR: %s/SKILL.md %s has leading whitespace: %s\n' "${label}" "${key}" "${value}" >&2
      return 1
      ;;
  esac

  case "${value}" in
    *' ')
      printf 'ERROR: %s/SKILL.md %s has trailing whitespace: %s\n' "${label}" "${key}" "${value}" >&2
      return 1
      ;;
  esac

  rest="${value#Use when}"
  if [[ "${rest}" != "${value}" ]]; then
    value="${rest}"
  fi

  case "${value}" in *": "*)
    printf 'ERROR: %s/SKILL.md %s contains unquoted colon-space sequence\n' "${label}" "${key}" >&2
    return 1
    ;;
  esac

  for c in '{' '}' '[' ']'; do
    case "${value}" in *"${c}"*)
      printf 'ERROR: %s/SKILL.md %s contains flow collection delimiter\n' "${label}" "${key}" >&2
      return 1
      ;;
  esac
  done

  case "${value}" in *"#"*)
    printf 'ERROR: %s/SKILL.md %s contains hash character\n' "${label}" "${key}" >&2
    return 1
    ;;
  esac

  return 0
}

validate_skill_frontmatter() {
  local skill_file="$1"
  local expected_name="$2"
  local label="$3"
  local first_line line actual_name="" description="" closed=0
  local name_seen=0 desc_seen=0

  {
    IFS= read -r first_line || true
    if [[ "${first_line}" != "---" ]]; then
      printf 'ERROR: %s/SKILL.md is missing opening --- frontmatter delimiter\n' "${label}" >&2
      return 1
    fi
    while IFS= read -r line; do
      case "${line}" in *$'\t'*)
        printf 'ERROR: %s/SKILL.md frontmatter contains tab\n' "${label}" >&2
        return 1
        ;;
      esac
      case "${line}" in
        ---)
          closed=1
          break
          ;;
        ---*)
          printf 'ERROR: %s/SKILL.md has invalid closing frontmatter delimiter: %s\n' "${label}" "${line}" >&2
          return 1
          ;;
        ' '*|$'\t'*)
          printf 'ERROR: %s/SKILL.md has indented continuation line: %s\n' "${label}" "${line}" >&2
          return 1
          ;;
        name:\ *)
          if [[ "${name_seen}" -eq 1 ]]; then
            printf 'ERROR: %s/SKILL.md has duplicate name key\n' "${label}" >&2
            return 1
          fi
          name_seen=1
          actual_name="${line#name: }"
          validate_frontmatter_value "${actual_name}" name "${label}" || return 1
          ;;
        description:\ *)
          if [[ "${desc_seen}" -eq 1 ]]; then
            printf 'ERROR: %s/SKILL.md has duplicate description key\n' "${label}" >&2
            return 1
          fi
          desc_seen=1
          description="${line#description: }"
          validate_frontmatter_value "${description}" description "${label}" || return 1
          ;;
        description:)
          if [[ "${desc_seen}" -eq 1 ]]; then
            printf 'ERROR: %s/SKILL.md has duplicate description key\n' "${label}" >&2
            return 1
          fi
          desc_seen=1
          description=""
          ;;
        ''|'#'*)
          ;;
        *)
          printf 'ERROR: %s/SKILL.md has unknown or malformed frontmatter line: %s\n' "${label}" "${line}" >&2
          return 1
          ;;
      esac
    done
  } < "${skill_file}"

  if [[ "${closed}" -ne 1 ]]; then
    printf 'ERROR: %s/SKILL.md has unterminated frontmatter\n' "${label}" >&2
    return 1
  fi
  if [[ "${actual_name}" != "${expected_name}" ]]; then
    printf 'ERROR: %s/SKILL.md frontmatter name is %s, expected %s\n' "${label}" "${actual_name:-<missing>}" "${expected_name}" >&2
    return 1
  fi
  if [[ -z "${description}" ]]; then
    printf 'ERROR: %s/SKILL.md has empty description\n' "${label}" >&2
    return 1
  fi
  case "${description}" in
    "Use when"*) ;;
    *)
      printf 'ERROR: %s/SKILL.md description must begin with "Use when"\n' "${label}" >&2
      return 1
      ;;
  esac
}

validate_reference_manifest() {
  local reference_dir="$1"
  local label="$2"
  local allowed_files="$3"
  local entry base required

  if [[ -L "${reference_dir}" || ! -d "${reference_dir}" ]]; then
    printf 'ERROR: %s/references must be a real directory\n' "${label}" >&2
    return 1
  fi
  for entry in "${reference_dir}"/* "${reference_dir}"/.*; do
    [[ -e "${entry}" || -L "${entry}" ]] || continue
    base="$(basename "${entry}")"
    [[ "${base}" == "." || "${base}" == ".." ]] && continue
    if [[ -L "${entry}" ]]; then
      printf 'ERROR: %s/references/%s is a symlink\n' "${label}" "${base}" >&2
      return 1
    fi
    if [[ ! -f "${entry}" ]] || ! allowed_entry "${base}" "${allowed_files}"; then
      printf 'ERROR: %s/references/%s is not in the source manifest\n' "${label}" "${base}" >&2
      return 1
    fi
    if [[ ! -r "${entry}" ]]; then
      printf 'ERROR: %s/references/%s is not readable\n' "${label}" "${base}" >&2
      return 1
    fi
  done
  for required in ${allowed_files}; do
    if [[ -L "${reference_dir}/${required}" || ! -f "${reference_dir}/${required}" ]]; then
      printf 'ERROR: %s/references/%s is missing or is not a regular file\n' "${label}" "${required}" >&2
      return 1
    fi
    if [[ ! -r "${reference_dir}/${required}" ]]; then
      printf 'ERROR: %s/references/%s is not readable\n' "${label}" "${required}" >&2
      return 1
    fi
  done
}

validate_skill_source() {
  local source="$1"
  local expected_name="$2"
  local label="$3"
  local allowed_root_files="$4"
  local allowed_reference_files="$5"
  local entry base required

  if [[ -L "${source}" || ! -d "${source}" ]]; then
    printf 'ERROR: %s must be a real directory\n' "${label}" >&2
    return 1
  fi
  if [[ ! -x "${source}" ]]; then
    printf 'ERROR: %s is not traversable\n' "${label}" >&2
    return 1
  fi
  for entry in "${source}"/* "${source}"/.*; do
    [[ -e "${entry}" || -L "${entry}" ]] || continue
    base="$(basename "${entry}")"
    [[ "${base}" == "." || "${base}" == ".." ]] && continue
    if [[ -L "${entry}" ]]; then
      printf 'ERROR: %s/%s is a symlink\n' "${label}" "${base}" >&2
      return 1
    fi
    if [[ -d "${entry}" ]]; then
      if [[ "${base}" != "references" ]]; then
        printf 'ERROR: %s/%s is not in the source manifest\n' "${label}" "${base}" >&2
        return 1
      fi
    elif [[ ! -f "${entry}" ]] || ! allowed_entry "${base}" "${allowed_root_files}"; then
      printf 'ERROR: %s/%s is not in the source manifest\n' "${label}" "${base}" >&2
      return 1
    else
      if [[ ! -r "${entry}" ]]; then
        printf 'ERROR: %s/%s is not readable\n' "${label}" "${base}" >&2
        return 1
      fi
    fi
  done
  for required in ${allowed_root_files}; do
    if [[ -L "${source}/${required}" || ! -f "${source}/${required}" ]]; then
      printf 'ERROR: %s/%s is missing or is not a regular file\n' "${label}" "${required}" >&2
      return 1
    fi
    if [[ ! -r "${source}/${required}" ]]; then
      printf 'ERROR: %s/%s is not readable\n' "${label}" "${required}" >&2
      return 1
    fi
  done
  validate_reference_manifest "${source}/references" "${label}" "${allowed_reference_files}" || return 1
  validate_skill_frontmatter "${source}/SKILL.md" "${expected_name}" "${label}" || return 1
}

validate_skill_source "${REPO_ROOT}/.apm/skills/humanizer" humanizer ".apm/skills/humanizer" "SKILL.md" "patterns.md" || exit 1
validate_skill_source "${REPO_ROOT}/.apm/skills/stop-slop" stop-slop ".apm/skills/stop-slop" "SKILL.md README.md LICENSE" "examples.md phrases.md structures.md" || exit 1
case "${AGENTS_PROFILE}" in
  personal-default|personal-context-improved)
    validate_skill_source "${REPO_ROOT}/profiles/personal/skills/ivan-writing" ivan-writing "profiles/personal/skills/ivan-writing" "SKILL.md" "registers.md examples.md" || exit 1
    ;;
esac

# Pre-mutation source readability check
preflight_source_readable() {
  local file
  for file in "${REPO_ROOT}/opencode.json" "${AGENT_HIVE_SOURCE}"; do
    if [[ ! -r "${file}" ]]; then
      printf 'ERROR: %s is not readable\n' "${file}" >&2
      exit 1
    fi
  done
  if [[ "${AGENTS_MODE}" == "install" && ! -r "${AGENTS_SOURCE}" ]]; then
    printf 'ERROR: %s is not readable\n' "${AGENTS_SOURCE}" >&2
    exit 1
  fi
}
preflight_source_readable

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
case "${AGENTS_PROFILE}" in
  personal-default|personal-context-improved)
    cp -a "${REPO_ROOT}/profiles/personal/skills/." "${TARGET_DIR}/skills/"
    ;;
esac

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
