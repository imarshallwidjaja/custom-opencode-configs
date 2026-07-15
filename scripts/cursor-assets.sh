#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TARGET_DIR="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"

AGENTS=(
  approach-advisor
  code-reviewer
  forager
  plan-reviewer
  scout
  simplicity-reviewer
)
COMMANDS=(
  compact-summary
  council-directive
  council
  implementation-brief
  interview
  interview-drill-down
  planning-prompt
)
SKILLS=(
  brainstorming
  consolidate-test-suites
  finishing-a-development-branch
  root-cause-finder
  subagent-delegation
  systematic-debugging
  test-driven-development
  use-railway
  using-git-worktrees
  verification
)

CANONICAL_SKILLS=(
  humanizer
  stop-slop
)

usage() {
  printf 'Usage:\n' >&2
  printf '  %s validate\n' "$(basename "$0")" >&2
  printf '  %s install [--dry-run]\n' "$(basename "$0")" >&2
  printf '  %s print-rules\n' "$(basename "$0")" >&2
  printf '\nInstall targets:\n' >&2
  printf '  CURSOR_CONFIG_DIR=/path/to/.cursor installs into one target.\n' >&2
  printf '  CURSOR_CONFIG_DIRS=/path/one;/path/two installs into multiple targets.\n' >&2
}

# Parse CURSOR_INSTALL_IVAN_WRITING at command boundary.
# Only unset/empty or exact "1" are accepted. All other values fail.
preflight_env() {
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    ''|1)
      return 0
      ;;
    *)
      printf 'ERROR: CURSOR_INSTALL_IVAN_WRITING=%s is not supported. Set to 1 to install, or unset/empty to skip.\n' "${CURSOR_INSTALL_IVAN_WRITING}" >&2
      exit 1
      ;;
  esac
}

source_root() {
  if [[ -d "${REPO_ROOT}/.apm/cursor" ]]; then
    printf '%s\n' "${REPO_ROOT}/.apm/cursor"
  elif [[ -d "${REPO_ROOT}/cursor-assets" ]]; then
    printf '%s\n' "${REPO_ROOT}/cursor-assets"
  else
    printf 'Cursor asset root not found. Expected .apm/cursor or cursor-assets.\n' >&2
    exit 1
  fi
}

check_python() {
  if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 is required for Cursor asset validation.\n' >&2
    exit 1
  fi
}

