#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TARGET_DIR="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
EJ_SOURCE="${REPO_ROOT}/vendor/oc-arkive/engineering-judgment/engineering-judgment.md"
# Compose separator shared by Rules and agent prompts: the Engineering Judgment
# snapshot follows the source body after a horizontal rule.
COMPOSE_SEPARATOR=$'\n---\n\n'

AGENTS=(
  approach-advisor
  code-reviewer
  forager
  plan-reviewer
  scout
  simplicity-reviewer
  vulnerability-reviewer
)
# Cursor-specific commands. Shared prompt-backed commands install from
# .apm/prompts/<name>.prompt.md instead.
COMMANDS=(
  compact-summary
  council-directive
  council
  dash-review
  grill
  implementation-brief
  interview
  vuln-review
)
SHARED_COMMANDS=(
  interview-drill-down
  planning-prompt
  reflect
)
SKILLS=(
  adversarial-review
  agents-md-mastery
  brainstorming
  code-design-principles
  complexity-audit
  complexity-review
  finishing-a-development-branch
  grilling
  how
  humanizer
  orchestrating-ad-hoc-work
  parallel-exploration
  pr-writing
  stop-design-slop
  stop-slop
  subagent-delegation
  systematic-debugging
  test-driven-development
  unslop
  using-git-worktrees
  verification
  why
  writing-for-agents
  writing-for-humans
)
RETIRED_SKILLS=(
  consolidate-test-suites
  root-cause-finder
  writing-policy
)
# Skills a previous install may have left in the shared agents directory.
RETIRED_AGENTS_SKILLS=(
  writing-policy
)

CANONICAL_SKILLS=(
  aero-design
  connecting-atlassian-tools
  cymbal
  decomposing-work
  drawio-skill
  frontend-slides
  hard-cut
  managing-work-in-jira
  react-best-practices
  resume-tailoring
  running-agile-delivery
  web-design-guidelines
  working-with-atlassian
  writing-work-items
)
HIVE_BUNDLED_SKILLS=(
  humanizer
  stop-design-slop
  stop-slop
  unslop
  writing-for-agents
  writing-for-humans
)
# Delivered prompts must be usable without Agent Hive. These patterns reject
# Hive and OpenCode runtime syntax in Rules, agents, commands, and skills, and
# private data anywhere. Attribution files (UPSTREAM.md, LICENSE*) keep their
# source wording, so only the private-data patterns apply to them.
FORBIDDEN_PATTERN_SOURCE=$(cat <<'PY'
hive_runtime_patterns = [
    (re.compile(r'\bhive_[A-Za-z0-9_]+\b'), 'Hive tool name'),
    (re.compile(r'\b(?:task|question|todowrite|subagent)\('), 'OpenCode-only tool call'),
    (re.compile(r'\bskill\s*\(\s*\{'), 'native skill call'),
    (re.compile(r'<!--\s*/?hive-host'), 'Hive host section marker'),
    (re.compile(r'\b(?:hive-helper|hive-builder|hive-master|swarm-orchestrator|architect-planner)\b'), 'Hive role identifier'),
    (re.compile(r'(?<![A-Za-z0-9_.-])\.hive/'), 'Hive state path'),
    (re.compile(r'\b(?:functions|multi_tool_use)\.[A-Za-z0-9_]+\b'), 'OpenCode tool namespace'),
    (re.compile(r'</?(?:tool_use|function_calls?|invoke|parameter)\b'), 'OpenCode XML tool-call syntax'),
]
private_patterns = [
    (re.compile(r'/(?:home|Users)/[A-Za-z0-9._-]+(?:/|\b)'), 'absolute home-directory path'),
    (re.compile(r'https?://(?:localhost|127\.0\.0\.1|0\.0\.0\.0)(?::\d+)?\b'), 'local proxy URL'),
    (re.compile(r'\b(?:sk-(?:ant-|proj-)?[A-Za-z0-9_-]{16,}|gh[pousr]_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16})\b'), 'obvious secret'),
    (re.compile(r'-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'), 'private key'),
]
forbidden_patterns = hive_runtime_patterns + private_patterns
attribution_name = re.compile(r'^(?:UPSTREAM\.md|LICENSE(?:\..+)?)$')
PY
)
export FORBIDDEN_PATTERN_SOURCE

DECISION_COUNT=0
AGENTS_IVAN_OPT_OUT_NOTED=0
AGENTS_HIVE_BUNDLED_NOTED=""

note_conflict() {
  printf 'decision needed: conflict: %s is outside the managed install path %s; left in place\n' "$1" "$2" >&2
  DECISION_COUNT=$((DECISION_COUNT + 1))
}

note_unversioned() {
  printf 'decision needed: unversioned: %s is not packaged by this install; left in place\n' "$1" >&2
  DECISION_COUNT=$((DECISION_COUNT + 1))
}

exit_if_skill_decisions() {
  if [[ "${DECISION_COUNT}" -gt 0 ]]; then
    exit 1
  fi
}

report_cursor_skill_decisions() {
  local target_dir="$1"
  local name path agents_ivan

  for name in "${RETIRED_SKILLS[@]}"; do
    path="${target_dir}/skills/${name}"
    if [[ -e "${path}" || -L "${path}" ]]; then
      note_unversioned "${path}"
    fi
  done
  for name in "${RETIRED_AGENTS_SKILLS[@]}"; do
    path="${AGENTS_SKILLS_DIR}/${name}"
    if [[ -e "${path}" || -L "${path}" ]]; then
      note_unversioned "${path}"
    fi
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    path="${target_dir}/skills/${name}"
    if [[ -e "${path}" || -L "${path}" ]]; then
      note_conflict "${path}" "${AGENTS_SKILLS_DIR}/${name}"
    fi
  done
  for name in "${HIVE_BUNDLED_SKILLS[@]}"; do
    path="${AGENTS_SKILLS_DIR}/${name}"
    case " ${AGENTS_HIVE_BUNDLED_NOTED} " in
      *" ${name} "*) ;;
      *)
        if [[ -e "${path}" || -L "${path}" ]]; then
          AGENTS_HIVE_BUNDLED_NOTED="${AGENTS_HIVE_BUNDLED_NOTED} ${name}"
          note_conflict "${path}" "${target_dir}/skills/${name}"
        fi
        ;;
    esac
  done
  path="${target_dir}/skills/ivan-writing"
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      if [[ -e "${path}" || -L "${path}" ]]; then
        note_conflict "${path}" "${AGENTS_SKILLS_DIR}/ivan-writing"
      fi
      ;;
    '')
      if ivan_marker_unobservable "${path}"; then
        note_unversioned "${path}"
      elif [[ -f "${path}/.cursor-managed" ]]; then
        note_unversioned "${path}"
      fi
      agents_ivan="${AGENTS_SKILLS_DIR}/ivan-writing"
      if [[ "${AGENTS_IVAN_OPT_OUT_NOTED}" -eq 0 ]]; then
        if ivan_marker_unobservable "${agents_ivan}"; then
          AGENTS_IVAN_OPT_OUT_NOTED=1
          note_unversioned "${agents_ivan}"
        elif [[ -f "${agents_ivan}/.cursor-managed" ]]; then
          AGENTS_IVAN_OPT_OUT_NOTED=1
          note_unversioned "${agents_ivan}"
        fi
      fi
      ;;
  esac
}

