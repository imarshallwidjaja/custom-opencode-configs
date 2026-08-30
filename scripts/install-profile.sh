#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${OPENCODE_CONFIG_DIR:-${HOME}/.config/opencode}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
AGENTS_PROFILE="${OPENCODE_AGENTS_PROFILE:-shared}"
OPENCODE_LOCAL_SKILLS=(
  context-mode
  writing-skills
  using-git-worktrees
  finishing-a-development-branch
  consolidate-test-suites
  root-cause-finder
)
SHARED_SKILLS=(
  cymbal
  drawio-skill
  frontend-slides
  hard-cut
  humanizer
  react-best-practices
  resume-tailoring
  stop-design-slop
  stop-slop
  use-railway
  web-design-guidelines
  writing-for-humans
)
HIVE_OWNED_SKILLS=(
  adversarial-review
  agents-md-mastery
  ast-grep
  background-delegation
  brainstorming
  code-reviewer
  dispatching-parallel-agents
  docker-mastery
  executing-plans
  grilling
  parallel-exploration
  systematic-debugging
  test-driven-development
  verification
  verification-before-completion
  verification-reviewer
  writing-plans
)
AGENTS_SOURCE="${REPO_ROOT}/profiles/agents/${AGENTS_PROFILE}.md"
AGENTS_MODE="${OPENCODE_AGENTS_MODE:-install}"
BASE_PAYLOAD_DIR="${REPO_ROOT}/profiles/base"
OPENCODE_SOURCE="${BASE_PAYLOAD_DIR}/opencode.json"
AGENT_HIVE_SOURCE="${BASE_PAYLOAD_DIR}/agent_hive.json"
PLUGIN_SOURCE="${BASE_PAYLOAD_DIR}/plugins/dcg-guard.js"
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
validate_skill_source "${REPO_ROOT}/.apm/skills/writing-for-humans" writing-for-humans ".apm/skills/writing-for-humans" "SKILL.md" "examples.md sources.md" || exit 1
case "${AGENTS_PROFILE}" in
  personal-default|personal-context-improved)
    validate_skill_source "${REPO_ROOT}/profiles/personal/skills/ivan-writing" ivan-writing "profiles/personal/skills/ivan-writing" "SKILL.md" "registers.md examples.md" || exit 1
    ;;
esac