validate_assets() {
  local root="$1"
  check_python
  AGENT_NAMES="${AGENTS[*]}" COMMAND_NAMES="${COMMANDS[*]}" SKILL_NAMES="${SKILLS[*]}" python3 - "$root" "${REPO_ROOT}" "${CURSOR_INSTALL_IVAN_WRITING:-}" <<'PY'
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
install_personal = sys.argv[3] == '1'

expected_agents = set(os.environ['AGENT_NAMES'].split())
expected_commands = set(os.environ['COMMAND_NAMES'].split())
expected_skills = set(os.environ['SKILL_NAMES'].split())
excluded_commands = {
    'approve-sync-plan',
    'hive-plan',
    'implementation-planning-prompt',
    'start-execution',
}

forbidden_patterns = [
    (re.compile(r'\bhive_[A-Za-z0-9_]+\b'), 'Hive tool name'),
    (re.compile(r'\b(?:task|question|todowrite)\s*\('), 'OpenCode-only tool call'),
    (re.compile(r'\b(?:functions|multi_tool_use)\.[A-Za-z0-9_]+\b'), 'OpenCode tool namespace'),
    (re.compile(r'</?(?:tool_use|function_calls?|invoke|parameter)\b'), 'OpenCode XML tool-call syntax'),
    (re.compile(r'/(?:home|Users)/[A-Za-z0-9._-]+(?:/|\b)'), 'absolute home-directory path'),
    (re.compile(r'https?://(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(?::\d+)?\b'), 'local proxy URL'),
    (re.compile(r'\b(?:sk-(?:ant-|proj-)?[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})\b'), 'obvious secret'),
    (re.compile(r'-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'), 'private key'),
]

errors = []
text_cache = {}

def fail(message):
    errors.append(message)

def display(path):
    for base in (root, repo_root):
        try:
            relative = path.relative_to(base)
            return str(relative) if str(relative) != '.' else str(base)
        except ValueError:
            pass
    return str(path)

def read_text(path):
    if path in text_cache:
        return text_cache[path]
    try:
        text = path.read_bytes().decode('utf-8')
    except UnicodeDecodeError:
        fail(f'{display(path)} is not valid UTF-8')
        text = ''
    except OSError as error:
        fail(f'{display(path)} cannot be read: {error}')
        text = ''
    text_cache[path] = text
    return text

def parse_frontmatter(path, allowed_keys=None):
    text = read_text(path)
    lines = text.splitlines()
    if len(lines) < 3 or lines[0] != '---':
        fail(f'{display(path)} is missing YAML frontmatter')
        return {}
    end = None
    for index, line in enumerate(lines[1:], start=1):
        if line == '---':
            end = index
            break
        if line.startswith('---'):
            fail(f'{display(path)} has invalid closing frontmatter delimiter: {line}')
            return {}
    if end is None:
        fail(f'{display(path)} has unterminated YAML frontmatter')
        return {}
    data = {}
    seen_keys = set()
    for line in lines[1:end]:
        if '\t' in line:
            fail(f'{display(path)} has tab in frontmatter: {repr(line)}')
            continue
        stripped = line.strip()
        if not stripped or stripped.startswith('#'):
            continue
        if line.startswith(' ') or line.startswith('\t'):
            if allowed_keys is not None:
                fail(f'{display(path)} has indented continuation line: {repr(line)}')
            continue
        if ':' not in line:
            fail(f'{display(path)} has invalid frontmatter line: {line}')
            continue
        key, value = line.split(':', 1)
        key = key.strip()
        if not key:
            fail(f'{display(path)} has an empty frontmatter key')
            continue
        if key in seen_keys:
            fail(f'{display(path)} has duplicate frontmatter key: {key}')
        seen_keys.add(key)
        if allowed_keys is not None and key not in allowed_keys:
            fail(f'{display(path)} has unknown frontmatter key: {key}')
            continue
        val = value.strip()
        if allowed_keys is not None:
            if val.startswith('"') or val.startswith("'"):
                fail(f'{display(path)} has quoted {key} value: {val}')
                continue
            if '\\' in val:
                fail(f'{display(path)} has backslash in {key} value: {val}')
                continue
            if ': ' in val:
                fail(f'{display(path)} has unquoted colon-space in {key} value: {val}')
                continue
            for ch in '{}[]':
                if ch in val:
                    fail(f'{display(path)} has flow collection delimiter in {key} value: {val}')
                    break
            if '#' in val:
                fail(f'{display(path)} has hash character in {key} value: {val}')
                continue
        if val.startswith('"') and not val.endswith('"'):
            fail(f'{display(path)} has malformed double-quoting in {key} value: {val}')
            continue
        if val.startswith("'") and not val.endswith("'"):
            fail(f'{display(path)} has malformed single-quoting in {key} value: {val}')
            continue
        data[key] = val.strip('"\'')
    return data

def walk_tree(directory):
    entries = []

    def visit(current):
        try:
            children = sorted(os.scandir(current), key=lambda entry: entry.name)
        except OSError as error:
            fail(f'{display(current)} cannot be scanned: {error}')
            return
        for child in children:
            path = Path(child.path)
            relative = str(path.relative_to(directory))
            if child.is_symlink():
                entries.append((relative, path, 'symlink'))
            elif child.is_dir(follow_symlinks=False):
                entries.append((relative, path, 'directory'))
                visit(path)
            elif child.is_file(follow_symlinks=False):
                entries.append((relative, path, 'file'))
            else:
                entries.append((relative, path, 'other'))

    visit(directory)
    return entries

def validate_tree_root(directory, label):
    if directory.is_symlink():
        fail(f'{display(directory)} is a symlink; {label} must be a real directory')
        return []
    if not directory.exists():
        fail(f'missing required directory: {display(directory)}')
        return []
    if not directory.is_dir():
        fail(f'{display(directory)} is not a directory')
        return []
    entries = walk_tree(directory)
    for _, path, kind in entries:
        if kind == 'symlink':
            fail(f'{display(path)} is a symlink')
        elif kind == 'other':
            fail(f'{display(path)} is not a regular file or directory')
    return entries

def validate_skill(path, expected_name, require_trigger=False, allowed_keys=None):
    if path.is_symlink() or not path.is_file():
        return
    frontmatter = parse_frontmatter(path, allowed_keys=allowed_keys)
    if frontmatter.get('name') != expected_name:
        fail(f'{display(path)} frontmatter name must be {expected_name!r}')
    description = frontmatter.get('description', '')
    if not description:
        fail(f'{display(path)} frontmatter has empty description')
    elif require_trigger and not description.startswith('Use when'):
        fail(f'{display(path)} description must begin with "Use when"')

def validate_source_manifest(directory, expected_name, expected_entries, allowed_keys=None):
    entries = validate_tree_root(directory, f'{expected_name} source')
    if not entries and (directory.is_symlink() or not directory.is_dir()):
        return
    actual = {relative for relative, _, _ in entries}
    expected = set(expected_entries)
    for missing in sorted(expected - actual):
        fail(f'{display(directory / missing)} is missing')
    for extra in sorted(actual - expected):
        fail(f'{display(directory / extra)} is not in the {expected_name} source manifest')
    validate_skill(directory / 'SKILL.md', expected_name, require_trigger=True, allowed_keys=allowed_keys)
    for _, path, kind in entries:
        if kind == 'file':
            check_forbidden_content(path)

def check_exact_names(directory, suffix, expected, label):
    if not directory.is_dir():
        fail(f'missing required directory: {directory.relative_to(root)}')
        return
    actual = {p.name[:-len(suffix)] for p in directory.iterdir() if p.is_file() and p.name.endswith(suffix)}
    extra_entries = [p.name for p in directory.iterdir() if not (p.is_file() and p.name.endswith(suffix))]
    if actual != expected:
        fail(f'{label} must be exactly {sorted(expected)}; found {sorted(actual)}')
    if extra_entries:
        fail(f'{label} contains unsupported entries: {sorted(extra_entries)}')

def check_forbidden_content(path):
    if path.is_symlink() or not path.is_file():
        return
    text = read_text(path)
    for pattern, label in forbidden_patterns:
        match = pattern.search(text)
        if match:
            fail(f'{display(path)} contains {label}: {match.group(0)}')

cursor_entries = validate_tree_root(root, 'Cursor asset root')

for required_dir in ('agents', 'commands', 'skills', 'rules'):
    if not (root / required_dir).is_dir():
        fail(f'missing required directory: {required_dir}')

rules_file = root / 'rules' / 'default-agent.md'
if not rules_file.is_file():
    fail('missing required file: rules/default-agent.md')

check_exact_names(root / 'agents', '.md', expected_agents, 'agents')
check_exact_names(root / 'commands', '.md', expected_commands, 'commands')

commands_dir = root / 'commands'
if commands_dir.is_dir():
    excluded_found = sorted(name for name in excluded_commands if (commands_dir / f'{name}.md').exists())
    if excluded_found:
        fail(f'excluded commands are present: {excluded_found}')

skills_dir = root / 'skills'
if skills_dir.is_dir():
    actual_skills = {p.name for p in skills_dir.iterdir() if p.is_dir()}
    unsupported_skill_entries = [p.name for p in skills_dir.iterdir() if not p.is_dir()]
    if actual_skills != expected_skills:
        fail(f'skills must be exactly {sorted(expected_skills)}; found {sorted(actual_skills)}')
    if unsupported_skill_entries:
        fail(f'skills contains unsupported entries: {sorted(unsupported_skill_entries)}')

for agent_name in expected_agents:
    path = root / 'agents' / f'{agent_name}.md'
    if not path.is_file():
        continue
    frontmatter = parse_frontmatter(path)
    if frontmatter.get('name') != agent_name:
        fail(f'agents/{agent_name}.md frontmatter name must be {agent_name!r}')
    if not frontmatter.get('description'):
        fail(f'agents/{agent_name}.md frontmatter is missing description')
    if frontmatter.get('model') != 'inherit':
        fail(f'agents/{agent_name}.md frontmatter model must be inherit')
    if frontmatter.get('readonly') not in {'true', 'false'}:
        fail(f'agents/{agent_name}.md frontmatter readonly must be true or false')

for skill_name in expected_skills:
    skill_dir = root / 'skills' / skill_name
    path = skill_dir / 'SKILL.md'
    if not path.is_file():
        fail(f'missing required file: skills/{skill_name}/SKILL.md')
        continue
    allowed_extra_roots = {'references', 'scripts'}
    unsupported_skill_entries = []
    for entry in sorted(skill_dir.iterdir(), key=lambda p: p.name):
        if entry == path:
            continue
        if entry.is_dir() and entry.name in allowed_extra_roots:
            continue
        unsupported_skill_entries.append(str(entry.relative_to(skill_dir)))
    if unsupported_skill_entries:
        fail(f'skills/{skill_name} contains unsupported entries: {unsupported_skill_entries}')
    validate_skill(path, skill_name)

for _, asset, kind in cursor_entries:
    if kind == 'file':
        check_forbidden_content(asset)

WRITING_ALLOWED_KEYS = frozenset({'name', 'description'})
source_manifests = (
    (
        repo_root / '.apm' / 'skills' / 'humanizer',
        'humanizer',
        ('SKILL.md', 'references', 'references/patterns.md'),
        WRITING_ALLOWED_KEYS,
    ),
    (
        repo_root / '.apm' / 'skills' / 'stop-slop',
        'stop-slop',
        (
            'SKILL.md',
            'README.md',
            'LICENSE',
            'references',
            'references/examples.md',
            'references/phrases.md',
            'references/structures.md',
        ),
        WRITING_ALLOWED_KEYS,
    ),
)
for source_directory, source_name, manifest, allowed_keys in source_manifests:
    validate_source_manifest(source_directory, source_name, manifest, allowed_keys=allowed_keys)

if install_personal:
    validate_source_manifest(
        repo_root / 'profiles' / 'personal' / 'skills' / 'ivan-writing',
        'ivan-writing',
        ('SKILL.md', 'references', 'references/registers.md', 'references/examples.md'),
        allowed_keys=WRITING_ALLOWED_KEYS,
    )

if errors:
    for error in errors:
        print(f'Cursor asset validation failed: {error}', file=sys.stderr)
    sys.exit(1)
PY
}