# Opt-out ivan-writing: a directory that is not both readable and traversable
# hides whether .cursor-managed exists. Stat the directory only; do not read it.
ivan_marker_unobservable() {
  local path="$1"
  [[ -d "${path}" && ( ! -r "${path}" || ! -x "${path}" ) ]]
}

usage() {
  printf 'Usage:\n' >&2
  printf '  %s validate\n' "$(basename "$0")" >&2
  printf '  %s install [--dry-run]\n' "$(basename "$0")" >&2
  printf '  %s print-rules\n' "$(basename "$0")" >&2
  printf '  %s print-agent <name>\n' "$(basename "$0")" >&2
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
  AGENT_NAMES="${AGENTS[*]}" COMMAND_NAMES="${COMMANDS[*]}" SHARED_COMMAND_NAMES="${SHARED_COMMANDS[*]}" SKILL_NAMES="${SKILLS[*]}" RETIRED_SKILL_NAMES="${RETIRED_SKILLS[*]}" python3 - "$root" "${REPO_ROOT}" "${CURSOR_INSTALL_IVAN_WRITING:-}" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
install_personal = sys.argv[3] == '1'

expected_agents = set(os.environ['AGENT_NAMES'].split())
expected_commands = set(os.environ['COMMAND_NAMES'].split())
shared_commands = set(os.environ['SHARED_COMMAND_NAMES'].split())
expected_skills = set(os.environ['SKILL_NAMES'].split())
retired_skills = set(os.environ['RETIRED_SKILL_NAMES'].split())
# Subagents whose role is read-only. Cursor enforces readonly only when the
# frontmatter says so, so the flag must match the role.
writing_agents = {'forager'}
# Hive skills Cursor does not ship because they drive Hive tools or state.
undelivered_hive_skills = {
    'background-delegation',
    'context-engineering',
    'dispatching-parallel-agents',
    'executing-plans',
    'hive-config',
    'writing-plans',
}
appended_guidance_sentence = (
    'Apply the Engineering Judgment section appended to this prompt within this role\'s current scope and finding bar.'
)
excluded_commands = {
    'approve-sync-plan',
    'hive-plan',
    'implementation-planning-prompt',
    'start-execution',
}

exec(os.environ['FORBIDDEN_PATTERN_SOURCE'])

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

def parse_frontmatter(path, allowed_keys=None, quoted_ok=False):
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
        if allowed_keys is not None and not quoted_ok:
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

def validate_skill(path, expected_name, require_trigger=False, allowed_keys=None, quoted_ok=False):
    if path.is_symlink() or not path.is_file():
        return
    frontmatter = parse_frontmatter(path, allowed_keys=allowed_keys, quoted_ok=quoted_ok)
    if frontmatter.get('name') != expected_name:
        fail(f'{display(path)} frontmatter name must be {expected_name!r}')
    description = frontmatter.get('description', '')
    if not description:
        fail(f'{display(path)} frontmatter has empty description')
    elif require_trigger and not description.startswith('Use when'):
        fail(f'{display(path)} description must begin with "Use when"')

def validate_source_manifest(directory, expected_name, expected_entries, allowed_keys=None, require_trigger=True):
    entries = validate_tree_root(directory, f'{expected_name} source')
    if not entries and (directory.is_symlink() or not directory.is_dir()):
        return
    actual = {relative for relative, _, _ in entries}
    expected = set(expected_entries)
    for missing in sorted(expected - actual):
        fail(f'{display(directory / missing)} is missing')
    for extra in sorted(actual - expected):
        fail(f'{display(directory / extra)} is not in the {expected_name} source manifest')
    validate_skill(directory / 'SKILL.md', expected_name, require_trigger=require_trigger, allowed_keys=allowed_keys)
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
    if path.suffix.lower() in {'.gz'}:
        return
    text = read_text(path)
    patterns = private_patterns if attribution_name.match(path.name) else forbidden_patterns
    for pattern, label in patterns:
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

# Shared commands live once under .apm/prompts and install into Cursor from there.
for shared_name in sorted(shared_commands):
    stale_copy = root / 'commands' / f'{shared_name}.md'
    if stale_copy.exists() or stale_copy.is_symlink():
        fail(f'stale duplicate commands/{shared_name}.md is present; use canonical .apm/prompts/{shared_name}.prompt.md')
    shared_source = repo_root / '.apm' / 'prompts' / f'{shared_name}.prompt.md'
    if shared_source.is_symlink() or not shared_source.is_file():
        fail(f'missing canonical shared command source: .apm/prompts/{shared_name}.prompt.md')
        continue
    shared_frontmatter = parse_frontmatter(shared_source)
    if set(shared_frontmatter) != {'description'} or not shared_frontmatter.get('description'):
        fail(f'.apm/prompts/{shared_name}.prompt.md frontmatter must be exactly a non-empty description')
    check_forbidden_content(shared_source)

commands_dir = root / 'commands'
if commands_dir.is_dir():
    excluded_found = sorted(name for name in excluded_commands if (commands_dir / f'{name}.md').exists())
    if excluded_found:
        fail(f'excluded commands are present: {excluded_found}')

# Imported skills are described by the sync provenance: its per-file list is the
# exact tree, so no second manifest is kept for them here.
provenance_file = repo_root / 'vendor' / 'oc-arkive' / 'cursor-skills' / 'provenance.json'
synced_names = set()
if provenance_file.is_file() and not provenance_file.is_symlink():
    try:
        synced_names = set(json.loads(provenance_file.read_text(encoding='utf-8'))['skills'])
    except (OSError, ValueError, KeyError, TypeError):
        synced_names = set()

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
    expected_readonly = 'false' if agent_name in writing_agents else 'true'
    if frontmatter.get('readonly') != expected_readonly:
        fail(f'agents/{agent_name}.md frontmatter readonly must be {expected_readonly}')
    agent_text = read_text(path)
    if agent_text.count(appended_guidance_sentence) != 1:
        fail(f'agents/{agent_name}.md must state the appended Engineering Judgment guidance exactly once')
    if 'active Cursor Rules' in agent_text or 'User Rules' in agent_text:
        fail(f'agents/{agent_name}.md must not rely on Rules inheritance; Cursor does not document that subagents receive User Rules')

extra_skill_roots = {'stop-design-slop': {'assets', 'examples'}}
extra_skill_files = {'stop-design-slop': {'LICENSE.impeccable'}}

for skill_name in expected_skills:
    skill_dir = root / 'skills' / skill_name
    path = skill_dir / 'SKILL.md'
    if not path.is_file():
        fail(f'missing required file: skills/{skill_name}/SKILL.md')
        continue
    if skill_name in synced_names:
        validate_skill(path, skill_name, allowed_keys=frozenset({'name', 'description'}), quoted_ok=True)
        continue
    allowed_extra_roots = {'references', 'scripts'} | extra_skill_roots.get(skill_name, set())
    unsupported_skill_entries = []
    for entry in sorted(skill_dir.iterdir(), key=lambda p: p.name):
        if entry == path:
            continue
        if entry.is_dir() and entry.name in allowed_extra_roots:
            continue
        if entry.is_file() and entry.name in extra_skill_files.get(skill_name, set()):
            continue
        unsupported_skill_entries.append(str(entry.relative_to(skill_dir)))
    if unsupported_skill_entries:
        fail(f'skills/{skill_name} contains unsupported entries: {unsupported_skill_entries}')
    # Locally maintained skills keep strict, Cursor-safe frontmatter. stop-design-slop
    # carries a nested metadata block and is validated against its own manifest.
    if skill_name == 'stop-design-slop':
        validate_skill(path, skill_name)
    else:
        validate_skill(path, skill_name, require_trigger=True, allowed_keys=frozenset({'name', 'description'}))

for _, asset, kind in cursor_entries:
    if kind == 'file':
        check_forbidden_content(asset)

# Reference closure: relative links inside a skill stay inside it and resolve,
# and no delivered instruction points at a skill Cursor does not ship.
link_pattern = re.compile(r'\]\(([^)\s]+)\)')
fence_pattern = re.compile(r'^(```|~~~)')
skill_name_pattern = {
    name: re.compile(r'(?<![A-Za-z0-9_-])' + re.escape(name) + r'(?![A-Za-z0-9_-])')
    for name in sorted(undelivered_hive_skills | retired_skills)
}
for _, asset, kind in cursor_entries:
    if kind != 'file' or asset.suffix.lower() != '.md' or attribution_name.match(asset.name):
        continue
    text = read_text(asset)
    for skill_ref, ref_pattern in ([] if asset == root / 'README.md' else skill_name_pattern.items()):
        if ref_pattern.search(text):
            fail(f'{display(asset)} references skill {skill_ref}, which Cursor does not ship')
    relative_to_root = asset.relative_to(root)
    if relative_to_root.parts[0] != 'skills' or len(relative_to_root.parts) < 3:
        continue
    skill_root = root / 'skills' / relative_to_root.parts[1]
    in_fence = False
    for line in text.splitlines():
        if fence_pattern.match(line.strip()):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for target in link_pattern.findall(line):
            if re.match(r'^(?:[A-Za-z][A-Za-z0-9+.-]*:|#)', target):
                continue
            resolved = (asset.parent / target.split('#', 1)[0]).resolve(strict=False)
            try:
                resolved.relative_to(skill_root.resolve(strict=False))
            except ValueError:
                fail(f'{display(asset)} links outside its skill: {target}')
                continue
            if not resolved.exists():
                fail(f'{display(asset)} links to a missing file: {target}')

WRITING_ALLOWED_KEYS = frozenset({'name', 'description'})
source_manifests = (
    (
        repo_root / '.apm' / 'skills' / 'drawio-skill',
        'drawio-skill',
        (
            '.gitignore',
            'SKILL.md',
            'bin',
            'bin/run',
            'data',
            'data/SHAPE-INDEX-NOTICE.md',
            'data/lobe-icons.json',
            'data/shape-index.json.gz',
            'pyproject.toml',
            'references',
            'references/autolayout.md',
            'references/derasterize.md',
            'references/diagram-types.md',
            'references/live-infra.md',
            'references/mermaid-authoring.md',
            'references/pr-bot.md',
            'references/shapes.md',
            'references/style-extraction.md',
            'references/style-presets.md',
            'references/toolbox.md',
            'references/troubleshooting.md',
            'references/tubemap.md',
            'references/xml-authoring.md',
            'scripts',
            'scripts/aiicons.py',
            'scripts/autolayout.py',
            'scripts/buildup.py',
            'scripts/c4.py',
            'scripts/ciimports.py',
            'scripts/composeimports.py',
            'scripts/compress.py',
            'scripts/dockerimports.py',
            'scripts/drawio2mermaid.py',
            'scripts/drawio2pptx.py',
            'scripts/drawiodiff.py',
            'scripts/drawiohtml.py',
            'scripts/edgeports.py',
            'scripts/encode_drawio_url.py',
            'scripts/explain.py',
            'scripts/goimports.py',
            'scripts/heatmap.py',
            'scripts/jsimports.py',
            'scripts/k8simports.py',
            'scripts/openapiimports.py',
            'scripts/prdiff.py',
            'scripts/pyclasses.py',
            'scripts/pyimports.py',
            'scripts/raster2drawio.py',
            'scripts/relabel.py',
            'scripts/repair_png.py',
            'scripts/restyle.py',
            'scripts/runbook.py',
            'scripts/rustimports.py',
            'scripts/seqlayout.py',
            'scripts/shapesearch.py',
            'scripts/sqlerd.py',
            'scripts/svgflow.py',
            'scripts/tfimports.py',
            'scripts/tfstate.py',
            'scripts/timelapse.py',
            'scripts/tubemap.py',
            'scripts/validate.py',
            'styles',
            'styles/built-in',
            'styles/built-in/colorblind-safe.json',
            'styles/built-in/corporate.json',
            'styles/built-in/dark.json',
            'styles/built-in/default.json',
            'styles/built-in/handdrawn.json',
            'styles/schema.json',
            'uv.lock',
        ),
        None,
    ),
    (
        repo_root / '.apm' / 'skills' / 'frontend-slides',
        'frontend-slides',
        (
            'SKILL.md',
            'references',
            'references/briefing.css',
            'references/html-template.md',
            'references/visual-system.md',
            'scripts',
            'scripts/build-standalone.py',
            'scripts/deploy.sh',
            'scripts/export-pdf.sh',
            'scripts/extract-pptx.py',
            'viewport-base.css',
        ),
        WRITING_ALLOWED_KEYS,
    ),
    (
        repo_root / '.apm' / 'cursor' / 'skills' / 'stop-design-slop',
        'stop-design-slop',
        (
            'LICENSE.impeccable',
            'SKILL.md',
            'assets',
            'assets/anti-slop-principles.svg',
            'assets/card-soup-vs-structure.svg',
            'assets/salience-hierarchy.svg',
            'examples',
            'examples/README.md',
            'examples/card-soup-before.html',
            'examples/dashboard-after.html',
            'examples/dashboard-before.html',
            'examples/generic-hero-before.html',
            'examples/product-led-hero-after.html',
            'examples/structural-hierarchy-after.html',
            'references',
            'references/pattern-catalog.md',
            'references/research-basis.md',
            'references/review-rubric.md',
            'references/source-index.md',
            'references/terminology.md',
            'scripts',
            'scripts/audit_ui.py',
            'scripts/contrast_check.py',
        ),
        None,
    ),
    (
        repo_root / '.apm' / 'skills' / 'cymbal',
        'cymbal',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'hard-cut',
        'hard-cut',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'connecting-atlassian-tools',
        'connecting-atlassian-tools',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'managing-work-in-jira',
        'managing-work-in-jira',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'working-with-atlassian',
        'working-with-atlassian',
        ('SKILL.md', 'references', 'references/jql-essentials.md'),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'web-design-guidelines',
        'web-design-guidelines',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'react-best-practices',
        'react-best-practices',
        (
            'AGENTS.md',
            'README.md',
            'SKILL.md',
            'metadata.json',
            'rules',
            'rules/_sections.md',
            'rules/_template.md',
            'rules/advanced-event-handler-refs.md',
            'rules/advanced-use-latest.md',
            'rules/async-api-routes.md',
            'rules/async-defer-await.md',
            'rules/async-dependencies.md',
            'rules/async-parallel.md',
            'rules/async-suspense-boundaries.md',
            'rules/bundle-barrel-imports.md',
            'rules/bundle-conditional.md',
            'rules/bundle-defer-third-party.md',
            'rules/bundle-dynamic-imports.md',
            'rules/bundle-preload.md',
            'rules/client-event-listeners.md',
            'rules/client-swr-dedup.md',
            'rules/js-batch-dom-css.md',
            'rules/js-cache-function-results.md',
            'rules/js-cache-property-access.md',
            'rules/js-cache-storage.md',
            'rules/js-combine-iterations.md',
            'rules/js-early-exit.md',
            'rules/js-hoist-regexp.md',
            'rules/js-index-maps.md',
            'rules/js-length-check-first.md',
            'rules/js-min-max-loop.md',
            'rules/js-set-map-lookups.md',
            'rules/js-tosorted-immutable.md',
            'rules/rendering-activity.md',
            'rules/rendering-animate-svg-wrapper.md',
            'rules/rendering-conditional-render.md',
            'rules/rendering-content-visibility.md',
            'rules/rendering-hoist-jsx.md',
            'rules/rendering-hydration-no-flicker.md',
            'rules/rendering-svg-precision.md',
            'rules/rerender-defer-reads.md',
            'rules/rerender-dependencies.md',
            'rules/rerender-derived-state.md',
            'rules/rerender-functional-setstate.md',
            'rules/rerender-lazy-state-init.md',
            'rules/rerender-memo.md',
            'rules/rerender-transitions.md',
            'rules/server-after-nonblocking.md',
            'rules/server-cache-lru.md',
            'rules/server-cache-react.md',
            'rules/server-parallel-fetching.md',
            'rules/server-serialization.md',
        ),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'aero-design',
        'aero-design',
        (
            'README.md',
            'SKILL.md',
            'assets',
            'assets/AERO-DESIGN.template.md',
            'references',
            'references/data-presentation.md',
            'references/review.md',
            'references/sources.md',
            'references/tuning.md',
            'references/visual-language.md',
        ),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'decomposing-work',
        'decomposing-work',
        (
            'SKILL.md',
            'references',
            'references/decomposition-example.md',
        ),
        WRITING_ALLOWED_KEYS,
        True,
    ),
    (
        repo_root / '.apm' / 'skills' / 'running-agile-delivery',
        'running-agile-delivery',
        ('SKILL.md',),
        WRITING_ALLOWED_KEYS,
        True,
    ),
    (
        repo_root / '.apm' / 'skills' / 'writing-work-items',
        'writing-work-items',
        (
            'SKILL.md',
            'references',
            'references/work-item-templates.md',
        ),
        WRITING_ALLOWED_KEYS,
        True,
    ),
    (
        repo_root / '.apm' / 'skills' / 'resume-tailoring',
        'resume-tailoring',
        (
            '.gitignore',
            'LICENSE',
            'MARKETPLACE.md',
            'README.md',
            'SKILL.md',
            'SUBMISSION_GUIDE.md',
            'branching-questions.md',
            'docs',
            'docs/plans',
            'docs/plans/2025-11-04-multi-job-implementation-summary.md',
            'docs/plans/2025-11-04-multi-job-resume-tailoring-design.md',
            'docs/schemas',
            'docs/schemas/batch-state-schema.md',
            'docs/schemas/job-schema.md',
            'docs/testing',
            'docs/testing/multi-job-test-checklist.md',
            'matching-strategies.md',
            'multi-job-workflow.md',
            'research-prompts.md',
        ),
        None,
        False,
    ),
)
for source_item in source_manifests:
    source_directory, source_name, manifest, allowed_keys = source_item[:4]
    require_trigger = source_item[4] if len(source_item) > 4 else True
    validate_source_manifest(
        source_directory,
        source_name,
        manifest,
        allowed_keys=allowed_keys,
        require_trigger=require_trigger,
    )

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
  python3 - "$root" "${REPO_ROOT}" <<'PY'
import hashlib
import json
import os
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
exec(os.environ['FORBIDDEN_PATTERN_SOURCE'])
rules = root / 'rules' / 'default-agent.md'
vendor = repo_root / 'vendor' / 'oc-arkive' / 'engineering-judgment' / 'engineering-judgment.md'
provenance_path = vendor.parent / 'provenance.json'

def require_regular_file(path, label, expected_root):
    try:
        relative = path.relative_to(repo_root)
    except ValueError:
        print(f'Cursor rules validation failed: {label} is outside the repository root', file=sys.stderr)
        raise SystemExit(1)
    current = repo_root
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            print(f'Cursor rules validation failed: {label} contains symlink path component {current}', file=sys.stderr)
            raise SystemExit(1)
    try:
        path.resolve(strict=False).relative_to(repo_root.resolve(strict=True))
    except (OSError, ValueError):
        print(f'Cursor rules validation failed: {label} resolves outside the repository root', file=sys.stderr)
        raise SystemExit(1)
    try:
        path.resolve(strict=False).relative_to(expected_root.resolve(strict=True))
    except (OSError, ValueError):
        print(f'Cursor rules validation failed: {label} resolves outside its expected root', file=sys.stderr)
        raise SystemExit(1)
    if not path.is_file():
        print(f'Cursor rules validation failed: missing regular file: {label}', file=sys.stderr)
        raise SystemExit(1)

require_regular_file(rules, 'rules/default-agent.md', root)
require_regular_file(vendor, 'vendor/oc-arkive/engineering-judgment/engineering-judgment.md', vendor.parent)
require_regular_file(provenance_path, 'vendor/oc-arkive/engineering-judgment/provenance.json', vendor.parent)

try:
    rules_bytes = rules.read_bytes()
    vendor_bytes = vendor.read_bytes()
    provenance_bytes = provenance_path.read_bytes()
    text = rules_bytes.decode('utf-8')
    vendor_text = vendor_bytes.decode('utf-8')
    provenance_text = provenance_bytes.decode('utf-8')
except UnicodeDecodeError as error:
    print(f'Cursor rules validation failed: content is not valid UTF-8: {error}', file=sys.stderr)
    raise SystemExit(1)

for label, content in (
    ('rules/default-agent.md', rules_bytes),
    ('engineering-judgment.md', vendor_bytes),
    ('provenance.json', provenance_bytes),
):
    if b'\r' in content or not content.endswith(b'\n'):
        print(f'Cursor rules validation failed: {label} must use normalized LF text with a trailing newline', file=sys.stderr)
        raise SystemExit(1)

try:
    provenance = json.loads(provenance_text)
except json.JSONDecodeError as error:
    print(f'Cursor rules validation failed: provenance.json is invalid JSON: {error}', file=sys.stderr)
    raise SystemExit(1)

if not isinstance(provenance, dict):
    print('Cursor rules validation failed: provenance root must be an object', file=sys.stderr)
    raise SystemExit(1)

expected_keys = {
    'schemaVersion',
    'upstreamRepository',
    'commit',
    'sourcePath',
    'packageVersion',
    'sha256',
}
if set(provenance) != expected_keys:
    print(f'Cursor rules validation failed: provenance keys must be exactly {sorted(expected_keys)}', file=sys.stderr)
    raise SystemExit(1)
if type(provenance['schemaVersion']) is not int or provenance['schemaVersion'] != 1:
    print('Cursor rules validation failed: provenance schemaVersion must be integer 1', file=sys.stderr)
    raise SystemExit(1)
if not isinstance(provenance['upstreamRepository'], str) or not provenance['upstreamRepository']:
    print('Cursor rules validation failed: provenance upstreamRepository must be a non-empty string', file=sys.stderr)
    raise SystemExit(1)
if not isinstance(provenance['commit'], str) or not re.fullmatch(r'[0-9a-f]{40}', provenance['commit']):
    print('Cursor rules validation failed: provenance commit must be an immutable full lowercase Git commit', file=sys.stderr)
    raise SystemExit(1)
if not isinstance(provenance['sourcePath'], str) or provenance['sourcePath'] != 'packages/opencode-hive/src/agents/engineering-judgment.ts':
    print('Cursor rules validation failed: provenance sourcePath is not the oc-arkive authority', file=sys.stderr)
    raise SystemExit(1)
if not isinstance(provenance['packageVersion'], str) or not provenance['packageVersion']:
    print('Cursor rules validation failed: provenance packageVersion must be a non-empty string', file=sys.stderr)
    raise SystemExit(1)
if not isinstance(provenance['sha256'], str) or not re.fullmatch(r'[0-9a-f]{64}', provenance['sha256']):
    print('Cursor rules validation failed: provenance sha256 must be a lowercase SHA-256', file=sys.stderr)
    raise SystemExit(1)
actual_hash = hashlib.sha256(vendor_bytes).hexdigest()
if provenance['sha256'] != actual_hash:
    print(
        f'Cursor rules validation failed: engineering-judgment.md SHA-256 is {actual_hash}, expected {provenance["sha256"]}',
        file=sys.stderr,
    )
    raise SystemExit(1)
if not vendor_text.startswith('## Engineering Judgment\n'):
    print('Cursor rules validation failed: engineering-judgment.md is missing its expected heading', file=sys.stderr)
    raise SystemExit(1)

separator = b'\n---\n\n'
composed = rules_bytes + separator + vendor_bytes
if composed.count(separator) != 1 or composed.count(vendor_bytes) != 1:
    print('Cursor rules validation failed: composed Rules must contain one separator and one vendored philosophy', file=sys.stderr)
    raise SystemExit(1)
if composed.count(b'## Engineering Judgment') != 1:
    print('Cursor rules validation failed: composed Rules must contain Engineering Judgment exactly once', file=sys.stderr)
    raise SystemExit(1)
composed_text = composed.decode('utf-8')

for pattern, label in forbidden_patterns:
    match = pattern.search(composed_text)
    if match:
        print(f'Cursor rules validation failed: composed Rules contain {label}: {match.group(0)}', file=sys.stderr)
        sys.exit(1)

# Each installed agent prompt is its source body plus the same Engineering
# Judgment snapshot, with the source frontmatter intact.
agents_directory = root / 'agents'
for agent_path in sorted(agents_directory.glob('*.md')):
    agent_bytes = agent_path.read_bytes()
    composed_agent = agent_bytes + separator + vendor_bytes
    composed_agent_text = composed_agent.decode('utf-8')
    label = f'agents/{agent_path.name}'
    if not composed_agent_text.startswith('---\nname: '):
        print(f'Cursor rules validation failed: composed {label} lost its frontmatter', file=sys.stderr)
        raise SystemExit(1)
    if b'## Engineering Judgment' in agent_bytes:
        print(f'Cursor rules validation failed: {label} source must not embed Engineering Judgment; it is appended at install', file=sys.stderr)
        raise SystemExit(1)
    if composed_agent.count(b'## Engineering Judgment') != 1 or composed_agent.count(vendor_bytes) != 1:
        print(f'Cursor rules validation failed: composed {label} must contain Engineering Judgment exactly once', file=sys.stderr)
        raise SystemExit(1)
    for pattern, pattern_label in forbidden_patterns:
        match = pattern.search(composed_agent_text)
        if match:
            print(f'Cursor rules validation failed: composed {label} contains {pattern_label}: {match.group(0)}', file=sys.stderr)
            raise SystemExit(1)
PY
}