# Pre-mutation source readability check
preflight_source_readable() {
  local file
  for file in "${OPENCODE_SOURCE}" "${AGENT_HIVE_SOURCE}" "${PLUGIN_SOURCE}"; do
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

backup_agents_skill() {
  local skill_name="$1"
  local path="${AGENTS_SKILLS_DIR}/${skill_name}"
  if [[ -e "${path}" ]]; then
    if [[ -z "${BACKUP_DIR}" ]]; then
      BACKUP_DIR="${TARGET_DIR}/.backup/$(date +%Y%m%d-%H%M%S)"
      mkdir -p "${BACKUP_DIR}"
    fi
    mkdir -p "${BACKUP_DIR}/agents-skills"
    cp -a "${path}" "${BACKUP_DIR}/agents-skills/${skill_name}"
  fi
}

same_resolved_path() {
  local left right
  left="$(realpath -m -- "$1")"
  right="$(realpath -m -- "$2")"
  [[ "${left}" == "${right}" ]]
}

abort_if_agents_skills_aliased() {
  local other="$1"
  local label="$2"
  if same_resolved_path "${AGENTS_SKILLS_DIR}" "${other}"; then
    printf 'ERROR: AGENTS_SKILLS_DIR resolves to the same directory as %s (%s)\n' "${label}" "${other}" >&2
    exit 1
  fi
}

preflight_agents_skills_dir() {
  local dir="${AGENTS_SKILLS_DIR}"
  local parent
  if [[ -e "${dir}" || -L "${dir}" ]]; then
    if [[ -L "${dir}" || ! -d "${dir}" ]]; then
      printf 'ERROR: AGENTS_SKILLS_DIR exists and is not a directory: %s\n' "${dir}" >&2
      exit 1
    fi
    if [[ ! -w "${dir}" || ! -x "${dir}" ]]; then
      printf 'ERROR: AGENTS_SKILLS_DIR is not writable/traversable: %s\n' "${dir}" >&2
      exit 1
    fi
    return 0
  fi
  parent="${dir}"
  while [[ ! -e "${parent}" && ! -L "${parent}" && "${parent}" != "/" ]]; do
    parent="$(dirname "${parent}")"
  done
  if [[ ! -d "${parent}" || ! -w "${parent}" || ! -x "${parent}" ]]; then
    printf 'ERROR: cannot create AGENTS_SKILLS_DIR: %s\n' "${dir}" >&2
    exit 1
  fi
}

abort_if_agents_skills_aliased "${TARGET_DIR}" "OpenCode TARGET_DIR"
abort_if_agents_skills_aliased "${TARGET_DIR}/skills" "OpenCode TARGET_DIR/skills"
preflight_agents_skills_dir

mkdir -p "${TARGET_DIR}"

backup_path "${TARGET_DIR}/opencode.json"
backup_path "${TARGET_DIR}/agent_hive.json"
backup_path "${TARGET_DIR}/plugins/dcg-guard.js"
if [[ "${AGENTS_MODE}" == "install" ]]; then
  backup_path "${TARGET_DIR}/AGENTS.md"
fi
backup_path "${TARGET_DIR}/skills"
backup_path "${TARGET_DIR}/agents"
backup_path "${TARGET_DIR}/commands"

mkdir -p "${TARGET_DIR}/skills" "${TARGET_DIR}/agents" "${AGENTS_SKILLS_DIR}"

install -m 0644 "${OPENCODE_SOURCE}" "${TARGET_DIR}/opencode.json"
install -m 0644 "${AGENT_HIVE_SOURCE}" "${TARGET_DIR}/agent_hive.json"
mkdir -p "${TARGET_DIR}/plugins"
install -m 0644 "${PLUGIN_SOURCE}" "${TARGET_DIR}/plugins/dcg-guard.js"
if [[ "${AGENTS_MODE}" == "install" ]]; then
  install -m 0644 "${AGENTS_SOURCE}" "${TARGET_DIR}/AGENTS.md"
fi
for skill_name in "${OPENCODE_LOCAL_SKILLS[@]}"; do
  skill_source="${REPO_ROOT}/.apm/skills/${skill_name}"
  if [[ -L "${skill_source}" || ! -d "${skill_source}" ]]; then
    printf 'ERROR: missing OpenCode-local skill source: %s\n' "${skill_source}" >&2
    exit 1
  fi
  rm -rf -- "${TARGET_DIR}/skills/${skill_name}"
  cp -a "${skill_source}" "${TARGET_DIR}/skills/${skill_name}"
done
for skill_name in "${SHARED_SKILLS[@]}"; do
  skill_source="${REPO_ROOT}/.apm/skills/${skill_name}"
  if [[ -L "${skill_source}" || ! -d "${skill_source}" ]]; then
    printf 'ERROR: missing shared skill source: %s\n' "${skill_source}" >&2
    exit 1
  fi
  if [[ -e "${AGENTS_SKILLS_DIR}/${skill_name}" ]]; then
    backup_agents_skill "${skill_name}"
  fi
  rm -rf -- "${AGENTS_SKILLS_DIR}/${skill_name}"
  cp -a "${skill_source}" "${AGENTS_SKILLS_DIR}/${skill_name}"
  rm -rf -- "${TARGET_DIR}/skills/${skill_name}"
done
for skill_name in "${HIVE_OWNED_SKILLS[@]}"; do
  rm -rf -- "${TARGET_DIR}/skills/${skill_name}"
done
if [[ -d "${REPO_ROOT}/.apm/agents" ]]; then
  cp -a "${REPO_ROOT}/.apm/agents/." "${TARGET_DIR}/agents/"
fi
case "${AGENTS_PROFILE}" in
  personal-default|personal-context-improved)
    personal_skills="${REPO_ROOT}/profiles/personal/skills"
    if [[ -d "${personal_skills}" ]]; then
      for personal_entry in "${personal_skills}"/*; do
        [[ -e "${personal_entry}" ]] || continue
        personal_name="$(basename "${personal_entry}")"
        if [[ -e "${AGENTS_SKILLS_DIR}/${personal_name}" ]]; then
          backup_agents_skill "${personal_name}"
        fi
        rm -rf -- "${AGENTS_SKILLS_DIR}/${personal_name}"
        cp -a "${personal_entry}" "${AGENTS_SKILLS_DIR}/${personal_name}"
        rm -rf -- "${TARGET_DIR}/skills/${personal_name}"
      done
    fi
    ;;
esac

shopt -s nullglob
if (( ${#LEGACY_PROMPT_COMMANDS[@]} > 0 )); then
  mkdir -p "${TARGET_DIR}/commands"
fi
for prompt_name in "${LEGACY_PROMPT_COMMANDS[@]}"; do
  rm -f "${TARGET_DIR}/commands/${prompt_name}.md"
done
for prompt_file in "${REPO_ROOT}"/.apm/prompts/*.prompt.md; do
  mkdir -p "${TARGET_DIR}/commands"
  prompt_name="$(basename "${prompt_file}" ".prompt.md")"
  install -m 0644 "${prompt_file}" "${TARGET_DIR}/commands/${prompt_name}.md"
done

if profile_needs_context_improved; then
  OPENCODE_CONFIG_DIR="${TARGET_DIR}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 "${ENABLE_OPTIONAL_SCRIPT}" context-improved
fi

if command -v cymbal >/dev/null 2>&1; then
  if ! OPENCODE_CONFIG_DIR="${TARGET_DIR}" cymbal hook install opencode --scope user; then
    printf 'Warning: failed to install optional Cymbal OpenCode hook.\n' >&2
  fi
fi

if ! command -v dcg >/dev/null 2>&1; then
  printf 'Warning: dcg is not on PATH. The installed dcg-guard plugin stays inactive until Destructive Command Guard is installed.\n' >&2
  printf '%s\n' 'Install: curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh?$(date +%s)" | bash -s -- --easy-mode' >&2
fi

printf 'Installed Opencode profile into %s\n' "${TARGET_DIR}"
printf 'Installed shared skills into %s\n' "${AGENTS_SKILLS_DIR}"
if [[ "${AGENTS_MODE}" == "install" ]]; then
  printf 'Installed AGENTS profile: %s\n' "${AGENTS_PROFILE}"
else
  printf 'Skipped AGENTS.md replacement; selected profile for manual merge: %s\n' "${AGENTS_PROFILE}"
fi
printf 'Installed canonical Agent Hive config\n'
printf 'Installed dcg-guard plugin\n'
if profile_needs_context_improved; then
  printf 'Auto-applied optional bundle: context-improved\n'
fi
if [[ -n "${BACKUP_DIR}" ]]; then
  printf 'Backed up replaced config into %s\n' "${BACKUP_DIR}"
fi