validate_rules() {
  local root="$1"
  check_python
  python3 - "$root" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
rules = root / 'rules' / 'default-agent.md'
if not rules.is_file():
    print('Cursor rules validation failed: missing rules/default-agent.md', file=sys.stderr)
    sys.exit(1)
text = rules.read_text(encoding='utf-8')
patterns = [
    (re.compile(r'\bhive_[A-Za-z0-9_]+\b'), 'Hive tool name'),
    (re.compile(r'\b(?:task|question|todowrite)\s*\('), 'OpenCode-only tool call'),
    (re.compile(r'\b(?:functions|multi_tool_use)\.[A-Za-z0-9_]+\b'), 'OpenCode tool namespace'),
    (re.compile(r'</?(?:tool_use|function_calls?|invoke|parameter)\b'), 'OpenCode XML tool-call syntax'),
    (re.compile(r'/(?:home|Users)/[A-Za-z0-9._-]+(?:/|\b)'), 'absolute home-directory path'),
    (re.compile(r'https?://(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(?::\d+)?\b'), 'local proxy URL'),
    (re.compile(r'\b(?:sk-(?:ant-|proj-)?[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})\b'), 'obvious secret'),
    (re.compile(r'-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'), 'private key'),
]
for pattern, label in patterns:
    match = pattern.search(text)
    if match:
        print(f'Cursor rules validation failed: rules/default-agent.md contains {label}: {match.group(0)}', file=sys.stderr)
        sys.exit(1)
PY
}