validate_cursor_hive_skills() {
  check_python
  python3 - "${REPO_ROOT}" <<'PY'
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

sys.dont_write_bytecode = True
repo_root = Path(sys.argv[1])
provenance_path = repo_root / 'vendor' / 'oc-arkive' / 'cursor-skills' / 'provenance.json'
skills_root = repo_root / '.apm' / 'cursor' / 'skills'
sync_script = repo_root / 'scripts' / 'sync-cursor-hive-skills.py'
expected_root_keys = {
    'schemaVersion',
    'upstreamRepository',
    'commit',
    'packageVersion',
    'skills',
}
expected_skill_keys = {'sourcePath', 'files'}
expected_file_keys = {'sourceSha256', 'installedSha256'}

def fail(message):
    print(f'Cursor Hive skills validation failed: {message}', file=sys.stderr)
    raise SystemExit(1)

def require_regular_file(path, label, expected_root):
    try:
        relative = path.relative_to(repo_root)
    except ValueError:
        fail(f'{label} is outside the repository root')
    current = repo_root
    for part in relative.parts:
        current = current / part
        if current.is_symlink():
            fail(f'{label} contains symlink path component {current}')
    try:
        path.resolve(strict=False).relative_to(repo_root.resolve(strict=True))
    except (OSError, ValueError):
        fail(f'{label} resolves outside the repository root')
    try:
        path.resolve(strict=False).relative_to(expected_root.resolve(strict=True))
    except (OSError, ValueError):
        fail(f'{label} resolves outside its expected root')
    if not path.is_file():
        fail(f'missing regular file: {label}')

if provenance_path.is_symlink():
    fail('vendor/oc-arkive/cursor-skills/provenance.json is a symlink')
if not provenance_path.exists():
    raise SystemExit(0)

require_regular_file(
    provenance_path,
    'vendor/oc-arkive/cursor-skills/provenance.json',
    provenance_path.parent,
)

try:
    provenance_bytes = provenance_path.read_bytes()
    provenance_text = provenance_bytes.decode('utf-8')
except UnicodeDecodeError as error:
    fail(f'provenance.json is not valid UTF-8: {error}')

if b'\r' in provenance_bytes or not provenance_bytes.endswith(b'\n'):
    fail('provenance.json must use normalized LF text with a trailing newline')

try:
    provenance = json.loads(provenance_text)
except json.JSONDecodeError as error:
    fail(f'provenance.json is invalid JSON: {error}')

if not isinstance(provenance, dict):
    fail('provenance root must be an object')
if set(provenance) != expected_root_keys:
    fail(f'provenance keys must be exactly {sorted(expected_root_keys)}')
if type(provenance['schemaVersion']) is not int or provenance['schemaVersion'] != 2:
    fail('provenance schemaVersion must be integer 2')
if not isinstance(provenance['upstreamRepository'], str) or not provenance['upstreamRepository']:
    fail('provenance upstreamRepository must be a non-empty string')
if not isinstance(provenance['commit'], str) or not re.fullmatch(r'[0-9a-f]{40}', provenance['commit']):
    fail('provenance commit must be an immutable full lowercase Git commit')
if not isinstance(provenance['packageVersion'], str) or not provenance['packageVersion']:
    fail('provenance packageVersion must be a non-empty string')
skills = provenance['skills']
if not isinstance(skills, dict) or not skills:
    fail('provenance skills must be a non-empty object')

# The sync script owns the imported and retired names; read them from it when
# it ships alongside this validator.
if sync_script.is_file() and not sync_script.is_symlink():
    spec = importlib.util.spec_from_file_location('cursor_hive_skills_sync', sync_script)
    sync_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sync_module)
    if set(skills) != set(sync_module.IMPORTED_SKILLS):
        fail(f'provenance skills must be exactly {sorted(sync_module.IMPORTED_SKILLS)}')
    for retired in sync_module.RETIRED_SKILLS:
        if (skills_root / retired).exists():
            fail(f'retired skill {retired} is still present in .apm/cursor/skills')

