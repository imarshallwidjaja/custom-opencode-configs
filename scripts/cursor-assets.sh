#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TARGET_DIR="${CURSOR_CONFIG_DIR:-${HOME}/.cursor}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"
REFLECT_SOURCE="${REPO_ROOT}/.apm/prompts/reflect.prompt.md"

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
  agents-md-mastery
  brainstorming
  finishing-a-development-branch
  subagent-delegation
  systematic-debugging
  test-driven-development
  using-git-worktrees
  verification
)
RETIRED_SKILLS=(
  consolidate-test-suites
  root-cause-finder
)

CANONICAL_SKILLS=(
  connecting-atlassian-tools
  cymbal
  decomposing-work
  drawio-skill
  frontend-slides
  hard-cut
  humanizer
  managing-work-in-jira
  react-best-practices
  resume-tailoring
  running-agile-delivery
  stop-design-slop
  stop-slop
  use-railway
  web-design-guidelines
  working-with-atlassian
  writing-for-humans
  writing-work-items
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
stale_reflect = root / 'commands' / 'reflect.md'
if stale_reflect.exists() or stale_reflect.is_symlink():
    fail('stale duplicate commands/reflect.md is present; use canonical .apm/prompts/reflect.prompt.md')
check_exact_names(root / 'commands', '.md', expected_commands, 'commands')

reflect_source = repo_root / '.apm' / 'prompts' / 'reflect.prompt.md'
if reflect_source.is_symlink() or not reflect_source.is_file():
    fail('missing canonical reflect source: .apm/prompts/reflect.prompt.md')
else:
    reflect_frontmatter = parse_frontmatter(reflect_source, allowed_keys={'description'})
    if not reflect_frontmatter.get('description'):
        fail('.apm/prompts/reflect.prompt.md frontmatter has empty description')
    check_forbidden_content(reflect_source)

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
            'scripts/deploy.sh',
            'scripts/export-pdf.sh',
            'scripts/extract-pptx.py',
            'viewport-base.css',
        ),
        WRITING_ALLOWED_KEYS,
    ),
    (
        repo_root / '.apm' / 'skills' / 'humanizer',
        'humanizer',
        ('SKILL.md', 'references', 'references/patterns.md'),
        WRITING_ALLOWED_KEYS,
    ),
    (
        repo_root / '.apm' / 'skills' / 'stop-design-slop',
        'stop-design-slop',
        (
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
        ),
        None,
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
    (
        repo_root / '.apm' / 'skills' / 'writing-for-humans',
        'writing-for-humans',
        (
            'SKILL.md',
            'references',
            'references/examples.md',
            'references/sources.md',
        ),
        WRITING_ALLOWED_KEYS,
        True,
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
        repo_root / '.apm' / 'skills' / 'web-design-guidelines',
        'web-design-guidelines',
        ('SKILL.md',),
        None,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'use-railway',
        'use-railway',
        (
            'SKILL.md',
            'references',
            'references/analyze-db-mongo.md',
            'references/analyze-db-mysql.md',
            'references/analyze-db-postgres.md',
            'references/analyze-db-redis.md',
            'references/analyze-db.md',
            'references/configure.md',
            'references/deploy.md',
            'references/feature-flags.md',
            'references/iac.md',
            'references/operate.md',
            'references/request.md',
            'references/sandbox.md',
            'references/setup.md',
            'scripts',
            'scripts/analyze-mongo.py',
            'scripts/analyze-mysql.py',
            'scripts/analyze-postgres.py',
            'scripts/analyze-redis.py',
            'scripts/dal.py',
            'scripts/enable-pg-stats.py',
            'scripts/pg-extensions.py',
            'scripts/railway-api.sh',
        ),
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
        repo_root / '.apm' / 'skills' / 'connecting-atlassian-tools',
        'connecting-atlassian-tools',
        ('SKILL.md',),
        WRITING_ALLOWED_KEYS,
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
        repo_root / '.apm' / 'skills' / 'managing-work-in-jira',
        'managing-work-in-jira',
        ('SKILL.md',),
        WRITING_ALLOWED_KEYS,
        False,
    ),
    (
        repo_root / '.apm' / 'skills' / 'running-agile-delivery',
        'running-agile-delivery',
        ('SKILL.md',),
        WRITING_ALLOWED_KEYS,
        True,
    ),
    (
        repo_root / '.apm' / 'skills' / 'working-with-atlassian',
        'working-with-atlassian',
        (
            'SKILL.md',
            'references',
            'references/jql-essentials.md',
        ),
        WRITING_ALLOWED_KEYS,
        False,
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
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
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
    match = pattern.search(composed_text)
    if match:
        print(f'Cursor rules validation failed: composed Rules contain {label}: {match.group(0)}', file=sys.stderr)
        sys.exit(1)
PY
}

validate_cursor_hive_skills() {
  check_python
  python3 - "${REPO_ROOT}" <<'PY'
import hashlib
import json
import re
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
provenance_path = repo_root / 'vendor' / 'oc-arkive' / 'cursor-skills' / 'provenance.json'
expected_names = (
    'brainstorming',
    'systematic-debugging',
    'test-driven-development',
    'verification',
)
expected_skill_keys = {'sourcePath', 'sourceSha256', 'installedSha256'}
expected_root_keys = {
    'schemaVersion',
    'upstreamRepository',
    'commit',
    'packageVersion',
    'skills',
}

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
if type(provenance['schemaVersion']) is not int or provenance['schemaVersion'] != 1:
    fail('provenance schemaVersion must be integer 1')
if not isinstance(provenance['upstreamRepository'], str) or not provenance['upstreamRepository']:
    fail('provenance upstreamRepository must be a non-empty string')
if not isinstance(provenance['commit'], str) or not re.fullmatch(r'[0-9a-f]{40}', provenance['commit']):
    fail('provenance commit must be an immutable full lowercase Git commit')
if not isinstance(provenance['packageVersion'], str) or not provenance['packageVersion']:
    fail('provenance packageVersion must be a non-empty string')
skills = provenance['skills']
if not isinstance(skills, dict) or set(skills) != set(expected_names):
    fail(f'provenance skills must be exactly {list(expected_names)}')

for name in expected_names:
    entry = skills[name]
    label = f'provenance skills.{name}'
    if not isinstance(entry, dict) or set(entry) != expected_skill_keys:
        fail(f'{label} keys must be exactly {sorted(expected_skill_keys)}')
    source_path = entry['sourcePath']
    expected_source = f'packages/opencode-hive/skills/{name}/SKILL.md'
    if not isinstance(source_path, str) or source_path != expected_source:
        fail(f'{label} sourcePath must be {expected_source}')
    for field in ('sourceSha256', 'installedSha256'):
        value = entry[field]
        if not isinstance(value, str) or not re.fullmatch(r'[0-9a-f]{64}', value):
            fail(f'{label} {field} must be a lowercase SHA-256')
    skill_path = repo_root / '.apm' / 'cursor' / 'skills' / name / 'SKILL.md'
    require_regular_file(skill_path, f'.apm/cursor/skills/{name}/SKILL.md', skill_path.parent)
    skill_bytes = skill_path.read_bytes()
    actual_hash = hashlib.sha256(skill_bytes).hexdigest()
    expected_hash = entry['installedSha256']
    if actual_hash != expected_hash:
        fail(
            f'.apm/cursor/skills/{name}/SKILL.md SHA-256 is {actual_hash}, expected {expected_hash}'
        )
    try:
        skill_text = skill_bytes.decode('utf-8')
    except UnicodeDecodeError as error:
        fail(f'.apm/cursor/skills/{name}/SKILL.md is not valid UTF-8: {error}')
    if 'skill(' in skill_text:
        fail(f'.apm/cursor/skills/{name}/SKILL.md contains skill(')
    if 'writing-plans' in skill_text:
        fail(f'.apm/cursor/skills/{name}/SKILL.md contains writing-plans as a skill-call target')
    if name == 'systematic-debugging':
        if 'root-cause-finder' in skill_text:
            fail(f'.apm/cursor/skills/{name}/SKILL.md contains root-cause-finder')
        if 'first unintended' not in skill_text and 'hidden write' not in skill_text:
            fail(f'.apm/cursor/skills/{name}/SKILL.md is missing the inlined downstream-symptom protocol')
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
  printf 'Would copy canonical .apm/prompts/reflect.prompt.md -> %s\n' "${target_dir}/commands/reflect.md"
  for name in "${SKILLS[@]}"; do
    source="${root}/skills/${name}"
    printf 'Would copy %s -> %s\n' "${source#"${root}/"}" "${target_dir}/skills/${name}"
  done
  for name in "${RETIRED_SKILLS[@]}"; do
    if [[ -e "${target_dir}/skills/${name}" || -L "${target_dir}/skills/${name}" ]]; then
      printf 'Would back up and remove leftover %s/skills/%s\n' "${target_dir}" "${name}"
    fi
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    printf 'Would copy canonical .apm/skills/%s -> %s/%s\n' "${name}" "${AGENTS_SKILLS_DIR}" "${name}"
    if [[ -e "${target_dir}/skills/${name}" || -L "${target_dir}/skills/${name}" ]]; then
      printf 'Would back up and remove stale %s/skills/%s\n' "${target_dir}" "${name}"
    fi
  done
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      printf 'Would copy personal profiles/personal/skills/ivan-writing -> %s/ivan-writing (CURSOR_INSTALL_IVAN_WRITING=1)\n' "${AGENTS_SKILLS_DIR}"
      if [[ -e "${target_dir}/skills/ivan-writing" || -L "${target_dir}/skills/ivan-writing" ]]; then
        printf 'Would back up and remove stale %s/skills/ivan-writing\n' "${target_dir}"
      fi
      ;;
    '')
      local marker="${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed"
      if [[ -f "${marker}" ]]; then
        printf 'Would back up and remove previously managed %s/ivan-writing (CURSOR_INSTALL_IVAN_WRITING unset, opt-out effective)\n' "${AGENTS_SKILLS_DIR}"
      elif [[ -d "${AGENTS_SKILLS_DIR}/ivan-writing" ]]; then
        printf 'Would preserve existing %s/ivan-writing (not managed by this helper)\n' "${AGENTS_SKILLS_DIR}"
      fi
      if [[ -e "${target_dir}/skills/ivan-writing" || -L "${target_dir}/skills/ivan-writing" ]]; then
        if [[ -f "${target_dir}/skills/ivan-writing/.cursor-managed" ]]; then
          printf 'Would back up and remove previously managed %s/skills/ivan-writing (CURSOR_INSTALL_IVAN_WRITING unset, opt-out effective)\n' "${target_dir}"
        else
          printf 'Would preserve existing %s/skills/ivan-writing (not managed by this helper)\n' "${target_dir}"
        fi
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

backup_agents_skill() {
  local target_dir="$1"
  local skill_name="$2"
  local path="${AGENTS_SKILLS_DIR}/${skill_name}"
  if [[ -e "${path}" ]]; then
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
  if [[ -e "${target_dir}/skills/${skill_name}" || -L "${target_dir}/skills/${skill_name}" ]]; then
    backup_path "${target_dir}" "${target_dir}/skills/${skill_name}"
    rm -rf "${target_dir}/skills/${skill_name}"
  fi
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
  if [[ -e "${target_dir}/skills/${skill_name}" || -L "${target_dir}/skills/${skill_name}" ]]; then
    backup_path "${target_dir}" "${target_dir}/skills/${skill_name}"
    rm -rf "${target_dir}/skills/${skill_name}"
  fi
  printf 'Copied personal skills/%s -> %s\n' "${skill_name}" "${AGENTS_SKILLS_DIR}/${skill_name}"
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
  backup_path "${target_dir}" "${target_dir}/commands/reflect.md"
  rm -rf "${target_dir}/commands/reflect.md"
  install -m 0644 "${REFLECT_SOURCE}" "${target_dir}/commands/reflect.md"
  printf 'Copied canonical .apm/prompts/reflect.prompt.md -> %s\n' "${target_dir}/commands/reflect.md"
  for name in "${SKILLS[@]}"; do
    backup_path "${target_dir}" "${target_dir}/skills/${name}"
    rm -rf "${target_dir}/skills/${name}"
    mkdir -p "${target_dir}/skills/${name}"
    cp -a "${root}/skills/${name}/." "${target_dir}/skills/${name}/"
    printf 'Copied skills/%s -> %s\n' "${name}" "${target_dir}/skills/${name}"
  done
  for name in "${RETIRED_SKILLS[@]}"; do
    if [[ -e "${target_dir}/skills/${name}" || -L "${target_dir}/skills/${name}" ]]; then
      backup_path "${target_dir}" "${target_dir}/skills/${name}"
      rm -rf "${target_dir}/skills/${name}"
      printf 'Backed up and removed leftover skills/%s\n' "${name}"
    fi
  done
  for name in "${CANONICAL_SKILLS[@]}"; do
    install_canonical_skill "${name}" "${target_dir}"
  done

  local marker="${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed"
  local cursor_ivan="${target_dir}/skills/ivan-writing"
  case "${CURSOR_INSTALL_IVAN_WRITING:-}" in
    1)
      install_personal_skill "ivan-writing" "${target_dir}"
      ;;
    '')
      if [[ -d "${AGENTS_SKILLS_DIR}/ivan-writing" ]]; then
        if [[ -f "${marker}" ]]; then
          backup_agents_skill "${target_dir}" "ivan-writing"
          rm -rf "${AGENTS_SKILLS_DIR}/ivan-writing"
          printf 'Backed up and removed previously managed ivan-writing from agents dir (opt-out effective)\n'
        else
          printf 'Preserved existing agents-dir ivan-writing (not managed by this helper)\n'
        fi
      fi
      if [[ -e "${cursor_ivan}" || -L "${cursor_ivan}" ]]; then
        if [[ -f "${cursor_ivan}/.cursor-managed" ]]; then
          backup_path "${target_dir}" "${cursor_ivan}"
          rm -rf "${cursor_ivan}"
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
    for name in "${COMMANDS[@]}" reflect; do
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
    for name in "${SKILLS[@]}" "${RETIRED_SKILLS[@]}" "${CANONICAL_SKILLS[@]}" ivan-writing; do
      if [[ -e "${target}/skills/${name}" || -L "${target}/skills/${name}" ]]; then
        check_recursive_readable "${target}/skills/${name}" "target/skills/${name}" || return 1
      fi
    done
  fi

  if [[ -d "${AGENTS_SKILLS_DIR}" ]]; then
    for name in "${CANONICAL_SKILLS[@]}" ivan-writing; do
      if [[ -e "${AGENTS_SKILLS_DIR}/${name}" || -L "${AGENTS_SKILLS_DIR}/${name}" ]]; then
        check_recursive_readable "${AGENTS_SKILLS_DIR}/${name}" "agents-skills/${name}" || return 1
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

  for target_dir in "${TARGETS[@]}"; do
    install_assets_into "${root}" "${target_dir}"
  done

  printf 'Manual next step: paste the output of ./scripts/cursor-assets.sh print-rules into Cursor Customize -> Rules -> User Rules.\n'
}

print_all_copy_plans() {
  local root="$1"
  local target_dir

  collect_targets
  preflight_agents_skills_alias || exit 1
  preflight_agents_skills_dir || exit 1
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
      printf '\n---\n\n'
      cat "${REPO_ROOT}/vendor/oc-arkive/engineering-judgment/engineering-judgment.md"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