print_copy_plan() {
  local root="$1"
  local target_dir="$2"
  local source
  printf 'Target: %s\n' "${target_dir}"
  for name in "${AGENTS[@]}"; do
    source="${root}/agents/${name}.md"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    source="${root}/commands/${name}.md"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/commands/${name}.md"
  done
  for name in "${SKILLS[@]}"; do
    source="${root}/skills/${name}"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/skills/${name}"
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    printf 'Would copy canonical .apm/skills/%s -> %s/skills/%s\n' "${name}" "${target_dir}" "${name}"
  done
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      printf 'Would copy personal profiles/personal/skills/ivan-writing -> %s/skills/ivan-writing (CURSOR_INSTALL_IVAN_WRITING=1)\n' "${target_dir}"
      ;;
    '')
      local marker="${target_dir}/${MARKER_RELPATH}"
      if [[ -f "${marker}" ]]; then
        printf 'Would back up and remove previously managed %s/skills/ivan-writing (CURSOR_INSTALL_IVAN_WRITING unset, opt-out effective)\n' "${target_dir}"
      elif [[ -d "${target_dir}/skills/ivan-writing" ]]; then
        printf 'Would preserve existing %s/skills/ivan-writing (not managed by this helper)\n' "${target_dir}"
      fi
      ;;
  esac
}