for name in sorted(skills):
    entry = skills[name]
    label = f'provenance skills.{name}'
    if not isinstance(entry, dict) or set(entry) != expected_skill_keys:
        fail(f'{label} keys must be exactly {sorted(expected_skill_keys)}')
    expected_source = f'packages/opencode-hive/skills/{name}'
    if entry['sourcePath'] != expected_source:
        fail(f'{label} sourcePath must be {expected_source}')
    files = entry['files']
    if not isinstance(files, dict) or 'SKILL.md' not in files:
        fail(f'{label} files must be an object that includes SKILL.md')
    skill_directory = skills_root / name
    if skill_directory.is_symlink() or not skill_directory.is_dir():
        fail(f'.apm/cursor/skills/{name} must be a real directory')
    actual = {
        path.relative_to(skill_directory).as_posix()
        for path in skill_directory.rglob('*')
        if path.is_file() or path.is_symlink()
    }
    for missing in sorted(set(files) - actual):
        fail(f'.apm/cursor/skills/{name}/{missing} is listed in provenance but missing')
    for extra in sorted(actual - set(files)):
        fail(f'.apm/cursor/skills/{name}/{extra} is not listed in provenance')
    for relative in sorted(files):
        file_entry = files[relative]
        file_label = f'{label}.files.{relative}'
        if not isinstance(file_entry, dict) or set(file_entry) != expected_file_keys:
            fail(f'{file_label} keys must be exactly {sorted(expected_file_keys)}')
        for field in sorted(expected_file_keys):
            value = file_entry[field]
            if not isinstance(value, str) or not re.fullmatch(r'[0-9a-f]{64}', value):
                fail(f'{file_label} {field} must be a lowercase SHA-256')
        installed_path = skill_directory / relative
        require_regular_file(installed_path, f'.apm/cursor/skills/{name}/{relative}', skill_directory)
        actual_hash = hashlib.sha256(installed_path.read_bytes()).hexdigest()
        if actual_hash != file_entry['installedSha256']:
            fail(
                f'.apm/cursor/skills/{name}/{relative} SHA-256 is {actual_hash}, expected {file_entry["installedSha256"]}'
            )
