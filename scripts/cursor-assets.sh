#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TARGET_DIR="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"

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
)
SKILLS=(
  brainstorming
  consolidate-test-suites
  finishing-a-development-branch
  humanizer
  root-cause-finder
  stop-slop
  subagent-delegation
  systematic-debugging
  test-driven-development
  using-git-worktrees
  verification
)

usage() {
  printf 'Usage:\n' >&2
  printf '  %s validate\n' "$(basename "$0")" >&2
  printf '  %s install [--dry-run]\n' "$(basename "$0")" >&2
  printf '  %s print-rules\n' "$(basename "$0")" >&2
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
  python3 - "$root" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])

expected_agents = {
    'approach-advisor',
    'code-reviewer',
    'forager',
    'plan-reviewer',
    'scout',
    'simplicity-reviewer',
}
expected_commands = {
    'compact-summary',
    'council-directive',
    'council',
    'implementation-brief',
    'interview',
}
expected_skills = {
    'brainstorming',
    'consolidate-test-suites',
    'finishing-a-development-branch',
    'humanizer',
    'root-cause-finder',
    'stop-slop',
    'subagent-delegation',
    'systematic-debugging',
    'test-driven-development',
    'using-git-worktrees',
    'verification',
}
excluded_commands = {
    'approve-sync-plan',
    'hive-plan',
    'implementation-planning-prompt',
    'interview-drill-down',
    'planning-prompt',
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

def fail(message):
    errors.append(message)

def read_text(path):
    try:
        return path.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        fail(f'{path.relative_to(root)} is not valid UTF-8')
        return ''

def parse_frontmatter(path):
    text = read_text(path)
    lines = text.splitlines()
    if len(lines) < 3 or lines[0] != '---':
        fail(f'{path.relative_to(root)} is missing YAML frontmatter')
        return {}
    try:
        end = lines[1:].index('---') + 1
    except ValueError:
        fail(f'{path.relative_to(root)} has unterminated YAML frontmatter')
        return {}
    data = {}
    for line in lines[1:end]:
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        if ':' not in line:
            fail(f'{path.relative_to(root)} has invalid frontmatter line: {line}')
            continue
        key, value = line.split(':', 1)
        data[key.strip()] = value.strip().strip('"\'')
    return data

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
    if not path.is_file():
        return
    text = read_text(path)
    for pattern, label in forbidden_patterns:
        match = pattern.search(text)
        if match:
            fail(f'{path.relative_to(root)} contains {label}: {match.group(0)}')

errors = []

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
    path = root / 'skills' / skill_name / 'SKILL.md'
    if not path.is_file():
        fail(f'missing required file: skills/{skill_name}/SKILL.md')
        continue
    frontmatter = parse_frontmatter(path)
    if frontmatter.get('name') != skill_name:
        fail(f'skills/{skill_name}/SKILL.md frontmatter name must match folder')
    if not frontmatter.get('description'):
        fail(f'skills/{skill_name}/SKILL.md frontmatter is missing description')

for asset in sorted(root.rglob('*.md')):
    check_forbidden_content(asset)

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
  local source
  for name in "${AGENTS[@]}"; do
    source="${root}/agents/${name}.md"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${TARGET_DIR}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    source="${root}/commands/${name}.md"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${TARGET_DIR}/commands/${name}.md"
  done
  for name in "${SKILLS[@]}"; do
    source="${root}/skills/${name}"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${TARGET_DIR}/skills/${name}"
  done
}

BACKUP_DIR=""

backup_path() {
  local path="$1"
  if [[ -e "${path}" ]]; then
    if [[ -z "${BACKUP_DIR}" ]]; then
      BACKUP_DIR="${TARGET_DIR}/.backup/custom-opencode-configs-cursor-$(date +%Y%m%d-%H%M%S)"
      mkdir -p "${BACKUP_DIR}"
    fi
    mkdir -p "${BACKUP_DIR}/$(dirname "${path#"${TARGET_DIR}/"}")"
    cp -a "${path}" "${BACKUP_DIR}/${path#"${TARGET_DIR}/"}"
  fi
}

install_assets() {
  local root="$1"
  local name

  mkdir -p "${TARGET_DIR}/agents" "${TARGET_DIR}/commands" "${TARGET_DIR}/skills"

  for name in "${AGENTS[@]}"; do
    backup_path "${TARGET_DIR}/agents/${name}.md"
    install -m 0644 "${root}/agents/${name}.md" "${TARGET_DIR}/agents/${name}.md"
    printf 'Copied agents/%s.md -> %s\n' "${name}" "${TARGET_DIR}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    backup_path "${TARGET_DIR}/commands/${name}.md"
    install -m 0644 "${root}/commands/${name}.md" "${TARGET_DIR}/commands/${name}.md"
    printf 'Copied commands/%s.md -> %s\n' "${name}" "${TARGET_DIR}/commands/${name}.md"
  done
  for name in "${SKILLS[@]}"; do
    backup_path "${TARGET_DIR}/skills/${name}"
    rm -rf "${TARGET_DIR}/skills/${name}"
    mkdir -p "${TARGET_DIR}/skills/${name}"
    cp -a "${root}/skills/${name}/." "${TARGET_DIR}/skills/${name}/"
    printf 'Copied skills/%s -> %s\n' "${name}" "${TARGET_DIR}/skills/${name}"
  done

  printf 'Cursor markdown assets installed into %s\n' "${TARGET_DIR}"
  if [[ -n "${BACKUP_DIR}" ]]; then
    printf 'Backed up replaced Cursor assets into %s\n' "${BACKUP_DIR}"
  fi
  printf 'Manual next step: paste the output of ./scripts/cursor-assets.sh print-rules into Cursor Settings -> Rules.\n'
}

main() {
  local command="${1:-}"
  local root
  root="$(source_root)"

  case "${command}" in
    validate)
      validate_assets "${root}"
      printf 'Cursor asset validation passed\n'
      ;;
    install)
      case "${2:-}" in
        '')
          validate_assets "${root}"
          install_assets "${root}"
          ;;
        --dry-run)
          validate_assets "${root}"
          print_copy_plan "${root}"
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;
    print-rules)
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