BACKUP_DIR=""
BACKUP_BASENAME="custom-opencode-configs-cursor-$(date +%Y%m%d-%H%M%S)"

backup_path() {
  local target_dir="$1"
  local path="$2"
  if [[ -e "${path}" ]]; then
    if [[ -z "${BACKUP_DIR}" ]]; then
      BACKUP_DIR="${target_dir}/.backup/${BACKUP_BASENAME}"
      mkdir -p "${BACKUP_DIR}"
    fi
    mkdir -p "${BACKUP_DIR}/$(dirname "${path#"${target_dir}/"}")"
    cp -a "${path}" "${BACKUP_DIR}/${path#"${target_dir}/"}"
  fi
}

install_canonical_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local source="${REPO_ROOT}/.apm/skills/${skill_name}"

  backup_path "${target_dir}" "${target_dir}/skills/${skill_name}"
  rm -rf "${target_dir}/skills/${skill_name}"
  mkdir -p "${target_dir}/skills/${skill_name}"
  cp -a "${source}/." "${target_dir}/skills/${skill_name}/"
  printf 'Copied canonical skills/%s -> %s\n' "${skill_name}" "${target_dir}/skills/${skill_name}"
}

MARKER_RELPATH="skills/ivan-writing/.cursor-managed"

install_personal_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local source="${REPO_ROOT}/profiles/personal/skills/${skill_name}"

  backup_path "${target_dir}" "${target_dir}/skills/${skill_name}"
  rm -rf "${target_dir}/skills/${skill_name}"
  mkdir -p "${target_dir}/skills/${skill_name}"
  cp -a "${source}/." "${target_dir}/skills/${skill_name}/"
  touch "${target_dir}/skills/${skill_name}/.cursor-managed"
  printf 'Copied personal skills/%s -> %s\n' "${skill_name}" "${target_dir}/skills/${skill_name}"
}