PY
}

# An installed agent prompt is the source body followed by the pinned
# Engineering Judgment snapshot, with the source frontmatter first.
render_agent() {
  local root="$1"
  local name="$2"
  cat "${root}/agents/${name}.md"
  printf '%s' "${COMPOSE_SEPARATOR}"
  cat "${EJ_SOURCE}"
}

print_copy_plan() {
  local root="$1"
  local target_dir="$2"
  local source
  printf 'Target: %s\n' "${target_dir}"
  for name in "${AGENTS[@]}"; do
    source="${root}/agents/${name}.md"
    printf 'Would copy %s with pinned Engineering Judgment appended -> %s\n' "${source#"${root}/"}" "${target_dir}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    source="${root}/commands/${name}.md"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/commands/${name}.md"
  done
  for name in "${SHARED_COMMANDS[@]}"; do
    printf 'Would copy canonical .apm/prompts/%s.prompt.md -> %s\n' "${name}" "${target_dir}/commands/${name}.md"
  done
  for name in "${SKILLS[@]}"; do
    source="${root}/skills/${name}"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/skills/${name}"
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    printf 'Would copy canonical .apm/skills/%s -> %s/%s\n' "${name}" "${AGENTS_SKILLS_DIR}" "${name}"
  done
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      printf 'Would copy personal profiles/personal/skills/ivan-writing -> %s/ivan-writing (CURSOR_INSTALL_IVAN_WRITING=1)\n' "${AGENTS_SKILLS_DIR}"
      ;;
    '')
      if [[ -d "${AGENTS_SKILLS_DIR}/ivan-writing" && -r "${AGENTS_SKILLS_DIR}/ivan-writing" && -x "${AGENTS_SKILLS_DIR}/ivan-writing" && ! -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]]; then
        printf 'Would preserve existing %s/ivan-writing (not managed by this helper)\n' "${AGENTS_SKILLS_DIR}"
      fi
      if [[ -e "${target_dir}/skills/ivan-writing" || -L "${target_dir}/skills/ivan-writing" ]]; then
        if ! ivan_marker_unobservable "${target_dir}/skills/ivan-writing" && [[ ! -f "${target_dir}/skills/ivan-writing/.cursor-managed" ]]; then
          printf 'Would preserve existing %s/skills/ivan-writing (not managed by this helper)\n' "${target_dir}"
        fi
      fi
      ;;
  esac
  report_cursor_skill_decisions "${target_dir}"
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

backup_agents_skill() {
  local target_dir="$1"
  local skill_name="$2"
  local path="${AGENTS_SKILLS_DIR}/${skill_name}"
  if [[ -e "${path}" || -L "${path}" ]]; then
    if [[ -z "${BACKUP_DIR}" ]]; then
      BACKUP_DIR="${target_dir}/.backup/${BACKUP_BASENAME}"
      mkdir -p "${BACKUP_DIR}"
    fi
    mkdir -p "${BACKUP_DIR}/agents-skills"
    cp -a "${path}" "${BACKUP_DIR}/agents-skills/${skill_name}"
  fi
}

install_canonical_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local source="${REPO_ROOT}/.apm/skills/${skill_name}"

  mkdir -p "${AGENTS_SKILLS_DIR}"
  backup_agents_skill "${target_dir}" "${skill_name}"
  rm -rf "${AGENTS_SKILLS_DIR}/${skill_name}"
  mkdir -p "${AGENTS_SKILLS_DIR}/${skill_name}"
  cp -a "${source}/." "${AGENTS_SKILLS_DIR}/${skill_name}/"
  printf 'Copied canonical skills/%s -> %s\n' "${skill_name}" "${AGENTS_SKILLS_DIR}/${skill_name}"
}

install_personal_skill() {
  local skill_name="$1"
  local target_dir="$2"
  local source="${REPO_ROOT}/profiles/personal/skills/${skill_name}"

  mkdir -p "${AGENTS_SKILLS_DIR}"
  backup_agents_skill "${target_dir}" "${skill_name}"
  rm -rf "${AGENTS_SKILLS_DIR}/${skill_name}"
  mkdir -p "${AGENTS_SKILLS_DIR}/${skill_name}"
  cp -a "${source}/." "${AGENTS_SKILLS_DIR}/${skill_name}/"
  touch "${AGENTS_SKILLS_DIR}/${skill_name}/.cursor-managed"
  printf 'Copied personal skills/%s -> %s\n' "${skill_name}" "${AGENTS_SKILLS_DIR}/${skill_name}"
}