install_assets_into() {
  local root="$1"
  local target_dir="$2"
  local name

  BACKUP_DIR=""
  mkdir -p "${target_dir}/agents" "${target_dir}/commands" "${target_dir}/skills"

  for name in "${AGENTS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/agents/${name}.md"
    rm -rf "${target_dir}/agents/${name}.md"
    install -m 0644 "${root}/agents/${name}.md" "${target_dir}/agents/${name}.md"
    printf 'Copied agents/%s.md -> %s\n' "${name}" "${target_dir}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/commands/${name}.md"
    rm -rf "${target_dir}/commands/${name}.md"
    install -m 0644 "${root}/commands/${name}.md" "${target_dir}/commands/${name}.md"
    printf 'Copied commands/%s.md -> %s\n' "${name}" "${target_dir}/commands/${name}.md"
  done
  for name in "${SKILLS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/skills/${name}"
    rm -rf "${target_dir}/skills/${name}"
    mkdir -p "${target_dir}/skills/${name}"
    cp -a "${root}/skills/${name}/." "${target_dir}/skills/${name}/"
    printf 'Copied skills/%s -> %s\n' "${name}" "${target_dir}/skills/${name}"
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    install_canonical_skill "${name}" "${target_dir}"
  done

  local marker="${target_dir}/${MARKER_RELPATH}"
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      install_personal_skill "ivan-writing" "${target_dir}"
      ;;
    '')
      if [[ -d "${target_dir}/skills/ivan-writing" ]]; then
        if [[ -f "${marker}" ]]; then
          backup_path "${target_dir}" "${target_dir}/skills/ivan-writing"
          rm -rf "${target_dir}/skills/ivan-writing"
          printf 'Backed up and removed previously managed skills/ivan-writing (opt-out effective)\n'
        else
          printf 'Preserved existing skills/ivan-writing (not managed by this helper)\n'
        fi
      fi
      ;;
  esac

  printf 'Cursor markdown assets installed into %s\n' "${target_dir}"
  if [[ -n "${BACKUP_DIR}" ]]; then
    printf 'Backed up replaced Cursor assets into %s\n' "${BACKUP_DIR}"
  fi
}

check_recursive_readable() {
  local path="$1"
  local label="$2"
  local entry base
  if [[ -L "${path}" ]]; then
    return 0
  fi
  if [[ -f "${path}" ]]; then
    if [[ ! -r "${path}" ]]; then
      printf 'ERROR: %s exists but is not readable\n' "${label}" >&2
      return 1
    fi
    return 0
  fi
  if [[ -d "${path}" ]]; then
    if [[ ! -r "${path}" || ! -x "${path}" ]]; then
      printf 'ERROR: %s exists but is not readable/traversable\n' "${label}" >&2
      return 1
    fi
    for entry in "${path}"/* "${path}"/.*; do
      [[ -e "${entry}" || -L "${entry}" ]] || continue
      base="${entry##*/}"
      [[ "${base}" == "." || "${base}" == ".." ]] && continue
      check_recursive_readable "${entry}" "${label}/${base}" || return 1
    done
  fi
  return 0
}

check_target_readability() {
  local target="$1"
  local name entry_path

  if [[ -d "${target}/agents" ]]; then
    for name in "${AGENTS[@]}"; do
      entry_path="${target}/agents/${name}.md"
      if [[ -e "${entry_path}" || -L "${entry_path}" ]]; then
        if [[ -d "${entry_path}" ]]; then
          check_recursive_readable "${entry_path}" "target/agents/${name}.md" || return 1
        elif [[ ! -r "${entry_path}" ]]; then
          printf 'ERROR: target/agents/%s.md exists but is not readable: %s\n' "${name}" "${entry_path}" >&2
          return 1
        fi
      fi
    done
  fi

  if [[ -d "${target}/commands" ]]; then
    for name in "${COMMANDS[@]}"; do
      entry_path="${target}/commands/${name}.md"
      if [[ -e "${entry_path}" || -L "${entry_path}" ]]; then
        if [[ -d "${entry_path}" ]]; then
          check_recursive_readable "${entry_path}" "target/commands/${name}.md" || return 1
        elif [[ ! -r "${entry_path}" ]]; then
          printf 'ERROR: target/commands/%s.md exists but is not readable: %s\n' "${name}" "${entry_path}" >&2
          return 1
        fi
      fi
    done
  fi

  if [[ -d "${target}/skills" ]]; then
    for name in "${SKILLS[@]}" "${CANONICAL_SKILLS[@]}" ivan-writing; do
      if [[ -e "${target}/skills/${name}" || -L "${target}/skills/${name}" ]]; then
        check_recursive_readable "${target}/skills/${name}" "target/skills/${name}" || return 1
      fi
    done
  fi
}