install_assets_into() {
  local root="$1"
  local target_dir="$2"
  local name rendered

  BACKUP_DIR=""
  mkdir -p "${target_dir}/agents" "${target_dir}/commands" "${target_dir}/skills"

  for name in "${AGENTS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/agents/${name}.md"
    rm -rf "${target_dir}/agents/${name}.md"
    rendered="$(mktemp "${target_dir}/agents/.${name}.XXXXXX")"
    render_agent "${root}" "${name}" > "${rendered}"
    install -m 0644 "${rendered}" "${target_dir}/agents/${name}.md"
    rm -f "${rendered}"
    printf 'Copied agents/%s.md with pinned Engineering Judgment appended -> %s\n' "${name}" "${target_dir}/agents/${name}.md"
  done
  for name in "${COMMANDS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/commands/${name}.md"
    rm -rf "${target_dir}/commands/${name}.md"
    install -m 0644 "${root}/commands/${name}.md" "${target_dir}/commands/${name}.md"
    printf 'Copied commands/%s.md -> %s\n' "${name}" "${target_dir}/commands/${name}.md"
  done
  for name in "${SHARED_COMMANDS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/commands/${name}.md"
    rm -rf "${target_dir}/commands/${name}.md"
    install -m 0644 "${REPO_ROOT}/.apm/prompts/${name}.prompt.md" "${target_dir}/commands/${name}.md"
    printf 'Copied canonical .apm/prompts/%s.prompt.md -> %s\n' "${name}" "${target_dir}/commands/${name}.md"
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

  local cursor_ivan="${target_dir}/skills/ivan-writing"
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      install_personal_skill "ivan-writing" "${target_dir}"
      ;;
    '')
      if [[ -d "${AGENTS_SKILLS_DIR}/ivan-writing" && -r "${AGENTS_SKILLS_DIR}/ivan-writing" && -x "${AGENTS_SKILLS_DIR}/ivan-writing" && ! -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]]; then
        printf 'Preserved existing agents-dir ivan-writing (not managed by this helper)\n'
      fi
      if [[ -e "${cursor_ivan}" || -L "${cursor_ivan}" ]]; then
        if ! ivan_marker_unobservable "${cursor_ivan}" && [[ ! -f "${cursor_ivan}/.cursor-managed" ]]; then
          printf 'Preserved existing skills/ivan-writing (not managed by this helper)\n'
        fi
      fi
      ;;
  esac
  report_cursor_skill_decisions "${target_dir}"

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
    for name in "${COMMANDS[@]}" "${SHARED_COMMANDS[@]}"; do
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
    for name in "${SKILLS[@]}"; do
      if [[ -e "${target}/skills/${name}" || -L "${target}/skills/${name}" ]]; then
        check_recursive_readable "${target}/skills/${name}" "target/skills/${name}" || return 1
      fi
    done
  fi

  if [[ -d "${AGENTS_SKILLS_DIR}" ]]; then
    for name in "${CANONICAL_SKILLS[@]}"; do
      if [[ -e "${AGENTS_SKILLS_DIR}/${name}" || -L "${AGENTS_SKILLS_DIR}/${name}" ]]; then
        check_recursive_readable "${AGENTS_SKILLS_DIR}/${name}" "agents-skills/${name}" || return 1
      fi
    done
    case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
      1)
        if [[ -e "${AGENTS_SKILLS_DIR}/ivan-writing" || -L "${AGENTS_SKILLS_DIR}/ivan-writing" ]]; then
          check_recursive_readable "${AGENTS_SKILLS_DIR}/ivan-writing" "agents-skills/ivan-writing" || return 1
        fi
        ;;
    esac
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