preflight_targets() {
  local target dir path relative backup_root
  for target in "$@"; do
    if [[ ( -e "${target}" || -L "${target}" ) && ! -d "${target}" ]]; then
      printf 'ERROR: target exists and is not a directory: %s\n' "${target}" >&2
      return 1
    fi
    if [[ -d "${target}" ]]; then
      if [[ ! -w "${target}" || ! -x "${target}" ]]; then
        printf 'ERROR: target is not writable/traversable: %s\n' "${target}" >&2
        return 1
      fi
    else
      dir="${target}"
      while [[ ! -e "${dir}" && ! -L "${dir}" && "${dir}" != "/" ]]; do
        dir="$(dirname "${dir}")"
      done
      if [[ ! -d "${dir}" ]]; then
        printf 'ERROR: cannot access target: %s (nearest existing ancestor is not a directory: %s)\n' "${target}" "${dir}" >&2
        return 1
      fi
      if [[ ! -w "${dir}" || ! -x "${dir}" ]]; then
        printf 'ERROR: cannot create target: %s (ancestor %s is not writable/executable)\n' "${target}" "${dir}" >&2
        return 1
      fi
    fi

    for relative in agents commands skills .backup; do
      path="${target}/${relative}"
      if [[ -e "${path}" || -L "${path}" ]]; then
        if [[ -L "${path}" || ! -d "${path}" ]]; then
          printf 'ERROR: required target path is not a directory: %s\n' "${path}" >&2
          return 1
        fi
        if [[ ! -w "${path}" || ! -x "${path}" ]]; then
          printf 'ERROR: required target path is not writable/traversable: %s\n' "${path}" >&2
          return 1
        fi
      fi
    done

    backup_root="${target}/.backup/${BACKUP_BASENAME}"
    for path in "${backup_root}" "${backup_root}/agents" "${backup_root}/commands" "${backup_root}/skills"; do
      if [[ -e "${path}" || -L "${path}" ]]; then
        if [[ -L "${path}" || ! -d "${path}" ]]; then
          printf 'ERROR: required backup path is not a directory: %s\n' "${path}" >&2
          return 1
        fi
        if [[ ! -w "${path}" || ! -x "${path}" ]]; then
          printf 'ERROR: required backup path is not writable/traversable: %s\n' "${path}" >&2
          return 1
        fi
      fi
    done

    check_target_readability "${target}" || return 1
  done
}

TARGETS=()
collect_targets() {
  TARGETS=()
  if [[ "${CURSOR_CONFIG_DIRS+x}" == x ]]; then
    local saved_ifs="$IFS"
    IFS=';'
    set -f
    set -- ${CURSOR_CONFIG_DIRS}
    set +f
    IFS="$saved_ifs"
    for target; do
      if [[ -n "${target}" ]]; then
        TARGETS[${#TARGETS[@]}]="${target}"
      fi
    done
    if [[ "${#TARGETS[@]}" -eq 0 ]]; then
      printf 'CURSOR_CONFIG_DIRS was set but contained no install targets.\n' >&2
      exit 1
    fi
  else
    TARGETS=("${DEFAULT_TARGET_DIR}")
  fi
}

install_assets() {
  local root="$1"
  local target_dir

  collect_targets
  preflight_targets "${TARGETS[@]}" || exit 1

  for target_dir in "${TARGETS[@]}"; do
    install_assets_into "${root}" "${target_dir}"
  done

  printf 'Manual next step: paste the output of ./scripts/cursor-assets.sh print-rules into Cursor Settings -> Rules.\n'
}

print_all_copy_plans() {
  local root="$1"
  local target_dir

  collect_targets
  preflight_targets "${TARGETS[@]}" || exit 1

  for target_dir in "${TARGETS[@]}"; do
    print_copy_plan "${root}" "${target_dir}"
  done
}

main() {
  local command="${1:-}"
  local root

  case "${command}" in
    validate)
      preflight_env
      root="$(source_root)"
      validate_assets "${root}"
      printf 'Cursor asset validation passed\n'
      ;;
    install)
      preflight_env
      root="$(source_root)"
      case "${2:-}" in
        '')
          validate_assets "${root}"
          install_assets "${root}"
          ;;
        --dry-run)
          validate_assets "${root}"
          print_all_copy_plans "${root}"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;
    print-rules)
      root="$(source_root)"
      validate_rules "${root}"
      cat "${root}/rules/default-agent.md"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