preflight_agents_skills_dir() {
  local dir="${AGENTS_SKILLS_DIR}"
  local parent
  if [[ -e "${dir}" || -L "${dir}" ]]; then
    if [[ -L "${dir}" || ! -d "${dir}" ]]; then
      printf 'ERROR: AGENTS_SKILLS_DIR exists and is not a directory: %s\n' "${dir}" >&2
      return 1
    fi
    if [[ ! -w "${dir}" || ! -x "${dir}" ]]; then
      printf 'ERROR: AGENTS_SKILLS_DIR is not writable/traversable: %s\n' "${dir}" >&2
      return 1
    fi
    return 0
  fi
  parent="${dir}"
  while [[ ! -e "${parent}" && ! -L "${parent}" && "${parent}" != "/" ]]; do
    parent="$(dirname "${parent}")"
  done
  if [[ ! -d "${parent}" || ! -w "${parent}" || ! -x "${parent}" ]]; then
    printf 'ERROR: cannot create AGENTS_SKILLS_DIR: %s\n' "${dir}" >&2
    return 1
  fi
}

# Portable stand-in for GNU `realpath -m`: resolve the longest existing
# directory prefix physically, then apply the missing components lexically.
resolve_path() {
  local path="$1" head tail="" part resolved
  [[ "${path}" == /* ]] || path="${PWD}/${path}"
  while [[ "${path}" == //* ]]; do path="${path#/}"; done
  head="${path}"
  while [[ ! -d "${head}" ]]; do
    tail="${head##*/}/${tail}"
    head="${head%/*}"
    [[ -n "${head}" ]] || head="/"
  done
  resolved="$(cd -P -- "${head}" && pwd -P)" || return 1
  while [[ -n "${tail}" ]]; do
    part="${tail%%/*}"
    tail="${tail#*/}"
    case "${part}" in
      ''|.) ;;
      ..) resolved="${resolved%/*}"; [[ -n "${resolved}" ]] || resolved="/" ;;
      *)
        resolved="${resolved%/}/${part}"
        if [[ -d "${resolved}" ]]; then
          resolved="$(cd -P -- "${resolved}" && pwd -P)" || return 1
        fi
        ;;
    esac
  done
  printf '%s\n' "${resolved}"
}

same_resolved_path() {
  local left right
  left="$(resolve_path "$1")" || return 1
  right="$(resolve_path "$2")" || return 1
  [[ "${left}" == "${right}" ]]
}

abort_if_agents_skills_aliased() {
  local other="$1"
  local label="$2"
  if same_resolved_path "${AGENTS_SKILLS_DIR}" "${other}"; then
    printf 'ERROR: AGENTS_SKILLS_DIR resolves to the same directory as %s (%s)\n' "${label}" "${other}" >&2
    return 1
  fi
}

preflight_agents_skills_alias() {
  local target_dir
  for target_dir in "${TARGETS[@]}"; do
    abort_if_agents_skills_aliased "${target_dir}" "Cursor target" || return 1
    abort_if_agents_skills_aliased "${target_dir}/skills" "Cursor target skills directory" || return 1
  done
}

install_assets() {
  local root="$1"
  local target_dir

  collect_targets
  preflight_agents_skills_alias || exit 1
  preflight_agents_skills_dir || exit 1
  preflight_targets "${TARGETS[@]}" || exit 1

  DECISION_COUNT=0
  AGENTS_IVAN_OPT_OUT_NOTED=0
  AGENTS_HIVE_BUNDLED_NOTED=""
  for target_dir in "${TARGETS[@]}"; do
    install_assets_into "${root}" "${target_dir}"
  done

  printf 'Manual next step: paste the output of ./scripts/cursor-assets.sh print-rules into Cursor Customize -> Rules -> User Rules.\n'
  exit_if_skill_decisions
}

print_all_copy_plans() {
  local root="$1"
  local target_dir

  collect_targets
  preflight_agents_skills_alias || exit 1
  preflight_agents_skills_dir || exit 1
  preflight_targets "${TARGETS[@]}" || exit 1

  DECISION_COUNT=0
  AGENTS_IVAN_OPT_OUT_NOTED=0
  AGENTS_HIVE_BUNDLED_NOTED=""
  for target_dir in "${TARGETS[@]}"; do
    print_copy_plan "${root}" "${target_dir}"
  done
  exit_if_skill_decisions
}

main() {
  local command="${1:-}"
  local root name agent_known

  case "${command}" in
    validate)
      preflight_env
      root="$(source_root)"
      validate_assets "${root}"
      validate_rules "${root}"
      validate_cursor_hive_skills
      printf 'Cursor asset validation passed\n'
      ;;
    install)
      preflight_env
      root="$(source_root)"
      case "${2:-}" in
        '')
          validate_assets "${root}"
          validate_rules "${root}"
          validate_cursor_hive_skills
          install_assets "${root}"
          ;;
        --dry-run)
          validate_assets "${root}"
          validate_rules "${root}"
          validate_cursor_hive_skills
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
      printf '%s' "${COMPOSE_SEPARATOR}"
      cat "${EJ_SOURCE}"
      ;;
    print-agent)
      root="$(source_root)"
      validate_rules "${root}"
      agent_known=0
      for name in "${AGENTS[@]}"; do
        if [[ "${name}" == "${2:-}" ]]; then
          agent_known=1
        fi
      done
      if [[ "${agent_known}" -ne 1 ]]; then
        usage
        exit 1
      fi
      render_agent "${root}" "${2}"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
