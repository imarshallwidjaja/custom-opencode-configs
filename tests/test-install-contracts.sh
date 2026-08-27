#!/usr/bin/env bash
# Integration test for durable install contracts.
# Builds isolated minimal repository fixtures under its temp directory.
# Never moves, deletes, or mutates repository source directories.
set -euo pipefail

PASS=0
FAIL=0
FAIL_NAMES=()

pass() { PASS=$((PASS+1)); printf '  PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); FAIL_NAMES+=("$1"); printf '  FAIL: %s\n' "$1"; }

# --- fixture helpers ---------------------------------------------------------

BUILDER_DIR="$(cd "$(dirname "$0")" && pwd)/.."
BASELINE_PWD="$(cd "${BUILDER_DIR}" && pwd)"
TMPDIR="$(mktemp -d)"

REPO_FIXTURE="${TMPDIR}/reporoot"

stub_canonical_skill_tree() {
  local skill_name="$1"
  python3 - "$BASELINE_PWD" "$REPO_FIXTURE" "$skill_name" <<'PY'
import sys
from pathlib import Path

repo = Path(sys.argv[1])
fixture = Path(sys.argv[2])
name = sys.argv[3]
src = repo / '.apm' / 'skills' / name
dest = fixture / '.apm' / 'skills' / name
if not src.is_dir():
    raise SystemExit(f'missing real skill source for fixture stub: {src}')
for path in sorted(src.rglob('*')):
    rel = path.relative_to(src)
    if any(part in {'.venv', '__pycache__'} for part in rel.parts):
        continue
    target = dest / rel
    if path.is_dir():
        target.mkdir(parents=True, exist_ok=True)
        continue
    target.parent.mkdir(parents=True, exist_ok=True)
    if path.name == 'SKILL.md':
        target.write_text(
            f'---\nname: {name}\ndescription: Use when testing fixture canonical skill {name}.\n---\nOK\n',
            encoding='utf-8',
        )
    elif path.suffix.lower() == '.gz':
        target.write_bytes(b'\x1f\x8b\x08\x00\x00\x00\x00\x00\x00\x03\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00')
    else:
        target.write_text('stub\n', encoding='utf-8')
PY
}

build_fixture() {
  rm -rf "${REPO_FIXTURE}"
  mkdir -p "${REPO_FIXTURE}"

  # Canonical skills (.apm/skills/)
  for skill in humanizer stop-slop writing-for-humans context-mode cymbal hard-cut web-design-guidelines writing-skills; do
    mkdir -p "${REPO_FIXTURE}/.apm/skills/${skill}"
    cat > "${REPO_FIXTURE}/.apm/skills/${skill}/SKILL.md" <<SKILL
---
name: ${skill}
description: Use when testing fixture canonical skill ${skill}.
---
OK
SKILL
  done

  # humanizer references
  mkdir -p "${REPO_FIXTURE}/.apm/skills/humanizer/references"
  echo "# Patterns" > "${REPO_FIXTURE}/.apm/skills/humanizer/references/patterns.md"

  # stop-slop references
  mkdir -p "${REPO_FIXTURE}/.apm/skills/stop-slop/references"
  echo "# Examples" > "${REPO_FIXTURE}/.apm/skills/stop-slop/references/examples.md"
  echo "# Phrases" > "${REPO_FIXTURE}/.apm/skills/stop-slop/references/phrases.md"
  echo "# Structures" > "${REPO_FIXTURE}/.apm/skills/stop-slop/references/structures.md"
  echo "# README" > "${REPO_FIXTURE}/.apm/skills/stop-slop/README.md"
  echo "MIT License" > "${REPO_FIXTURE}/.apm/skills/stop-slop/LICENSE"

  # writing-for-humans references
  mkdir -p "${REPO_FIXTURE}/.apm/skills/writing-for-humans/references"
  echo "# Examples" > "${REPO_FIXTURE}/.apm/skills/writing-for-humans/references/examples.md"
  echo "# Sources" > "${REPO_FIXTURE}/.apm/skills/writing-for-humans/references/sources.md"

  stub_canonical_skill_tree frontend-slides
  stub_canonical_skill_tree drawio-skill
  stub_canonical_skill_tree stop-design-slop

  # Cursor asset root (.apm/cursor/)
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/agents" "${REPO_FIXTURE}/.apm/cursor/commands" "${REPO_FIXTURE}/.apm/cursor/skills" "${REPO_FIXTURE}/.apm/cursor/rules"

  # Cursor agents
  for agent in approach-advisor code-reviewer forager plan-reviewer scout simplicity-reviewer; do
    cat > "${REPO_FIXTURE}/.apm/cursor/agents/${agent}.md" <<AGENT
---
name: ${agent}
description: Test agent ${agent}
model: inherit
readonly: false
---
OK
AGENT
  done

  # Cursor commands
  for cmd in compact-summary council-directive council implementation-brief interview interview-drill-down planning-prompt; do
    echo "# ${cmd}" > "${REPO_FIXTURE}/.apm/cursor/commands/${cmd}.md"
  done

  # OpenCode prompt-backed commands
  mkdir -p "${REPO_FIXTURE}/.apm/prompts"
  cat > "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" <<'PROMPT'
---
description: Review this session and propose durable agent-memory learnings
---
Propose durable learnings and wait for operator approval before editing memory files.
PROMPT

  # Cursor rules
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/rules"
  cat > "${REPO_FIXTURE}/.apm/cursor/rules/default-agent.md" <<'RULES'
# Default Agent
Be helpful. Use plain language. Avoid Hive tools.
RULES

  # Provenance-pinned Engineering Judgment vendor
  mkdir -p "${REPO_FIXTURE}/vendor/oc-arkive/engineering-judgment"
  cat > "${REPO_FIXTURE}/vendor/oc-arkive/engineering-judgment/engineering-judgment.md" <<'JUDGMENT'
## Engineering Judgment

Fixture guidance.
JUDGMENT
  python3 - "${REPO_FIXTURE}/vendor/oc-arkive/engineering-judgment" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

directory = Path(sys.argv[1])
content = (directory / 'engineering-judgment.md').read_bytes()
provenance = {
    'schemaVersion': 1,
    'upstreamRepository': 'https://example.test/agent-hive.git',
    'commit': '0123456789abcdef0123456789abcdef01234567',
    'sourcePath': 'packages/opencode-hive/src/agents/engineering-judgment.ts',
    'packageVersion': '9.8.7',
    'sha256': hashlib.sha256(content).hexdigest(),
}
(directory / 'provenance.json').write_text(
    json.dumps(provenance, indent=2) + '\n',
    encoding='utf-8',
    newline='\n',
)
PY

  # Cursor skills
  for skill in agents-md-mastery brainstorming consolidate-test-suites finishing-a-development-branch root-cause-finder subagent-delegation systematic-debugging test-driven-development use-railway using-git-worktrees verification; do
    mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/${skill}"
    cat > "${REPO_FIXTURE}/.apm/cursor/skills/${skill}/SKILL.md" <<SKILL
---
name: ${skill}
description: Use when testing fixture Cursor skill ${skill}.
---
OK
SKILL
  done

  # use-railway needs references and scripts (real bundle has them)
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/references"
  for ref in analyze-db-mongo analyze-db-mysql analyze-db-postgres analyze-db-redis analyze-db configure deploy operate request setup; do
    echo "# ${ref}" > "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/references/${ref}.md"
  done
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/scripts"
  for script in analyze-mongo analyze-mysql analyze-postgres analyze-redis dal enable-pg-stats pg-extensions; do
    echo "#!/usr/bin/env python3" > "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/scripts/${script}.py"
  done
  printf '%s\n' '#!/usr/bin/env bash' 'echo ok' > "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/scripts/railway-api.sh"
  chmod +x "${REPO_FIXTURE}/.apm/cursor/skills/use-railway/scripts/"*

  # Personal source
  mkdir -p "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references"
  cat > "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/SKILL.md" <<SKILL
---
name: ivan-writing
description: Use when testing fixture Ivan writing.
---
OK
SKILL
  echo "# Registers" > "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/registers.md"
  echo "# Examples" > "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/examples.md"

  # Agents profiles
  mkdir -p "${REPO_FIXTURE}/profiles/agents"
  for prof in shared personal-default shared-context-improved personal-context-improved; do
    echo "# ${prof} profile" > "${REPO_FIXTURE}/profiles/agents/${prof}.md"
  done

  # Base install payloads, plus obsolete root-path decoys
  mkdir -p "${REPO_FIXTURE}/profiles/base"
  echo '{"source":"profiles/base/opencode.json"}' > "${REPO_FIXTURE}/profiles/base/opencode.json"
  echo '{"source":"profiles/base/agent_hive.json"}' > "${REPO_FIXTURE}/profiles/base/agent_hive.json"
  mkdir -p "${REPO_FIXTURE}/profiles/base/plugins"
  printf '%s\n' '// fixture dcg-guard' > "${REPO_FIXTURE}/profiles/base/plugins/dcg-guard.js"
  echo '{"source":"obsolete-root/opencode.json"}' > "${REPO_FIXTURE}/opencode.json"
  echo '{"source":"obsolete-root/agent_hive.json"}' > "${REPO_FIXTURE}/agent_hive.json"
  echo '{}' > "${REPO_FIXTURE}/apm.yml"
  mkdir -p "${REPO_FIXTURE}/scripts"
  printf '#!/bin/true\n' > "${REPO_FIXTURE}/scripts/enable-optional.sh"
  chmod +x "${REPO_FIXTURE}/scripts/enable-optional.sh"

  # Copy real scripts so BASH_SOURCE resolves the fixture root.
  cp "${BASELINE_PWD}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/cursor-assets.sh"
  cp "${BASELINE_PWD}/scripts/install-profile.sh" "${REPO_FIXTURE}/scripts/install-profile.sh"
  if [[ -f "${BASELINE_PWD}/scripts/sync-engineering-judgment.py" ]]; then
    cp "${BASELINE_PWD}/scripts/sync-engineering-judgment.py" "${REPO_FIXTURE}/scripts/sync-engineering-judgment.py"
  fi
  chmod +x "${REPO_FIXTURE}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/install-profile.sh"
  [[ ! -f "${REPO_FIXTURE}/scripts/sync-engineering-judgment.py" ]] || chmod +x "${REPO_FIXTURE}/scripts/sync-engineering-judgment.py"
}

CURSOR_HELPER="${REPO_FIXTURE}/scripts/cursor-assets.sh"
INSTALL_HELPER="${REPO_FIXTURE}/scripts/install-profile.sh"

cleanup() {
  chmod -R +rwX "${TMPDIR}" 2>/dev/null || true
  rm -rf "${TMPDIR}"
}
trap cleanup EXIT

snapshot_tree() {
  python3 - "$1" <<'PY'
import hashlib
import os
import stat
import sys
from pathlib import Path

root = Path(sys.argv[1])
if not os.path.lexists(str(root)):
    print('<missing>')
    raise SystemExit

for path in [root, *sorted(root.rglob('*'), key=lambda item: str(item.relative_to(root)))]:
    relative = '.' if path == root else str(path.relative_to(root))
    metadata = path.lstat()
    if stat.S_ISLNK(metadata.st_mode):
        detail = f'link:{os.readlink(path)}'
    elif stat.S_ISREG(metadata.st_mode):
        try:
            detail = f'file:{hashlib.sha256(path.read_bytes()).hexdigest()}'
        except PermissionError:
            detail = 'file:UNREADABLE'
    elif stat.S_ISDIR(metadata.st_mode):
        detail = 'dir'
    else:
        detail = f'other:{stat.S_IFMT(metadata.st_mode)}'
    print(f'{relative}\t{stat.S_IMODE(metadata.st_mode):04o}\t{detail}')
PY
}

tracked_markdown_uses_canonical_cursor_destination() {
  python3 - "$1" <<'PY'
import os
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
obsolete = 'Cursor Settings -> Rules'
tracked = subprocess.run(
    ['git', '-C', str(root), 'ls-files', '-z'],
    check=True,
    stdout=subprocess.PIPE,
).stdout.split(b'\0')
errors = []
for raw_relative in tracked:
    if not raw_relative:
        continue
    relative = Path(os.fsdecode(raw_relative))
    if relative.suffix != '.md':
        continue
    path = root / relative
    if path.is_file() and obsolete in path.read_text(encoding='utf-8', errors='ignore'):
        errors.append(str(relative))
if errors:
    raise SystemExit(f'obsolete Cursor Rules destination found in: {", ".join(errors)}')
PY
}

cursor_target_unmodified() {
  local dir="$1"
  [[ ! -e "${dir}/agents" && ! -e "${dir}/commands" && ! -e "${dir}/skills" && ! -e "${dir}/.backup" ]]
}

opencode_target_unmodified() {
  local dir="$1"
  [[ ! -e "${dir}/opencode.json" && ! -e "${dir}/agent_hive.json" && ! -e "${dir}/AGENTS.md" && ! -e "${dir}/agents" && ! -e "${dir}/commands" && ! -e "${dir}/skills" && ! -e "${dir}/.backup" ]]
}

replace_fixture_text() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
old = sys.argv[2]
new = sys.argv[3]
text = path.read_text(encoding='utf-8')
if old not in text:
    raise SystemExit(f'fixture text not found in {path}: {old}')
path.write_text(text.replace(old, new, 1), encoding='utf-8')
PY
}

# ---------------------------------------------------------------------------
# Ensure fresh fixture
build_fixture

# Preflight: helpers exist
# ---------------------------------------------------------------------------
printf '=== Preflight: helpers exist ===\n'
if [[ -x "${CURSOR_HELPER}" ]]; then pass "cursor-assets.sh exists and is executable"; else fail "cursor-assets.sh missing or not executable"; fi
if [[ -x "${INSTALL_HELPER}" ]]; then pass "install-profile.sh exists and is executable"; else fail "install-profile.sh missing or not executable"; fi
if [[ -f "${BASELINE_PWD}/profiles/base/opencode.json" && -f "${BASELINE_PWD}/profiles/base/agent_hive.json" ]]; then pass "base payloads live under profiles/base"; else fail "base payloads missing from profiles/base"; fi
if [[ ! -e "${BASELINE_PWD}/opencode.json" && ! -e "${BASELINE_PWD}/agent_hive.json" ]]; then pass "repository root has no auto-discovered config payloads"; else fail "repository root still contains config payloads"; fi
if [[ -f "${BASELINE_PWD}/.apm/prompts/reflect.prompt.md" ]]; then pass "canonical shared reflect prompt exists"; else fail "canonical shared reflect prompt missing"; fi
if [[ ! -e "${BASELINE_PWD}/.apm/cursor/commands/reflect.md" ]]; then pass "stale Cursor reflect duplicate is absent"; else fail "stale Cursor reflect duplicate still exists"; fi
if [[ -f "${BASELINE_PWD}/.apm/cursor/skills/agents-md-mastery/SKILL.md" ]]; then pass "Cursor agents-md-mastery skill exists"; else fail "Cursor agents-md-mastery skill missing"; fi

if python3 - "${BASELINE_PWD}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
prompt = root / ".apm/prompts/reflect.prompt.md"
errors = []
shared_markers = (
    "$arguments",
    "optional focus",
    "if `agents-md-mastery` is available",
    "operator accepts",
    "provisional cross-project operator preferences",
    "voice",
    "interaction style",
    "personification",
    "scratchpad",
    "global instructions",
    "cursor-user-rules:manual",
    "current rules text",
    "supplied or visible",
    "manual paste",
    "never claim to read or edit cursor settings",
    "not applied",
)

text = prompt.read_text(encoding="utf-8")
lowered = text.lower()
description = next((line.removeprefix("description: ") for line in text.splitlines() if line.startswith("description: ")), "")
if len(description) > 70:
    errors.append(f"canonical reflect description exceeds APM's 70-character semantic limit: {len(description)}")
if "do not edit" not in lowered:
    errors.append("canonical reflect prompt is missing its pre-write approval gate")
for marker in shared_markers:
    if marker not in lowered:
        errors.append(f"canonical reflect prompt is missing contract text: {marker}")
if "ivan" in lowered:
    errors.append("canonical reflect prompt contains Ivan-specific content")
if re.search(r"/(?:home|users)/[^/\s]+", lowered):
    errors.append("canonical reflect prompt contains an absolute home path")

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("ok")
PY
then
  pass "canonical reflect prompt preserves shared approval, personification, portability, and manual Cursor Rules contracts"
else
  fail "canonical reflect prompt preserves shared approval, personification, portability, and manual Cursor Rules contracts"
fi

if python3 - "${BASELINE_PWD}/.apm/cursor/skills/agents-md-mastery/SKILL.md" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit("Cursor agents-md-mastery skill is missing")
text = path.read_text(encoding="utf-8")
lowered = text.lower()
contracts = (
    "evidence before durable instructions",
    "signal",
    "noise",
    "hard-won safety",
    "item-level approval",
    "scratchpad",
    "cursor user rules",
    "paste-ready",
    "manual instructions",
    "nested agents.md",
    "observable behavior",
    "generic best practices",
    "bootstrap",
    "prune",
)
missing = [contract for contract in contracts if contract not in lowered]
if missing:
    raise SystemExit(f"skill is missing behavioral contracts: {missing}")
if not re.search(r"one-off preferences.{0,120}(?:may|can).{0,120}(?:provisional|provisionally).{0,120}scratchpad", lowered, re.DOTALL):
    raise SystemExit("skill must allow one-off preferences to be captured provisionally in scratchpad")
if not re.search(r"(?:must not|do not).{0,160}(?:project instructions|project agents\.md).{0,160}global instructions.{0,160}cursor user rules.{0,200}(?:repeated|mature).{0,80}evidence", lowered, re.DOTALL):
    raise SystemExit("skill must reserve promotion beyond scratchpad for repeated or mature evidence")
if not re.search(r"only after.{0,80}(?:exact )?proposal.{0,80}item-level approval", lowered, re.DOTALL):
    raise SystemExit("skill must require proposal and item-level approval before any accepted scratchpad write")
for pattern, label in (
    (r"\.(?:hive)(?:/|\b)", ".hive path"),
    (r"\b(?:agent hive|opencode)\b", "non-Cursor harness assumption"),
):
    match = re.search(pattern, lowered)
    if match:
        raise SystemExit(f"skill contains {label}: {match.group(0)}")
print("ok")
PY
then
  pass "Cursor agents-md-mastery durable-memory and harness-isolation contracts"
else
  fail "Cursor agents-md-mastery durable-memory and harness-isolation contracts"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])

def load(path):
    return (root / path).read_text(encoding="utf-8")

def section(markdown, title):
    lines = markdown.splitlines()
    wanted = title.casefold()
    start = None
    level = None
    for index, line in enumerate(lines):
        match = re.match(r"^(#{1,6})\s+(.+?)\s*$", line)
        if match and match.group(2).strip().casefold() == wanted:
            start = index + 1
            level = len(match.group(1))
            break
    if start is None:
        return ""
    end = len(lines)
    for index in range(start, len(lines)):
        match = re.match(r"^(#{1,6})\s+", lines[index])
        if match and len(match.group(1)) <= level:
            end = index
            break
    return "\n".join(lines[start:end]).casefold()

def route(section_text, name):
    for line in section_text.splitlines():
        if re.search(rf"(?<![\w-])`?{re.escape(name)}`?(?![\w-])\s*:", line):
            return line
    return ""

def require_terms(errors, label, text, groups):
    missing = []
    for group in groups:
        choices = (group,) if isinstance(group, str) else group
        if not any(choice in text for choice in choices):
            missing.append("/".join(choices))
    if missing:
        errors.append(f"{label} is missing: {missing}")

def frontmatter_description(markdown):
    match = re.search(r"^description:\s*(.+)$", markdown, re.MULTILINE)
    return match.group(1).casefold() if match else ""

def validate(rule, skill, agents, docs):
    errors = []
    lowered_rule = rule.casefold()
    lowered_skill = skill.casefold()
    direct = section(rule, "Direct-Work Boundary")
    lifecycle = section(rule, "Default Lifecycle")
    routing = section(rule, "Cursor Subagents")
    scheduling = section(skill, "Scheduling Rules")
    lane_prompt = section(skill, "Lane Prompt Requirements")
    execution_models = section(skill, "Cursor Execution Models")
    failure = section(skill, "Failure Handling")
    integration = section(skill, "Integration")

    require_terms(errors, "direct-work boundary", direct, (
        ("up to one bounded read", "at most one bounded read"),
        ("one bounded write or patch", "one bounded write/patch"),
        ("one cheap focused check", "one cheap, focused check"),
        ("coordination", "setup"),
        ("trivial conversation", "trivial conversational"),
    ))
    for pattern, label in (
        (r"(?:two|2)(?:\s+or more|\+)\s+reads", "2+ reads"),
        (r"(?:two|2)(?:\s+or more|\+)\s+(?:writes|patches)", "2+ patches"),
        (r"tests?.{0,30}(?:debug|loop)|(?:debug|test).{0,30}loops?", "test or debug loops"),
        (r"material uncertainty", "material uncertainty"),
        (r"multi-file", "multi-file work"),
        (r"behavio(?:u)?r.{0,20}public[- ]contract", "behavior or public-contract changes"),
        (r"implementation-level.{0,30}non-trivial verification", "implementation-level non-trivial verification"),
    ):
        if not re.search(pattern, direct, re.DOTALL):
            errors.append(f"direct-work boundary is missing {label}")
    if not re.search(r"classification thresholds?.{0,100}(?:do not|don't).{0,80}(?:prevent|stop).{0,80}parent", direct, re.DOTALL):
        errors.append("direct-work boundary does not separate classification from parent integration duties")
    require_terms(errors, "direct-work parent integration duty", direct, (
        ("status and diff", "status/diff"), "combined integration verification",
    ))

    route_contracts = {
        "scout": (("read-only",), ("code",), ("docs", "documentation"), ("research", "context retrieval")),
        "forager": (("ordinary", "bounded"), ("implementation",), ("bug fix",), ("refactor",), ("tests", "testing"), ("documentation", "docs")),
        "approach-advisor": (("read-only",), ("direction", "approach"), ("uncertain", "costly to reverse", "costly-to-reverse")),
        "plan-reviewer": (("read-only",), ("plan",), ("readiness", "ready"), ("requested", "artifact")),
        "code-reviewer": (("read-only",), ("completed",), ("correctness",), ("risk", "regression")),
        "simplicity-reviewer": (("read-only",), ("final", "completed"), ("yagni", "unnecessary complexity"), ("dead code",), ("proportional",)),
    }
    for name, groups in route_contracts.items():
        require_terms(errors, f"{name} route", route(routing, name), groups)

    isolation_text = f"{routing}\n{scheduling}\n{execution_models}"
    if not re.search(r"separate (?:assistant )?(?:session|context).{0,100}(?:does not|doesn't|is not).{0,50}(?:isolate|isolation)", isolation_text, re.DOTALL):
        errors.append("delegation policy does not state that separate context/session is not file isolation")
    require_terms(errors, "true write isolation", isolation_text, (
        "true write isolation", "worktree", ("isolated project copy", "separate project copy"),
        ("cloud environment", "separate working directory"),
    ))
    if not re.search(r"shared checkout.{0,160}(?:disjoint|non-overlapping).{0,100}(?:serial|one writing lane)", isolation_text, re.DOTALL):
        errors.append("shared-checkout writers are not constrained to disjoint ownership or serial execution")
    if re.search(r"(?:git )?branch (?:isolates? files|provides? (?:file isolation|true write isolation))", isolation_text, re.DOTALL):
        errors.append("a Git branch is incorrectly described as file isolation")

    require_terms(errors, "default-rule handoff", routing, (
        "self-contained", ("objective", "primary goal"), ("constraints", "scope"),
        "file ownership", ("done criteria", "acceptance criteria"), "verification",
    ))
    require_terms(errors, "skill handoff procedure", lane_prompt, (
        "objective", "expected output", "in scope", "out of scope", "evidence",
        "prior failures", "dependencies", "file ownership", "verification", "blockers", "final summary",
    ))
    if not re.search(r"fresh (?:named )?(?:subagent|child|session).{0,120}(?:failed|failure)", f"{routing}\n{failure}", re.DOTALL):
        errors.append("failed child recovery does not require a fresh child")
    require_terms(errors, "default-rule integration gates", routing, (
        ("actual diff", "inspect every returned result and the actual diff"), "combined verification",
        "code-reviewer", "simplicity-reviewer",
    ))

    lifecycle_terms = ("integration workspace", "combined verification", "diff", "code-review", "simplicity-review", "commit", "cleanup")
    positions = [integration.find(term) for term in lifecycle_terms]
    if any(position < 0 for position in positions) or positions != sorted(positions):
        errors.append("delegation skill does not order integration workspace, combined verification, diff/reviews, commit, and cleanup")
    if not re.search(r"(?:materialize|integrate).{0,100}isolated results?.{0,100}integration workspace", integration, re.DOTALL):
        errors.append("isolated results are not materialized into an integration workspace")
    require_terms(errors, "default lifecycle", lifecycle, (
        ("classify", "direct vs delegated"), "delegate", ("integration workspace", "integrate isolated results"),
        "combined verification", ("status and diff", "status/diff"), "commit", "cleanup",
    ))

    description = frontmatter_description(agents["forager"])
    require_terms(errors, "forager description", description, (
        ("ordinary", "bounded"), "implementation", "bug fix", "refactor", "tests", ("documentation", "docs"),
    ))
    if "isolated" in description or "isolation" in description:
        errors.append("forager role identity incorrectly depends on isolation")
    require_terms(errors, "forager execution guidance", agents["forager"].casefold(), (
        ("isolated copy when needed", "isolated working copy when needed", "worktree when needed"),
        "do not delegate implementation", "no recursive delegation",
    ))

    direct_first = re.compile(r"(?:handle|work|implement).{0,50}(?:directly|itself).{0,40}(?:first|by default)|subagents?.{0,30}(?:optional|only when useful)", re.DOTALL)
    if direct_first.search(lowered_rule):
        errors.append("default Agent Rules contain direct-first policy wording")
    if "delegation-first" not in lowered_rule or "parent coordinates" not in lowered_rule:
        errors.append("default Agent Rules no longer establish delegation-first parent coordination")
    combined = f"{lowered_rule}\n{lowered_skill}"
    if re.search(r"\b(?:hive_[a-z0-9_]+|task)\s*\(", combined) or re.search(r"\bsubagent_type\s*:", combined):
        errors.append("Cursor delegation assets contain Hive/OpenCode tool-call syntax")

    for name, text in docs.items():
        relevant = section(text, "Cursor prompt-level assets") if name == "README.md" else text.casefold()
        if name == "FOR-LLM-AGENTS.md":
            relevant = section(text, "What This Repo Actually Supports")
        require_terms(errors, f"{name} Cursor contract", relevant, (
            ("strong prompt policy", "strong prompting policy"),
            ("heuristic",), ("not runtime-guaranteed", "not runtime guaranteed", "cannot guarantee routing"),
            ("bounded direct exception", "bounded direct-work exception", "bounded direct work exception"),
            ("separate context", "separate assistant session"), "shared checkout", ("does not isolate", "not file isolation"),
            "worktree", ("project copy", "project copies", "isolated project copy"), ("overlapping writers", "overlap"),
        ))
    return errors

rule = load(".apm/cursor/rules/default-agent.md")
skill = load(".apm/cursor/skills/subagent-delegation/SKILL.md")
agents = {name: load(f".apm/cursor/agents/{name}.md") for name in (
    "scout", "forager", "approach-advisor", "plan-reviewer", "code-reviewer", "simplicity-reviewer",
)}
docs = {name: load(name) for name in ("README.md", "CURSOR.md", "FOR-LLM-AGENTS.md", ".apm/cursor/README.md")}

errors = validate(rule, skill, agents, docs)
if errors:
    raise SystemExit("\n".join(errors))

negative_cases = {
    "direct-first synonym": rule.replace(
        "a retrieval-led, delegation-first ad-hoc orchestrator",
        "an orchestrator that handles work directly first and uses subagents only when useful",
    ),
    "removed scout mapping": rule.replace("- `scout`:", "- `removed-scout`:", 1),
    "removed forager mapping": rule.replace("- `forager`:", "- `removed-forager`:", 1),
    "branch as isolation": rule.replace(
        "Separate context is not filesystem isolation.",
        "A Git branch isolates files for each child.",
        1,
    ),
    "missing parent integration duty": re.sub(
        r"^.*classification thresholds.*combined integration verification.*\n?",
        "",
        rule,
        count=1,
        flags=re.MULTILINE | re.IGNORECASE,
    ),
}
for label, mutated_rule in negative_cases.items():
    if mutated_rule == rule:
        raise SystemExit(f"negative fixture did not mutate the rule: {label}")
    if not validate(mutated_rule, skill, agents, docs):
        raise SystemExit(f"semantic validator accepted negative case: {label}")

print("ok")
PY
then
  pass "Cursor delegation policy and documentation semantic contracts"
else
  fail "Cursor delegation policy and documentation semantic contracts"
fi

# ---------------------------------------------------------------------------
# Preflight contract: validation rejects a stale Cursor reflect duplicate
# ---------------------------------------------------------------------------
printf '\n=== Preflight: stale Cursor reflect duplicate rejection ===\n'
printf '%s\n' '# stale duplicate' > "${REPO_FIXTURE}/.apm/cursor/commands/reflect.md"
if ! bash "${CURSOR_HELPER}" validate >"${TMPDIR}/stale-reflect.out" 2>"${TMPDIR}/stale-reflect.err"; then
  grep -q 'stale duplicate.*commands/reflect.md' "${TMPDIR}/stale-reflect.err" && pass "stale Cursor reflect duplicate rejected" || fail "stale Cursor reflect duplicate produced wrong error"
else
  fail "stale Cursor reflect duplicate was accepted"
fi
rm -f "${REPO_FIXTURE}/.apm/cursor/commands/reflect.md"

# ---------------------------------------------------------------------------
# 0. context-improved installs the optional Cymbal hook
# ---------------------------------------------------------------------------
printf '\n=== 0. context-improved Cymbal hook ===\n'
optional_bin="${TMPDIR}/optional-bin"
optional_target="${TMPDIR}/optional-target"
optional_target_failing_cymbal="${TMPDIR}/optional-target-failing-cymbal"
mkdir -p "${optional_bin}" "${optional_target}" "${optional_target_failing_cymbal}"
ln -s "$(command -v jq)" "${optional_bin}/jq"
printf '#!/bin/sh\nexit 0\n' > "${optional_bin}/uvx"
cat > "${optional_bin}/cymbal" <<'SH'
#!/bin/sh
printf '%s\n' "${OPENCODE_CONFIG_DIR}" > "${CYMBAL_HOOK_LOG}"
printf '%s\n' "$*" >> "${CYMBAL_HOOK_LOG}"
SH
chmod +x "${optional_bin}/uvx" "${optional_bin}/cymbal"
cat > "${optional_target}/opencode.json" <<'JSON'
{
  "mcp": {
    "context-mode": {
      "type": "local",
      "command": ["context-mode", "--mcp"]
    },
    "unrelated": {
      "type": "local",
      "command": ["unrelated-server"]
    }
  }
}
JSON
printf '{}\n' > "${optional_target}/agent_hive.json"
if PATH="${optional_bin}:/usr/bin:/bin" CYMBAL_HOOK_LOG="${TMPDIR}/cymbal-hook.log" CONTEXT7_API_KEY=test OPENCODE_CONFIG_DIR="${optional_target}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null; then
  if [[ "$(sed -n '1p' "${TMPDIR}/cymbal-hook.log" 2>/dev/null)" == "${optional_target}" && "$(sed -n '2p' "${TMPDIR}/cymbal-hook.log" 2>/dev/null)" == "hook install opencode --scope user" ]]; then
    pass "0a: context-improved installs Cymbal hook for selected config dir"
  else
    fail "0a: context-improved installs Cymbal hook for selected config dir"
  fi
else
  fail "0a: context-improved install with Cymbal should succeed"
fi
if jq -e '(.plugin | index("context-mode@latest") != null) and (.mcp["context-mode"] == null) and (.mcp.unrelated.command == ["unrelated-server"]) and (.mcp.ast_grep.command == ["uvx", "--from", "git+https://github.com/ast-grep/ast-grep-mcp", "--with", "fastmcp", "ast-grep-server"]) and (.mcp.context7.enabled == true)' "${optional_target}/opencode.json" >/dev/null; then
  pass "0b: context-improved removes stale MCP and preserves unrelated MCPs"
else
  fail "0b: context-improved removes stale MCP and preserves unrelated MCPs"
fi
cat > "${optional_bin}/cymbal" <<'SH'
#!/bin/sh
exit 23
SH
printf '{}\n' > "${optional_target_failing_cymbal}/opencode.json"
printf '{}\n' > "${optional_target_failing_cymbal}/agent_hive.json"
if PATH="${optional_bin}:/usr/bin:/bin" CONTEXT7_API_KEY=test OPENCODE_CONFIG_DIR="${optional_target_failing_cymbal}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>"${TMPDIR}/optional-failing-cymbal.err" && grep -q 'Warning: failed to install optional Cymbal OpenCode hook.' "${TMPDIR}/optional-failing-cymbal.err" && jq -e '(.plugin | index("context-mode@latest") != null) and (.mcp["context-mode"] == null)' "${optional_target_failing_cymbal}/opencode.json" >/dev/null; then
  pass "0c: failed Cymbal hook warns without failing or rolling back bundle"
else
  fail "0c: failed Cymbal hook should warn without failing or rolling back bundle"
fi

# ---------------------------------------------------------------------------
# 0d. Missing agent_hive target exits non-zero without mutating opencode.json
# ---------------------------------------------------------------------------
printf '\n=== 0d. Missing agent_hive target no-mutation ===\n'
td_missing_ah="${TMPDIR}/test-missing-ah"; mkdir -p "${td_missing_ah}"
printf '{"mcp":{}}\n' > "${td_missing_ah}/opencode.json"
cp "${td_missing_ah}/opencode.json" "${td_missing_ah}/opencode.json.before"
if ! PATH="${optional_bin}:/usr/bin:/bin" CONTEXT7_API_KEY=test OPENCODE_CONFIG_DIR="${td_missing_ah}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>&1; then
  if cmp -s "${td_missing_ah}/opencode.json" "${td_missing_ah}/opencode.json.before"; then
    pass "0d: missing agent_hive target exits non-zero, opencode.json unchanged"
  else
    fail "0d: missing agent_hive target mutated opencode.json"
  fi
else
  fail "0d: missing agent_hive target should have exited non-zero"
fi

# ---------------------------------------------------------------------------
# 0e. Malformed agent_hive target exits non-zero without mutating opencode.json
# ---------------------------------------------------------------------------
printf '\n=== 0e. Malformed agent_hive target no-mutation ===\n'
td_malformed_ah="${TMPDIR}/test-malformed-ah"; mkdir -p "${td_malformed_ah}"
printf '{"mcp":{}}\n' > "${td_malformed_ah}/opencode.json"
cp "${td_malformed_ah}/opencode.json" "${td_malformed_ah}/opencode.json.before"
printf 'not json\n' > "${td_malformed_ah}/agent_hive.json"
if ! PATH="${optional_bin}:/usr/bin:/bin" CONTEXT7_API_KEY=test OPENCODE_CONFIG_DIR="${td_malformed_ah}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>&1; then
  if cmp -s "${td_malformed_ah}/opencode.json" "${td_malformed_ah}/opencode.json.before"; then
    pass "0e: malformed agent_hive target exits non-zero, opencode.json unchanged"
  else
    fail "0e: malformed agent_hive target mutated opencode.json"
  fi
else
  fail "0e: malformed agent_hive target should have exited non-zero"
fi

# ---------------------------------------------------------------------------
# 1. Invalid env values table-driven (0, false, 2) must fail dry-run
# ---------------------------------------------------------------------------
printf '\n=== 1. Invalid env values (0, false, 2) table-driven ===\n'
for inval in 0 false 2; do
  td="${TMPDIR}/td_env_${inval}"; mkdir -p "${td}"
  ! CURSOR_CONFIG_DIR="${td}" CURSOR_INSTALL_IVAN_WRITING="${inval}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td}/err" || fail "1a: ${inval} should have exited non-zero"
  grep -q 'not supported' "${td}/err" && pass "1b: ${inval} rejected" || fail "1c: wrong error for ${inval}: $(cat ${td}/err)"
  cursor_target_unmodified "${td}" && pass "1d: ${inval} created no managed paths" || fail "1e: ${inval} target mutated"
done

# ---------------------------------------------------------------------------
# 2. Invalid env fails before any target mutation (real install)
# ---------------------------------------------------------------------------
printf '\n=== 2. Invalid env fails before any mutation (real install) ===\n'
td2="${TMPDIR}/test2"; mkdir -p "${td2}"
! CURSOR_CONFIG_DIR="${td2}" CURSOR_INSTALL_IVAN_WRITING=0 bash "${CURSOR_HELPER}" install 2>"${td2}/err" || fail "2a: should have exited non-zero"
cursor_target_unmodified "${td2}" && pass "2b: no managed paths created after invalid env" || fail "2c: unexpected mutation"

# ---------------------------------------------------------------------------
# 3. Opt-in install creates marker inside skill directory
# ---------------------------------------------------------------------------
printf '\n=== 3. Opt-in install (marker inside) ===\n'
td3="${TMPDIR}/test3"; mkdir -p "${td3}"
CURSOR_CONFIG_DIR="${td3}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td3}/install.log" && pass "3a: opt-in install succeeded" || fail "3b: opt-in install failed"
[[ -f "${td3}/skills/ivan-writing/SKILL.md" ]] && pass "3c: ivan-writing SKILL.md" || fail "3d: ivan-writing SKILL.md not found"
[[ -f "${td3}/skills/ivan-writing/references/registers.md" ]] && pass "3e: registers.md" || fail "3f: registers.md not found"
[[ -f "${td3}/skills/ivan-writing/references/examples.md" ]] && pass "3g: examples.md" || fail "3h: examples.md not found"
[[ -f "${td3}/skills/stop-slop/SKILL.md" ]] && pass "3i: stop-slop installed" || fail "3j: canonical skill not installed"
[[ -f "${td3}/skills/humanizer/SKILL.md" ]] && pass "3k: humanizer installed" || fail "3l: canonical skill not installed"
[[ -f "${td3}/skills/writing-for-humans/SKILL.md" ]] && pass "3ac: writing-for-humans installed" || fail "3ad: writing-for-humans canonical skill not installed"
[[ -f "${td3}/skills/writing-for-humans/references/sources.md" ]] && pass "3ae: writing-for-humans sources" || fail "3af: writing-for-humans extra file not copied"
[[ -f "${td3}/skills/frontend-slides/SKILL.md" ]] && pass "3o: frontend-slides installed" || fail "3p: frontend-slides canonical skill not installed"
[[ -f "${td3}/skills/frontend-slides/viewport-base.css" ]] && pass "3q: frontend-slides viewport-base.css" || fail "3r: frontend-slides extra file not copied"
[[ -f "${td3}/skills/drawio-skill/SKILL.md" ]] && pass "3s: drawio-skill installed" || fail "3t: drawio-skill canonical skill not installed"
[[ -f "${td3}/skills/drawio-skill/bin/run" ]] && pass "3u: drawio-skill bin/run" || fail "3v: drawio-skill extra file not copied"
[[ -f "${td3}/skills/drawio-skill/data/shape-index.json.gz" ]] && pass "3w: drawio-skill gzip index" || fail "3x: drawio-skill gzip index not copied"
[[ -f "${td3}/skills/stop-design-slop/SKILL.md" ]] && pass "3y: stop-design-slop installed" || fail "3z: stop-design-slop canonical skill not installed"
[[ -f "${td3}/skills/stop-design-slop/references/review-rubric.md" ]] && pass "3aa: stop-design-slop rubric" || fail "3ab: stop-design-slop extra file not copied"
[[ -f "${td3}/skills/ivan-writing/.cursor-managed" ]] && pass "3m: marker inside ivan-writing" || fail "3n: marker not inside ivan-writing"
cmp -s "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" "${td3}/commands/reflect.md" && pass "3ag: canonical reflect content installed byte-for-byte" || fail "3ah: canonical reflect content changed during Cursor install"
cmp -s "${REPO_FIXTURE}/.apm/cursor/skills/agents-md-mastery/SKILL.md" "${td3}/skills/agents-md-mastery/SKILL.md" && pass "3ai: Cursor agents-md-mastery installed byte-for-byte" || fail "3aj: Cursor agents-md-mastery content changed during install"

# ---------------------------------------------------------------------------
# 4. Opt-out removes only helper-managed ivan-writing (in-directory marker)
# ---------------------------------------------------------------------------
printf '\n=== 4. Opt-out removes managed ivan-writing (in-directory marker) ===\n'
td4="${TMPDIR}/test4"; mkdir -p "${td4}"
build_fixture
CURSOR_CONFIG_DIR="${td4}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td4}/install.log" || fail "4a: install failed"
[[ -f "${td4}/skills/ivan-writing/SKILL.md" ]] || fail "4b: pre-check failed"
[[ -f "${td4}/skills/ivan-writing/.cursor-managed" ]] || fail "4c: installer did not create marker"
CURSOR_CONFIG_DIR="${td4}" bash "${CURSOR_HELPER}" install 2>"${td4}/optout.log" || fail "4d: opt-out install failed"
[[ ! -d "${td4}/skills/ivan-writing" ]] && pass "4e: opt-out removed ivan-writing" || fail "4f: opt-out did not remove ivan-writing"
ls "${td4}/.backup/"*"/skills/ivan-writing" >/dev/null 2>&1 && pass "4g: backup exists" || fail "4h: no backup"

# ---------------------------------------------------------------------------
# 5. Unowned existing ivan-writing preserved on opt-out (no marker)
# ---------------------------------------------------------------------------
printf '\n=== 5. Unowned existing ivan-writing preserved ===\n'
td5="${TMPDIR}/test5"; mkdir -p "${td5}/skills/ivan-writing"
echo "user content" > "${td5}/skills/ivan-writing/user-file.txt"
build_fixture
CURSOR_CONFIG_DIR="${td5}" bash "${CURSOR_HELPER}" install 2>"${td5}/optout.log" || fail "5a: install with unowned ivan-writing failed"
[[ -f "${td5}/skills/ivan-writing/user-file.txt" ]] && pass "5b: unowned preserved" || fail "5c: unowned removed"

# ---------------------------------------------------------------------------
# 6. Missing canonical source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 6. Missing canonical source fails before mutation ===\n'
td6="${TMPDIR}/test6"; mkdir -p "${td6}"
rm -rf "${REPO_FIXTURE}/.apm/skills/humanizer"
! CURSOR_CONFIG_DIR="${td6}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td6}/err" || fail "6a: should have failed"
grep -q 'validation failed.*\.apm/skills/humanizer' "${td6}/err" && pass "6b: missing canonical detected" || fail "6c: wrong error: $(cat ${td6}/err)"
cursor_target_unmodified "${td6}" && pass "6d: no managed paths created" || fail "6e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 7. Wrong-name canonical source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 7. Wrong-name canonical source fails before mutation ===\n'
td7="${TMPDIR}/test7"; mkdir -p "${td7}"
SKILL_FILE="${REPO_FIXTURE}/.apm/skills/humanizer/SKILL.md"
replace_fixture_text "${SKILL_FILE}" 'name: humanizer' 'name: humanizer-wrong'
! CURSOR_CONFIG_DIR="${td7}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td7}/err" || fail "7a: should have failed"
grep -q -i 'frontmatter name' "${td7}/err" && pass "7b: wrong name detected" || fail "7c: wrong error: $(cat ${td7}/err)"
cursor_target_unmodified "${td7}" && pass "7d: no managed paths created" || fail "7e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 8. Missing personal source fails before mutation (opt-in)
# ---------------------------------------------------------------------------
printf '\n=== 8. Missing personal source fails (opt-in) ===\n'
td8="${TMPDIR}/test8"; mkdir -p "${td8}"
rm -rf "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing"
! CURSOR_CONFIG_DIR="${td8}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run 2>"${td8}/err" || fail "8a: should have failed"
grep -q 'validation failed.*profiles/personal/skills/ivan-writing' "${td8}/err" && pass "8b: missing personal detected" || fail "8c: wrong error: $(cat ${td8}/err)"
cursor_target_unmodified "${td8}" && pass "8d: no managed paths created" || fail "8e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 9. Wrong-name personal source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 9. Wrong-name personal source fails ===\n'
td9="${TMPDIR}/test9"; mkdir -p "${td9}"
PSKILL="${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/SKILL.md"
replace_fixture_text "${PSKILL}" 'name: ivan-writing' 'name: ivan-writing-wrong'
! CURSOR_CONFIG_DIR="${td9}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run 2>"${td9}/err" || fail "9a: should have failed"
grep -q -i 'frontmatter name' "${td9}/err" && pass "9b: wrong personal name detected" || fail "9c: wrong error: $(cat ${td9}/err)"
cursor_target_unmodified "${td9}" && pass "9d: no managed paths created" || fail "9e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 10. Missing reference file in personal source
# ---------------------------------------------------------------------------
printf '\n=== 10. Missing reference file in personal source ===\n'
td10="${TMPDIR}/test10"; mkdir -p "${td10}"
rm -f "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/registers.md"
! CURSOR_CONFIG_DIR="${td10}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run 2>"${td10}/err" || fail "10a: should have failed"
grep -q 'registers' "${td10}/err" && pass "10b: missing registers.md detected" || fail "10c: wrong error: $(cat ${td10}/err)"
cursor_target_unmodified "${td10}" && pass "10d: no managed paths created" || fail "10e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 11. OpenCode personal source preflight before mutation
# ---------------------------------------------------------------------------
printf '\n=== 11. OpenCode personal source preflight ===\n'
td11="${TMPDIR}/test11"; mkdir -p "${td11}"
rm -rf "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing"
! OPENCODE_CONFIG_DIR="${td11}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" 2>"${td11}/err" || fail "11a: should have failed"
grep -q 'ERROR' "${td11}/err" && pass "11b: personal preflight detected" || fail "11c: wrong error: $(cat ${td11}/err)"
opencode_target_unmodified "${td11}" && pass "11d: no managed paths created" || fail "11e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 12. Shared install independent of personal source
# ---------------------------------------------------------------------------
printf '\n=== 12. Shared install independent of personal source ===\n'
td12="${TMPDIR}/test12"; mkdir -p "${td12}"
rm -rf "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing"
OPENCODE_CONFIG_DIR="${td12}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td12}/err" && pass "12a: shared install succeeded" || fail "12b: shared install failed"
cmp -s "${REPO_FIXTURE}/profiles/base/opencode.json" "${td12}/opencode.json" && pass "12c: base opencode payload installed" || fail "12d: installed opencode payload did not come from profiles/base"
cmp -s "${REPO_FIXTURE}/profiles/base/agent_hive.json" "${td12}/agent_hive.json" && pass "12e: base Agent Hive payload installed" || fail "12f: installed Agent Hive payload did not come from profiles/base"
[[ -f "${td12}/skills/frontend-slides/SKILL.md" ]] && pass "12g: OpenCode frontend-slides installed" || fail "12h: OpenCode frontend-slides missing"
[[ -f "${td12}/skills/drawio-skill/SKILL.md" ]] && pass "12i: OpenCode drawio-skill installed" || fail "12j: OpenCode drawio-skill missing"
[[ -f "${td12}/skills/stop-design-slop/SKILL.md" ]] && pass "12k: OpenCode stop-design-slop installed" || fail "12l: OpenCode stop-design-slop missing"
[[ -f "${td12}/skills/writing-for-humans/SKILL.md" ]] && pass "12m: OpenCode writing-for-humans installed" || fail "12n: OpenCode writing-for-humans missing"
[[ -f "${td12}/commands/reflect.md" ]] && pass "12o: OpenCode reflect command installed" || fail "12p: OpenCode reflect command missing"
cmp -s "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" "${td12}/commands/reflect.md" && pass "12q: OpenCode reflect content installed byte-for-byte" || fail "12r: OpenCode reflect content changed during install"
[[ ! -e "${td12}/skills/agents-md-mastery" ]] && pass "12s: OpenCode installer excludes Cursor agents-md-mastery" || fail "12t: OpenCode installer leaked Cursor agents-md-mastery"
build_fixture

# ---------------------------------------------------------------------------
# 12b. Missing profiles/base/opencode.json fails before mutation (root decoys remain)
# ---------------------------------------------------------------------------
printf '\n=== 12b. Missing base opencode.json fails before mutation ===\n'
td12b="${TMPDIR}/test12b"; mkdir -p "${td12b}"
printf '{"existing":"opencode"}\n' > "${td12b}/opencode.json"
printf '{"existing":"agent_hive"}\n' > "${td12b}/agent_hive.json"
cp "${td12b}/opencode.json" "${td12b}/opencode.json.before"
cp "${td12b}/agent_hive.json" "${td12b}/agent_hive.json.before"
rm -f "${REPO_FIXTURE}/profiles/base/opencode.json"
[[ -f "${REPO_FIXTURE}/opencode.json" && -f "${REPO_FIXTURE}/agent_hive.json" && -f "${REPO_FIXTURE}/profiles/base/agent_hive.json" ]] || fail "12b-setup: root decoys or remaining base payload missing"
if ! OPENCODE_CONFIG_DIR="${td12b}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td12b}/err"; then
  grep -q 'ERROR' "${td12b}/err" && pass "12b-a: missing base opencode exits non-zero" || fail "12b-b: wrong error: $(cat "${td12b}/err")"
  if cmp -s "${td12b}/opencode.json" "${td12b}/opencode.json.before" && cmp -s "${td12b}/agent_hive.json" "${td12b}/agent_hive.json.before"; then
    pass "12b-c: existing target config unmodified"
  else
    fail "12b-d: existing target config mutated"
  fi
  [[ ! -e "${td12b}/AGENTS.md" && ! -e "${td12b}/agents" && ! -e "${td12b}/commands" && ! -e "${td12b}/skills" && ! -e "${td12b}/.backup" ]] \
    && pass "12b-e: no managed paths created" || fail "12b-f: managed paths created despite missing base opencode"
else
  fail "12b-g: install should have failed when profiles/base/opencode.json is absent"
fi
build_fixture

# ---------------------------------------------------------------------------
# 12c. Missing profiles/base/agent_hive.json fails before mutation (root decoys remain)
# ---------------------------------------------------------------------------
printf '\n=== 12c. Missing base agent_hive.json fails before mutation ===\n'
td12c="${TMPDIR}/test12c"; mkdir -p "${td12c}"
printf '{"existing":"opencode"}\n' > "${td12c}/opencode.json"
printf '{"existing":"agent_hive"}\n' > "${td12c}/agent_hive.json"
cp "${td12c}/opencode.json" "${td12c}/opencode.json.before"
cp "${td12c}/agent_hive.json" "${td12c}/agent_hive.json.before"
rm -f "${REPO_FIXTURE}/profiles/base/agent_hive.json"
[[ -f "${REPO_FIXTURE}/opencode.json" && -f "${REPO_FIXTURE}/agent_hive.json" && -f "${REPO_FIXTURE}/profiles/base/opencode.json" ]] || fail "12c-setup: root decoys or remaining base payload missing"
if ! OPENCODE_CONFIG_DIR="${td12c}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td12c}/err"; then
  grep -q 'ERROR' "${td12c}/err" && pass "12c-a: missing base agent_hive exits non-zero" || fail "12c-b: wrong error: $(cat "${td12c}/err")"
  if cmp -s "${td12c}/opencode.json" "${td12c}/opencode.json.before" && cmp -s "${td12c}/agent_hive.json" "${td12c}/agent_hive.json.before"; then
    pass "12c-c: existing target config unmodified"
  else
    fail "12c-d: existing target config mutated"
  fi
  [[ ! -e "${td12c}/AGENTS.md" && ! -e "${td12c}/agents" && ! -e "${td12c}/commands" && ! -e "${td12c}/skills" && ! -e "${td12c}/.backup" ]] \
    && pass "12c-e: no managed paths created" || fail "12c-f: managed paths created despite missing base agent_hive"
else
  fail "12c-g: install should have failed when profiles/base/agent_hive.json is absent"
fi
build_fixture

# ---------------------------------------------------------------------------
# 13. Dry-run non-mutation
# ---------------------------------------------------------------------------
printf '\n=== 13. Dry-run non-mutation ===\n'
td13="${TMPDIR}/test13"; mkdir -p "${td13}"
echo "keep" > "${td13}/should_stay.txt"
build_fixture
before13="$(snapshot_tree "${td13}")"
CURSOR_CONFIG_DIR="${td13}" bash "${CURSOR_HELPER}" install --dry-run >"${TMPDIR}/test13-dryrun.log" 2>&1 && pass "13a: dry-run succeeded" || fail "13b: dry-run failed"
after13="$(snapshot_tree "${td13}")"
[[ "${before13}" == "${after13}" ]] && pass "13c: dry-run target tree unchanged" || fail "13d: dry-run mutated target tree"
grep -q 'canonical .apm/skills/frontend-slides' "${TMPDIR}/test13-dryrun.log" && pass "13e: dry-run plans frontend-slides" || fail "13f: dry-run omitted frontend-slides"
grep -q 'canonical .apm/skills/drawio-skill' "${TMPDIR}/test13-dryrun.log" && pass "13g: dry-run plans drawio-skill" || fail "13h: dry-run omitted drawio-skill"
grep -q 'canonical .apm/skills/stop-design-slop' "${TMPDIR}/test13-dryrun.log" && pass "13i: dry-run plans stop-design-slop" || fail "13j: dry-run omitted stop-design-slop"
grep -q 'canonical .apm/skills/writing-for-humans' "${TMPDIR}/test13-dryrun.log" && pass "13k: dry-run plans writing-for-humans" || fail "13l: dry-run omitted writing-for-humans"
grep -q '\.apm/prompts/reflect\.prompt\.md.*commands/reflect\.md' "${TMPDIR}/test13-dryrun.log" && pass "13m: dry-run sources reflect from canonical prompt" || fail "13n: dry-run omitted canonical reflect source"
grep -q 'skills/agents-md-mastery.*skills/agents-md-mastery' "${TMPDIR}/test13-dryrun.log" && pass "13o: dry-run plans Cursor agents-md-mastery" || fail "13p: dry-run omitted Cursor agents-md-mastery"

# ---------------------------------------------------------------------------
# 14. CURSOR_CONFIG_DIRS=';;' must fail
# ---------------------------------------------------------------------------
printf '\n=== 14. CURSOR_CONFIG_DIRS=";;" rejection ===\n'
td14="${TMPDIR}/test14"; mkdir -p "${td14}/home"
build_fixture
before14="$(snapshot_tree "${td14}")"
! HOME="${td14}/home" CURSOR_CONFIG_DIRS=';;' bash "${CURSOR_HELPER}" install --dry-run 2>"${TMPDIR}/test14-err" || fail "14a: should have exited non-zero"
after14="$(snapshot_tree "${td14}")"
[[ "${before14}" == "${after14}" ]] && pass "14b: all-empty target list created nothing" || fail "14c: all-empty target list mutated isolated HOME"

# ---------------------------------------------------------------------------
# 15. Semicolon multi-root copies named skills to both targets
# ---------------------------------------------------------------------------
printf '\n=== 15. Semicolon multi-root install ===\n'
td15a="${TMPDIR}/test15a"; td15b="${TMPDIR}/test15b"
mkdir -p "${td15a}" "${td15b}"
build_fixture
CURSOR_CONFIG_DIRS="${td15a};${td15b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/multi.log" && pass "15a: multi-root succeeded" || fail "15b: multi-root failed"
[[ -f "${td15a}/skills/stop-slop/SKILL.md" ]] && pass "15c: first target canonical" || fail "15d: first target missing canonical"
[[ -f "${td15b}/skills/stop-slop/SKILL.md" ]] && pass "15e: second target canonical" || fail "15f: second target missing canonical"
[[ -f "${td15a}/skills/frontend-slides/SKILL.md" && -f "${td15b}/skills/frontend-slides/SKILL.md" ]] && pass "15k: both targets frontend-slides" || fail "15l: multi-root missing frontend-slides"
[[ -f "${td15a}/skills/drawio-skill/SKILL.md" && -f "${td15b}/skills/drawio-skill/SKILL.md" ]] && pass "15m: both targets drawio-skill" || fail "15n: multi-root missing drawio-skill"
[[ -f "${td15a}/skills/stop-design-slop/SKILL.md" && -f "${td15b}/skills/stop-design-slop/SKILL.md" ]] && pass "15o: both targets stop-design-slop" || fail "15p: multi-root missing stop-design-slop"
[[ -f "${td15a}/skills/writing-for-humans/SKILL.md" && -f "${td15b}/skills/writing-for-humans/SKILL.md" ]] && pass "15q: both targets writing-for-humans" || fail "15r: multi-root missing writing-for-humans"
[[ -f "${td15a}/agents/forager.md" ]] && pass "15g: first target agent" || fail "15h: first target missing agent"
[[ -f "${td15b}/agents/forager.md" ]] && pass "15i: second target agent" || fail "15j: second target missing agent"
[[ -f "${td15a}/commands/reflect.md" && -f "${td15b}/commands/reflect.md" ]] && pass "15s: both targets reflect command" || fail "15t: multi-root missing reflect command"
if cmp -s "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" "${td15a}/commands/reflect.md" && cmp -s "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" "${td15b}/commands/reflect.md"; then
  pass "15u: both targets preserve canonical reflect content byte-for-byte"
else
  fail "15v: multi-root canonical reflect content changed during install"
fi
if cmp -s "${REPO_FIXTURE}/.apm/cursor/skills/agents-md-mastery/SKILL.md" "${td15a}/skills/agents-md-mastery/SKILL.md" && cmp -s "${REPO_FIXTURE}/.apm/cursor/skills/agents-md-mastery/SKILL.md" "${td15b}/skills/agents-md-mastery/SKILL.md"; then
  pass "15w: both targets preserve Cursor agents-md-mastery byte-for-byte"
else
  fail "15x: multi-root Cursor agents-md-mastery content changed during install"
fi

# ---------------------------------------------------------------------------
# 16. Opt-in multi-root copies ivan-writing to both
# ---------------------------------------------------------------------------
printf '\n=== 16. Opt-in multi-root install ===\n'
td16a="${TMPDIR}/test16a"; td16b="${TMPDIR}/test16b"
mkdir -p "${td16a}" "${td16b}"
build_fixture
CURSOR_CONFIG_DIRS="${td16a};${td16b}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/multi-optin.log" && pass "16a: opt-in multi-root succeeded" || fail "16b: opt-in multi-root failed"
[[ -f "${td16a}/skills/ivan-writing/SKILL.md" ]] && pass "16c: first target ivan-writing" || fail "16d: first target missing"
[[ -f "${td16b}/skills/ivan-writing/SKILL.md" ]] && pass "16e: second target ivan-writing" || fail "16f: second target missing"
[[ -f "${td16a}/skills/ivan-writing/.cursor-managed" ]] && pass "16g: first target marker" || fail "16h: first target marker missing"
[[ -f "${td16b}/skills/ivan-writing/.cursor-managed" ]] && pass "16i: second target marker" || fail "16j: second target marker missing"

# ---------------------------------------------------------------------------
# 17. Stale-marker: deleted managed dir then recreate, opt-out preserves
# ---------------------------------------------------------------------------
printf '\n=== 17. Deleted managed dir recreated by user, opt-out preserves ===\n'
td17="${TMPDIR}/test17"; mkdir -p "${td17}"
build_fixture
CURSOR_CONFIG_DIR="${td17}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td17}/log1" || fail "17a: install failed"
rm -rf "${td17}/skills/ivan-writing"
mkdir -p "${td17}/skills/ivan-writing"
echo "user file" > "${td17}/skills/ivan-writing/user.txt"
CURSOR_CONFIG_DIR="${td17}" bash "${CURSOR_HELPER}" install 2>"${td17}/log2" || fail "17b: opt-out failed"
[[ -f "${td17}/skills/ivan-writing/user.txt" ]] && pass "17c: user-owned recreated dir preserved" || fail "17d: user dir removed despite missing marker"



# ---------------------------------------------------------------------------
# 22. Unsupported extra file in canonical skill directory
# ---------------------------------------------------------------------------
printf '\n=== 22. Unsupported extra file in canonical skill directory ===\n'
td22="${TMPDIR}/test22"; mkdir -p "${td22}"
touch "${REPO_FIXTURE}/.apm/skills/humanizer/extra.txt"
! CURSOR_CONFIG_DIR="${td22}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td22}/err" || fail "22a: should have failed"
grep -q -i 'extra\|unsupported' "${td22}/err" && pass "22b: extra file detected" || fail "22c: wrong error: $(cat ${td22}/err)"
cursor_target_unmodified "${td22}" && pass "22d: no managed paths created" || fail "22e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 23. Unsupported extra subdirectory in canonical skill
# ---------------------------------------------------------------------------
printf '\n=== 23. Unsupported extra subdirectory in canonical skill ===\n'
td23="${TMPDIR}/test23"; mkdir -p "${td23}"
mkdir -p "${REPO_FIXTURE}/.apm/skills/humanizer/scripts"
! CURSOR_CONFIG_DIR="${td23}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td23}/err" || fail "23a: should have failed"
grep -q -i 'scripts\|unsupported' "${td23}/err" && pass "23b: extra subdir detected" || fail "23c: wrong error: $(cat ${td23}/err)"
cursor_target_unmodified "${td23}" && pass "23d: no managed paths created" || fail "23e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 24. Bad second root (file, not directory) fails before first-root mutation
# ---------------------------------------------------------------------------
printf '\n=== 24. Bad second root fails without first-root mutation ===\n'
scope24="${TMPDIR}/scope24"
td24a="${scope24}/first"; td24b="${scope24}/second"
mkdir -p "${td24a}"
printf 'keep\n' > "${td24a}/existing.txt"
touch "${td24b}"
build_fixture
before24="$(snapshot_tree "${scope24}")"
! CURSOR_CONFIG_DIRS="${td24a};${td24b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test24_err" || fail "24a: should have failed"
after24="$(snapshot_tree "${scope24}")"
[[ "${before24}" == "${after24}" ]] && pass "24b: target scope unchanged" || fail "24c: target scope mutated despite bad second root"

# ---------------------------------------------------------------------------
# 25. Unsupported CLI flag fails non-mutation
# ---------------------------------------------------------------------------
printf '\n=== 25. Unsupported CLI flag fails non-mutation ===\n'
td25="${TMPDIR}/test25"; mkdir -p "${td25}"
! CURSOR_CONFIG_DIR="${td25}" bash "${CURSOR_HELPER}" install --bogus 2>"${td25}/err" || fail "25a: should have failed"
[[ ! -f "${td25}/agents" && ! -f "${td25}/skills" ]] && pass "25b: no mutation" || fail "25c: unexpected mutation"
cursor_target_unmodified "${td25}" && pass "25d: no managed paths created" || fail "25e: target mutated"

# ---------------------------------------------------------------------------
# 26. Nested unsupported file under references/ in canonical stop-slop
# ---------------------------------------------------------------------------
printf '\n=== 26. Nested unsupported file under references/ (canonical, Cursor) ===\n'
td26="${TMPDIR}/test26"; mkdir -p "${td26}"
touch "${REPO_FIXTURE}/.apm/skills/stop-slop/references/extra.txt"
! CURSOR_CONFIG_DIR="${td26}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td26}/err" || fail "26a: should have failed"
grep -q 'extra\|unsupported' "${td26}/err" && pass "26b: nested extra file rejected" || fail "26c: wrong error: $(cat ${td26}/err)"
cursor_target_unmodified "${td26}" && pass "26d: no managed paths created" || fail "26e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 27. Nested subdirectory under references/ in canonical humanizer
# ---------------------------------------------------------------------------
printf '\n=== 27. Nested subdirectory under references/ (canonical, Cursor) ===\n'
td27="${TMPDIR}/test27"; mkdir -p "${td27}"
mkdir -p "${REPO_FIXTURE}/.apm/skills/humanizer/references/subdir"
! CURSOR_CONFIG_DIR="${td27}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td27}/err" || fail "27a: should have failed"
grep -q 'subdir\|unsupported' "${td27}/err" && pass "27b: nested subdir rejected" || fail "27c: wrong error: $(cat ${td27}/err)"
cursor_target_unmodified "${td27}" && pass "27d: no managed paths created" || fail "27e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 28. Nested unsupported file under references/ in personal ivan-writing (Cursor)
# ---------------------------------------------------------------------------
printf '\n=== 28. Nested unsupported file under references/ (personal, Cursor) ===\n'
td28="${TMPDIR}/test28"; mkdir -p "${td28}"
touch "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/extra.txt"
! CURSOR_CONFIG_DIR="${td28}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run 2>"${td28}/err" || fail "28a: should have failed"
grep -q 'extra\|unsupported' "${td28}/err" && pass "28b: personal nested extra file rejected" || fail "28c: wrong error: $(cat ${td28}/err)"
cursor_target_unmodified "${td28}" && pass "28d: no managed paths created" || fail "28e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 29. Nested symlink under references/ in personal ivan-writing (Cursor)
# ---------------------------------------------------------------------------
printf '\n=== 29. Nested symlink under references/ (personal, Cursor) ===\n'
td29="${TMPDIR}/test29"; mkdir -p "${td29}"
ln -s /dev/null "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/sneaky-link"
! CURSOR_CONFIG_DIR="${td29}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run 2>"${td29}/err" || fail "29a: should have failed"
grep -q 'sneaky\|unsupported\|link' "${td29}/err" && pass "29b: personal nested symlink rejected" || fail "29c: wrong error: $(cat ${td29}/err)"
cursor_target_unmodified "${td29}" && pass "29d: no managed paths created" || fail "29e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 30. Nested subdirectory under references/ in personal ivan-writing (OpenCode)
# ---------------------------------------------------------------------------
printf '\n=== 30. Nested subdirectory under references/ (personal, OpenCode) ===\n'
td30="${TMPDIR}/test30"; mkdir -p "${td30}"
mkdir -p "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/subdir"
! OPENCODE_CONFIG_DIR="${td30}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" 2>"${td30}/err" || fail "30a: should have failed"
grep -q 'subdir\|unsupported' "${td30}/err" && pass "30b: OpenCode personal nested subdir rejected" || fail "30c: wrong error: $(cat ${td30}/err)"
opencode_target_unmodified "${td30}" && pass "30d: no managed paths created" || fail "30e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 31. Nested unsupported file under references/ in canonical stop-slop (OpenCode path)
# ---------------------------------------------------------------------------
printf '\n=== 31. Nested unsupported file under references/ (canonical, OpenCode install) ===\n'
td31="${TMPDIR}/test31"; mkdir -p "${td31}"
touch "${REPO_FIXTURE}/.apm/skills/stop-slop/references/rando.txt"
! OPENCODE_CONFIG_DIR="${td31}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td31}/err" || fail "31a: should have failed"
grep -q 'rando\|unsupported' "${td31}/err" && pass "31b: canonical nested extra file rejected in OpenCode" || fail "31c: wrong error: $(cat ${td31}/err)"
opencode_target_unmodified "${td31}" && pass "31d: no managed paths created" || fail "31e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 32. CURSOR_INSTALL_IVAN_WRITING=1 validate validates personal source
# ---------------------------------------------------------------------------
printf '\n=== 32. validate with CURSOR_INSTALL_IVAN_WRITING=1 validates personal source ===\n'
td32="${TMPDIR}/test32"; mkdir -p "${td32}"
CURSOR_CONFIG_DIR="${td32}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" validate 2>"${td32}/val.log" && pass "32a: validate passed with opt-in" || fail "32b: validate failed with opt-in"
rm -rf "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing"
! CURSOR_CONFIG_DIR="${td32}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" validate 2>"${td32}/err" || fail "32c: should have failed with missing personal"
grep -q 'validation failed.*profiles/personal/skills/ivan-writing' "${td32}/err" && pass "32d: validate detects missing personal source" || fail "32e: wrong error: $(cat ${td32}/err)"
build_fixture

# ---------------------------------------------------------------------------
# 33. Production scripts contain no known Bash 4-only collection constructs
# ---------------------------------------------------------------------------
printf '\n=== 33. Bash 3-compatible production scripts ===\n'
if grep -nE 'declare[[:space:]]+-A|(^|[[:space:]])(mapfile|readarray)([[:space:]]|$)' "${REPO_FIXTURE}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/install-profile.sh" >"${TMPDIR}/test33-matches"; then
  fail "33a: Bash 4-only construct found: $(tr '\n' ' ' < "${TMPDIR}/test33-matches")"
else
  pass "33b: no declare -A, mapfile, or readarray"
fi

# ---------------------------------------------------------------------------
# 34. Multi-root: writable first + second under non-creatable ancestor
# ---------------------------------------------------------------------------
printf '\n=== 34. Second target non-creatable ancestor, first target untouched ===\n'
scope34="${TMPDIR}/scope34"
td34a="${scope34}/first"
td34b_parent="${scope34}/blocked"
mkdir -p "${td34a}"
printf 'keep\n' > "${td34a}/existing.txt"
mkdir -p "${td34b_parent}"
chmod 000 "${td34b_parent}"
build_fixture
before34="$(snapshot_tree "${scope34}")"
! CURSOR_CONFIG_DIRS="${td34a};${td34b_parent}/nonexistent" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test34_err" || fail "34a: should have failed"
after34="$(snapshot_tree "${scope34}")"
[[ "${before34}" == "${after34}" ]] && pass "34b: target scope unchanged" || fail "34c: target scope mutated"
chmod -R +rwX "${td34b_parent}" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 35. Existing internal path in second target is a regular file
# ---------------------------------------------------------------------------
printf '\n=== 35. Second target agents file rejected before mutation ===\n'
scope35="${TMPDIR}/scope35"
td35a="${scope35}/first"; td35b="${scope35}/second"
mkdir -p "${td35a}" "${td35b}"
printf 'keep\n' > "${td35a}/existing.txt"
printf 'not a directory\n' > "${td35b}/agents"
build_fixture
before35="$(snapshot_tree "${scope35}")"
! CURSOR_CONFIG_DIRS="${td35a};${td35b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test35-err" || fail "35a: should have failed"
after35="$(snapshot_tree "${scope35}")"
[[ "${before35}" == "${after35}" ]] && pass "35b: both target trees unchanged" || fail "35c: a target mutated before feasibility failure"

# ---------------------------------------------------------------------------
# 36. Broken symlink in an external source manifest
# ---------------------------------------------------------------------------
printf '\n=== 36. Broken source symlink rejected ===\n'
td36="${TMPDIR}/test36"; mkdir -p "${td36}"
build_fixture
ln -s missing.md "${REPO_FIXTURE}/.apm/skills/humanizer/references/broken.md"
! CURSOR_CONFIG_DIR="${td36}" bash "${CURSOR_HELPER}" install --dry-run 2>"${TMPDIR}/test36-err" || fail "36a: should have failed"
grep -q 'broken.md\|symlink' "${TMPDIR}/test36-err" && pass "36b: broken symlink rejected" || fail "36c: wrong error: $(cat "${TMPDIR}/test36-err")"
cursor_target_unmodified "${td36}" && pass "36d: no managed paths created" || fail "36e: target mutated"

# ---------------------------------------------------------------------------
# 37. Frontmatter closing delimiter must be exactly ---
# ---------------------------------------------------------------------------
printf '\n=== 37. Non-exact frontmatter closing delimiter rejected ===\n'
td37="${TMPDIR}/test37"; mkdir -p "${td37}"
build_fixture
replace_fixture_text "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/SKILL.md" $'\n---\nOK' $'\n---junk\nOK'
! CURSOR_CONFIG_DIR="${td37}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" validate 2>"${TMPDIR}/test37-err" || fail "37a: should have failed"
grep -q 'frontmatter\|delimiter\|unterminated' "${TMPDIR}/test37-err" && pass "37b: ---junk rejected" || fail "37c: wrong error: $(cat "${TMPDIR}/test37-err")"

# ---------------------------------------------------------------------------
# 38. OpenCode validates canonical source frontmatter
# ---------------------------------------------------------------------------
printf '\n=== 38. OpenCode wrong canonical source rejected ===\n'
td38="${TMPDIR}/test38"; mkdir -p "${td38}"
build_fixture
replace_fixture_text "${REPO_FIXTURE}/.apm/skills/stop-slop/SKILL.md" 'name: stop-slop' 'name: wrong-name'
! OPENCODE_CONFIG_DIR="${td38}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${TMPDIR}/test38-err" || fail "38a: should have failed"
grep -q 'wrong-name\|frontmatter name\|expected stop-slop' "${TMPDIR}/test38-err" && pass "38b: wrong canonical name rejected" || fail "38c: wrong error: $(cat "${TMPDIR}/test38-err")"
opencode_target_unmodified "${td38}" && pass "38d: no managed paths created" || fail "38e: target mutated"

# ---------------------------------------------------------------------------
# 39. OpenCode validates exact canonical source manifests
# ---------------------------------------------------------------------------
printf '\n=== 39. OpenCode extra canonical source entry rejected ===\n'
td39="${TMPDIR}/test39"; mkdir -p "${td39}"
build_fixture
mkdir -p "${REPO_FIXTURE}/.apm/skills/stop-slop/references/nested"
printf 'extra\n' > "${REPO_FIXTURE}/.apm/skills/stop-slop/references/nested/extra.md"
! OPENCODE_CONFIG_DIR="${td39}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${TMPDIR}/test39-err" || fail "39a: should have failed"
grep -q 'nested\|extra.md\|unsupported' "${TMPDIR}/test39-err" && pass "39b: nested extra entry rejected" || fail "39c: wrong error: $(cat "${TMPDIR}/test39-err")"
opencode_target_unmodified "${td39}" && pass "39d: no managed paths created" || fail "39e: target mutated"

# ---------------------------------------------------------------------------
# 40. Standalone opted-in validation applies source content checks
# ---------------------------------------------------------------------------
printf '\n=== 40. Opted-in standalone validate checks personal source content ===\n'
build_fixture
printf '\n/home/example/secret\n' >> "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/references/examples.md"
! CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" validate 2>"${TMPDIR}/test40-err" || fail "40a: should have failed"
grep -q 'references/examples.md.*absolute home-directory path' "${TMPDIR}/test40-err" && pass "40b: personal source content checked" || fail "40c: wrong error: $(cat "${TMPDIR}/test40-err")"

# ---------------------------------------------------------------------------
# 41. Permission preflight: second target unreadable managed file
# ---------------------------------------------------------------------------
printf '\n=== 41. Second target unreadable managed file fails before first-target mutation ===\n'
if [[ "$(id -u)" -eq 0 ]]; then
  pass "41: SKIP - effective UID is root; kernel bypasses permission bits"
else
  scope41="${TMPDIR}/scope41"
  td41a="${scope41}/first"; td41b="${scope41}/second"
  mkdir -p "${td41a}" "${td41b}/skills/humanizer"
  printf 'keep\n' > "${td41a}/keep.txt"
  printf 'unreadable skill\n' > "${td41b}/skills/humanizer/SKILL.md"
  chmod 000 "${td41b}/skills/humanizer/SKILL.md"
  build_fixture
  before41="$(snapshot_tree "${scope41}")"
  ! CURSOR_CONFIG_DIRS="${td41a};${td41b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test41-err" || fail "41a: should have failed"
  after41="$(snapshot_tree "${scope41}")"
  [[ "${before41}" == "${after41}" ]] && pass "41b: first target unchanged" || fail "41c: first target mutated"
  chmod -R +rwX "${td41b}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 42. OpenCode source readability: unreadable canonical reference
# ---------------------------------------------------------------------------
printf '\n=== 42. OpenCode unreadable canonical reference fails before mutation ===\n'
td42="${TMPDIR}/test42"; mkdir -p "${td42}"
chmod 000 "${REPO_FIXTURE}/.apm/skills/stop-slop/references/examples.md"
! OPENCODE_CONFIG_DIR="${td42}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${TMPDIR}/test42-err" || fail "42a: should have failed"
grep -q 'not readable' "${TMPDIR}/test42-err" && pass "42b: unreadable reference detected" || fail "42c: wrong error: $(cat "${TMPDIR}/test42-err")"
opencode_target_unmodified "${td42}" && pass "42d: no managed paths created" || fail "42e: target mutated"
chmod -R +rwX "${REPO_FIXTURE}/.apm/skills/stop-slop" 2>/dev/null || true
build_fixture



# ---------------------------------------------------------------------------
# 51. Multi-root second target unreadable nested reference
# ---------------------------------------------------------------------------
printf '\n=== 51. Second target unreadable nested reference fails before first-target mutation ===\n'
if [[ "$(id -u)" -eq 0 ]]; then
  pass "51: SKIP - effective UID is root; kernel bypasses permission bits"
else
  scope51="${TMPDIR}/scope51"
  td51a="${scope51}/first"; td51b="${scope51}/second"
  mkdir -p "${td51a}" "${td51b}/skills/humanizer/references"
  printf 'keep\n' > "${td51a}/keep.txt"
  printf '# nested patterns\n' > "${td51b}/skills/humanizer/references/patterns.md"
  chmod 000 "${td51b}/skills/humanizer/references/patterns.md"
  build_fixture
  before51="$(snapshot_tree "${scope51}")"
  ! CURSOR_CONFIG_DIRS="${td51a};${td51b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test51-err" || fail "51a: should have failed"
  after51="$(snapshot_tree "${scope51}")"
  [[ "${before51}" == "${after51}" ]] && pass "51b: first target unchanged" || fail "51c: first target mutated"
  chmod -R +rwX "${td51b}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 60. Multi-root second target execute-only references/ dir fails before first-target mutation
# ---------------------------------------------------------------------------
printf '\n=== 60. Second target execute-only references/ dir fails before first-target mutation ===\n'
if [[ "$(id -u)" -eq 0 ]]; then
  pass "60: SKIP - effective UID is root; kernel bypasses permission bits"
else
  scope60="${TMPDIR}/scope60"
  td60a="${scope60}/first"; td60b="${scope60}/second"
  mkdir -p "${td60a}" "${td60b}/skills/humanizer/references"
  printf 'keep\n' > "${td60a}/keep.txt"
  printf '# patterns\n' > "${td60b}/skills/humanizer/references/patterns.md"
  chmod 333 "${td60b}/skills/humanizer/references"
  build_fixture
  before60="$(snapshot_tree "${scope60}")"
  ! CURSOR_CONFIG_DIRS="${td60a};${td60b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test60-err" || fail "60a: should have failed"
  after60="$(snapshot_tree "${scope60}")"
  [[ "${before60}" == "${after60}" ]] && pass "60b: first target unchanged" || fail "60c: first target mutated"
  chmod -R +rwX "${td60b}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 61. Multi-root second target directory-shaped agent.md with unreadable content
# ---------------------------------------------------------------------------
printf '\n=== 61. Second target directory-shaped agents/code-reviewer.md fails before first-target mutation ===\n'
if [[ "$(id -u)" -eq 0 ]]; then
  pass "61: SKIP - effective UID is root; kernel bypasses permission bits"
else
  scope61="${TMPDIR}/scope61"
  td61a="${scope61}/first"; td61b="${scope61}/second"
  mkdir -p "${td61a}" "${td61b}/agents/code-reviewer.md"
  printf '# nested agent content\n' > "${td61b}/agents/code-reviewer.md/instructions.md"
  printf 'keep\n' > "${td61a}/keep.txt"
  chmod 000 "${td61b}/agents/code-reviewer.md/instructions.md"
  build_fixture
  before61="$(snapshot_tree "${scope61}")"
  ! CURSOR_CONFIG_DIRS="${td61a};${td61b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/test61-err" || fail "61a: should have failed"
  after61="$(snapshot_tree "${scope61}")"
  [[ "${before61}" == "${after61}" ]] && pass "61b: first target unchanged" || fail "61c: first target mutated"
  chmod -R +rwX "${td61b}" 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# Table-driven malformed-frontmatter tests
# ---------------------------------------------------------------------------
printf '\n=== Table-driven malformed-frontmatter tests ===\n'

run_td_frontmatter_test() {
  local tn="$1" label="$2" tool="$3" content="$4" expect="$5"
  local td="${TMPDIR}/tdfm_${tn}"; mkdir -p "${td}"
  printf '%b' "${content}" > "${REPO_FIXTURE}/.apm/skills/humanizer/SKILL.md"
  case "${tool}" in
    cursor)
      ! CURSOR_CONFIG_DIR="${td}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td}/err" || { fail "${tn}a: ${label} should have failed"; return; }
      cursor_target_unmodified "${td}" && pass "${tn}d: ${label} no managed paths" || fail "${tn}e: ${label} target mutated"
      ;;
    opencode)
      ! OPENCODE_CONFIG_DIR="${td}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td}/err" || { fail "${tn}a: ${label} should have failed"; return; }
      opencode_target_unmodified "${td}" && pass "${tn}d: ${label} no managed paths" || fail "${tn}e: ${label} target mutated"
      ;;
  esac
  grep -q "${expect}" "${td}/err" && pass "${tn}b: ${label} matched" || fail "${tn}c: ${label} wrong error: $(cat "${td}/err")"
}

# 18: Missing opening delimiter
run_td_frontmatter_test "18" "missing opening ---" cursor \
  "name: humanizer\ndescription: Test missing delimiter.\n---\nOK\n" \
  "frontmatter"

# 19: Missing closing delimiter
run_td_frontmatter_test "19" "missing closing ---" cursor \
  "---\nname: humanizer\ndescription: Test missing closing delimiter.\n" \
  "unterminated\|frontmatter"

# 20: Empty description
run_td_frontmatter_test "20" "empty description" cursor \
  "---\nname: humanizer\ndescription:\n---\nOK\n" \
  "empty"

# 21: Description not starting with "Use when"
run_td_frontmatter_test "21" "description not Use when" cursor \
  "---\nname: humanizer\ndescription: Fixes promotional AI writing.\n---\nOK\n" \
  "Use when"

# 43: Cursor colon-space
run_td_frontmatter_test "43" "Cursor colon-space" cursor \
  "---\nname: humanizer\ndescription: Use when: malformed YAML\n---\nOK\n" \
  "colon-space"

# 44: Cursor duplicate key
run_td_frontmatter_test "44" "Cursor duplicate key" cursor \
  "---\nname: humanizer\ndescription: Use when test.\nname: humanizer\n---\nOK\n" \
  "duplicate"

# 45: Cursor unknown key
run_td_frontmatter_test "45" "Cursor unknown key" cursor \
  "---\nname: humanizer\ndescription: Use when test.\nversion: 1.0\n---\nOK\n" \
  "unknown.*key"

# 46: Cursor malformed quoting
run_td_frontmatter_test "46" "Cursor malformed quoting" cursor \
  "---\nname: humanizer\ndescription: \"Use when malformed quoting\n---\nOK\n" \
  "malformed.*quoting\|quoting"

# 47: OpenCode colon-space
run_td_frontmatter_test "47" "OpenCode colon-space" opencode \
  "---\nname: humanizer\ndescription: Use when: malformed YAML\n---\nOK\n" \
  "colon-space"

# 48: OpenCode duplicate key
run_td_frontmatter_test "48" "OpenCode duplicate key" opencode \
  "---\nname: humanizer\ndescription: Use when test.\nname: humanizer\n---\nOK\n" \
  "duplicate"

# 49: OpenCode unknown key
run_td_frontmatter_test "49" "OpenCode unknown key" opencode \
  "---\nname: humanizer\ndescription: Use when test.\nversion: 1.0\n---\nOK\n" \
  "unknown\|malformed frontmatter"

# 50: OpenCode malformed quoting
run_td_frontmatter_test "50" "OpenCode malformed quoting" opencode \
  "---\nname: humanizer\ndescription: 'Use when malformed quoting\n---\nOK\n" \
  "malformed.*quoting\|quoting"

# 52: Cursor indented continuation
run_td_frontmatter_test "52" "Cursor indented continuation" cursor \
  "---\nname: humanizer\n  continuation line\ndescription: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed"

# 53: OpenCode indented continuation
run_td_frontmatter_test "53" "OpenCode indented continuation" opencode \
  "---\nname: humanizer\n  continuation line\ndescription: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed"

# 54: Cursor quoted scalar
run_td_frontmatter_test "54" "Cursor quoted scalar" cursor \
  "---\nname: \"humanizer\"\ndescription: Use when test.\n---\nOK" \
  "quote\|quoted"

# 55: OpenCode quoted scalar
run_td_frontmatter_test "55" "OpenCode quoted scalar" opencode \
  "---\nname: 'humanizer'\ndescription: Use when test.\n---\nOK" \
  "quote\|quoted"

# 56: Cursor one-space-indented name
run_td_frontmatter_test "56" "Cursor one-space-indented name" cursor \
  "---\n name: humanizer\ndescription: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed\|leading whitespace"

# 57: OpenCode one-space-indented name
run_td_frontmatter_test "57" "OpenCode one-space-indented name" opencode \
  "---\n name: humanizer\ndescription: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed\|leading whitespace"

# 58: Cursor one-space-indented description
run_td_frontmatter_test "58" "Cursor one-space-indented description" cursor \
  "---\nname: humanizer\n description: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed\|leading whitespace"

# 59: OpenCode one-space-indented description
run_td_frontmatter_test "59" "OpenCode one-space-indented description" opencode \
  "---\nname: humanizer\n description: Use when test.\n---\nOK" \
  "continuation\|indented\|malformed\|leading whitespace"

build_fixture

# ---------------------------------------------------------------------------
# 62. Shared install copies dcg-guard plugin without wiping other plugins
# ---------------------------------------------------------------------------
printf '\n=== 62. Shared install copies dcg-guard plugin ===\n'
td62="${TMPDIR}/test62"; mkdir -p "${td62}/plugins"
printf '%s\n' '// keep me' > "${td62}/plugins/unrelated.js"
OPENCODE_CONFIG_DIR="${td62}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td62}/err" && pass "62a: shared install succeeded" || fail "62b: shared install failed: $(cat "${td62}/err")"
cmp -s "${REPO_FIXTURE}/profiles/base/plugins/dcg-guard.js" "${td62}/plugins/dcg-guard.js" && pass "62c: dcg-guard plugin installed" || fail "62d: dcg-guard plugin not copied from profiles/base/plugins"
[[ -f "${td62}/plugins/unrelated.js" ]] && pass "62e: existing unrelated plugin preserved" || fail "62f: existing plugins directory was wiped"
build_fixture

# ---------------------------------------------------------------------------
# 63. Missing dcg-guard plugin source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 63. Missing dcg-guard plugin source fails before mutation ===\n'
td63="${TMPDIR}/test63"; mkdir -p "${td63}"
printf '{"existing":"opencode"}\n' > "${td63}/opencode.json"
printf '{"existing":"agent_hive"}\n' > "${td63}/agent_hive.json"
cp "${td63}/opencode.json" "${td63}/opencode.json.before"
cp "${td63}/agent_hive.json" "${td63}/agent_hive.json.before"
rm -f "${REPO_FIXTURE}/profiles/base/plugins/dcg-guard.js"
if ! OPENCODE_CONFIG_DIR="${td63}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" 2>"${td63}/err"; then
  grep -q 'ERROR' "${td63}/err" && pass "63a: missing dcg-guard plugin exits non-zero" || fail "63b: wrong error: $(cat "${td63}/err")"
  if cmp -s "${td63}/opencode.json" "${td63}/opencode.json.before" && cmp -s "${td63}/agent_hive.json" "${td63}/agent_hive.json.before"; then
    pass "63c: existing target config unmodified"
  else
    fail "63d: existing target config mutated"
  fi
else
  fail "63e: install should have failed when profiles/base/plugins/dcg-guard.js is absent"
fi
build_fixture

# ---------------------------------------------------------------------------
# 64. Base install wires Cymbal hook when cymbal is on PATH
# ---------------------------------------------------------------------------
printf '\n=== 64. Base install Cymbal hook ===\n'
cymbal_bin="${TMPDIR}/cymbal-bin"
td64="${TMPDIR}/test64"
td64_fail="${TMPDIR}/test64-fail"
mkdir -p "${cymbal_bin}" "${td64}" "${td64_fail}"
cat > "${cymbal_bin}/cymbal" <<'SH'
#!/bin/sh
printf '%s\n' "${OPENCODE_CONFIG_DIR}" > "${CYMBAL_HOOK_LOG}"
printf '%s\n' "$*" >> "${CYMBAL_HOOK_LOG}"
SH
chmod +x "${cymbal_bin}/cymbal"
if PATH="${cymbal_bin}:/usr/bin:/bin" CYMBAL_HOOK_LOG="${TMPDIR}/install-cymbal-hook.log" OPENCODE_CONFIG_DIR="${td64}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" >/dev/null; then
  if [[ "$(sed -n '1p' "${TMPDIR}/install-cymbal-hook.log" 2>/dev/null)" == "${td64}" && "$(sed -n '2p' "${TMPDIR}/install-cymbal-hook.log" 2>/dev/null)" == "hook install opencode --scope user" ]]; then
    pass "64a: base install installs Cymbal hook for selected config dir"
  else
    fail "64a: base install installs Cymbal hook for selected config dir"
  fi
else
  fail "64b: base install with Cymbal should succeed"
fi
cat > "${cymbal_bin}/cymbal" <<'SH'
#!/bin/sh
exit 23
SH
if PATH="${cymbal_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td64_fail}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" >/dev/null 2>"${TMPDIR}/install-failing-cymbal.err" && grep -q 'Warning: failed to install optional Cymbal OpenCode hook.' "${TMPDIR}/install-failing-cymbal.err" && [[ -f "${td64_fail}/opencode.json" ]]; then
  pass "64c: failed Cymbal hook warns without failing base install"
else
  fail "64c: failed Cymbal hook should warn without failing base install"
fi
build_fixture

# ---------------------------------------------------------------------------
# 65. Repository payloads are OpenAI gpt-5.6 luna/sol only
# ---------------------------------------------------------------------------
printf '\n=== 65. Repository OpenAI-only payload contracts ===\n'
if python3 - "${BASELINE_PWD}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
hive_path = root / "profiles/base/agent_hive.json"
open_path = root / "profiles/base/opencode.json"
plugin_path = root / "profiles/base/plugins/dcg-guard.js"
errors = []

def walk(value, path="$"):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk(child, f"{path}.{key}")
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, f"{path}[{index}]")
    else:
        yield path, value

try:
    hive = json.loads(hive_path.read_text(encoding="utf-8"))
    opencode = json.loads(open_path.read_text(encoding="utf-8"))
except json.JSONDecodeError as exc:
    print(f"invalid JSON: {exc}")
    raise SystemExit(1)

allowed_models = {"openai/gpt-5.6-luna", "openai/gpt-5.6-sol"}
blocked_substrings = ("opencode-go/", "magic-compact", "opencode-go-multi-auth")
for path, value in walk(hive):
    if not isinstance(value, str):
        continue
    if path.endswith(".model") and (
        value not in allowed_models or "-fast" in value or value.startswith("xai/") or "opencode-go/" in value
    ):
        errors.append(f"{hive_path.name} {path}={value}")

for path, value in walk(opencode):
    if not isinstance(value, str):
        continue
    if any(part in value for part in blocked_substrings):
        errors.append(f"{open_path.name} {path}={value}")
    if path.endswith(".model") and (value not in allowed_models or "-fast" in value):
        errors.append(f"{open_path.name} {path}={value}")

plugin = opencode.get("plugin") or []
if "oc-arkive@latest" not in plugin:
    errors.append("opencode.json missing oc-arkive@latest")
if "opencode-gpt-imagegen" not in plugin:
    errors.append("opencode.json missing opencode-gpt-imagegen")

required_custom = {
    "documentation-reviewer",
    "adversarial-documentation-reviewer",
    "scout-researcher-capable",
    "scout-researcher-code",
    "ui-reviewer",
}
custom = hive.get("customAgents") or {}
missing = sorted(required_custom - set(custom))
if missing:
    errors.append(f"missing customAgents: {missing}")
if "code-reviewer-documentation" in custom:
    errors.append("legacy customAgents.code-reviewer-documentation still present")
if "code-reviewer-ui" in custom:
    errors.append("legacy customAgents.code-reviewer-ui still present")

docs_autoload = {
    "forager-documents": ("writing-for-humans",),
    "documentation-reviewer": ("writing-for-humans",),
    "adversarial-documentation-reviewer": ("adversarial-review", "writing-for-humans"),
}
for name, prefix in docs_autoload.items():
    agent = custom.get(name) or {}
    skills = tuple(agent.get("autoLoadSkills") or [])
    if skills[: len(prefix)] != prefix:
        errors.append(f"{name} autoLoadSkills={list(skills)!r} does not start with {list(prefix)!r}")

docs_members = (((hive.get("council") or {}).get("groups") or {}).get("documents") or {}).get("members") or []
if "documentation-reviewer" not in docs_members:
    errors.append("council.groups.documents missing documentation-reviewer")
if "code-reviewer-documentation" in docs_members:
    errors.append("council.groups.documents still references code-reviewer-documentation")

groups = ((hive.get("council") or {}).get("groups") or {})
design = groups.get("design") or {}
if design.get("maxMembers") != 5:
    errors.append(f"council.groups.design.maxMembers={design.get('maxMembers')!r}, expected 5")
for group_name in ("design", "ui"):
    members = (groups.get(group_name) or {}).get("members") or []
    if "ui-reviewer" not in members:
        errors.append(f"council.groups.{group_name} missing ui-reviewer")
    if "code-reviewer-ui" in members:
        errors.append(f"council.groups.{group_name} still references code-reviewer-ui")

summarizer = hive.get("taskTraceSummarizer") or {}
if summarizer.get("model") not in allowed_models:
    errors.append(f"taskTraceSummarizer.model={summarizer.get('model')}")

exact_seats = {
    "forager-capable": ("openai/gpt-5.6-sol", "high"),
    "forager-documents": ("openai/gpt-5.6-sol", "high"),
    "forager-fast": ("openai/gpt-5.6-luna", "xhigh"),
    "forager-ui": ("openai/gpt-5.6-sol", "max"),
    "adversarial-plan-reviewer": ("openai/gpt-5.6-sol", "max"),
    "adversarial-documentation-reviewer": ("openai/gpt-5.6-sol", "max"),
    "adversarial-code-reviewer": ("openai/gpt-5.6-sol", "max"),
    "adversarial-simplicity-reviewer": ("openai/gpt-5.6-sol", "max"),
    "adversarial-approach-advisor": ("openai/gpt-5.6-sol", "max"),
    "ui-design-advisor": ("openai/gpt-5.6-sol", "max"),
    "scout-researcher-capable": ("openai/gpt-5.6-luna", "xhigh"),
    "scout-researcher-code": ("openai/gpt-5.6-sol", "max"),
    "forager-worker": ("openai/gpt-5.6-sol", "medium"),
    "hive-helper": ("openai/gpt-5.6-sol", "max"),
    "ui-reviewer": ("openai/gpt-5.6-sol", "xhigh"),
    "vulnerability-reviewer": ("openai/gpt-5.6-sol", "max"),
}
for name, expected in exact_seats.items():
    entry = custom.get(name) or (hive.get("agents") or {}).get(name) or {}
    actual = (entry.get("model"), entry.get("variant"))
    if actual != expected:
        errors.append(f"{name} model/variant={actual!r}, expected {expected!r}")

agents = hive.get("agents") or {}
if (agents.get("forager-worker") or {}).get("autoLoadSkills") != ["verification"]:
    errors.append("forager-worker must autoload canonical verification")
builder_skills = (agents.get("hive-builder") or {}).get("autoLoadSkills") or []
if not builder_skills or builder_skills[0] != "verification":
    errors.append(f"hive-builder autoLoadSkills={builder_skills!r} must start with canonical verification")

for path, value in walk(hive):
    if value == "verification-before-completion":
        errors.append(f"deprecated verification-before-completion at {path}")
    if value in {"ivan-writing", "impeccable"}:
        errors.append(f"shared Agent Hive config contains personal-only skill {value} at {path}")

ui_skills = {
    "forager-ui": ("web-design-guidelines", "stop-design-slop"),
    "ui-reviewer": ("web-design-guidelines", "stop-design-slop"),
    "ui-design-advisor": ("web-design-guidelines", "stop-design-slop"),
}
for name, expected in ui_skills.items():
    skills = tuple((custom.get(name) or {}).get("autoLoadSkills") or [])
    if skills != expected:
        errors.append(f"{name} autoLoadSkills={list(skills)!r}, expected {list(expected)!r}")

for profile_path in sorted((root / "profiles/agents").glob("*.md")):
    text = profile_path.read_text(encoding="utf-8")
    if "verification-before-completion" in text:
        errors.append(f"{profile_path.relative_to(root)} still references verification-before-completion")

if not plugin_path.is_file():
    errors.append("profiles/base/plugins/dcg-guard.js missing")
else:
    text = plugin_path.read_text(encoding="utf-8")
    if "Bun.which(\"dcg\")" not in text or "tool.execute.before" not in text:
        errors.append("dcg-guard.js is not the Destructive Command Guard adapter")

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("ok")
PY
then
  pass "65a: base payloads are OpenAI gpt-5.6 luna/sol with required Hive seats"
else
  fail "65b: base payloads are OpenAI gpt-5.6 luna/sol with required Hive seats"
fi

# ---------------------------------------------------------------------------
# 66. Extra drawio-skill files, including a local venv, fail Cursor validation
# ---------------------------------------------------------------------------
printf '\n=== 66. Extra drawio-skill source entries rejected ===\n'
td66="${TMPDIR}/test66"; mkdir -p "${td66}"
build_fixture
mkdir -p "${REPO_FIXTURE}/.apm/skills/drawio-skill/.venv"
printf 'stub\n' > "${REPO_FIXTURE}/.apm/skills/drawio-skill/.venv/pyvenv.cfg"
! CURSOR_CONFIG_DIR="${td66}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td66}/err" || fail "66a: should have failed"
grep -q 'drawio-skill/.venv' "${td66}/err" && pass "66b: extra drawio-skill venv rejected" || fail "66c: wrong error: $(cat ${td66}/err)"
cursor_target_unmodified "${td66}" && pass "66d: no managed paths created" || fail "66e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 67. Cursor Engineering Judgment portability contracts
# ---------------------------------------------------------------------------
printf '\n=== 67. Cursor Engineering Judgment portability contracts ===\n'
vendor_rel='vendor/oc-arkive/engineering-judgment/engineering-judgment.md'
provenance_rel='vendor/oc-arkive/engineering-judgment/provenance.json'
sync_rel='scripts/sync-engineering-judgment.py'
anchor='Apply Engineering Judgment from active Cursor Rules within this role'"'"'s current scope and finding bar.'

if [[ -f "${BASELINE_PWD}/${vendor_rel}" && ! -L "${BASELINE_PWD}/${vendor_rel}" && -f "${BASELINE_PWD}/${provenance_rel}" && ! -L "${BASELINE_PWD}/${provenance_rel}" ]]; then
  pass "67a: vendored Engineering Judgment and provenance are regular files"
else
  fail "67a: vendored Engineering Judgment and provenance must be regular non-symlinked files"
fi

if [[ -x "${BASELINE_PWD}/${sync_rel}" ]]; then
  pass "67b: Engineering Judgment sync script exists and is executable"
else
  fail "67b: Engineering Judgment sync script missing or not executable"
fi

upstream67="${TMPDIR}/upstream67"
mkdir -p "${upstream67}/packages/opencode-hive/src/agents"
cat > "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts" <<'TS'
export const ENGINEERING_JUDGMENT_PROMPT = `## Engineering Judgment

Committed fixture guidance.`;
TS
cat > "${upstream67}/packages/opencode-hive/package.json" <<'JSON'
{
  "name": "oc-arkive",
  "version": "9.8.7",
  "repository": {
    "type": "git",
    "url": "https://example.test/agent-hive.git",
    "directory": "packages/opencode-hive"
  }
}
JSON
git -C "${upstream67}" init -q
git -C "${upstream67}" add .
git -C "${upstream67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm fixture
commit67="$(git -C "${upstream67}" rev-parse HEAD)"
printf '%s\n' 'export const ENGINEERING_JUDGMENT_PROMPT = `dirty checkout must not be read`;' > "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts"

if [[ -x "${REPO_FIXTURE}/${sync_rel}" ]]; then
  if "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67.out" 2>"${TMPDIR}/sync67.err"; then
    if python3 - "${REPO_FIXTURE}" "${commit67}" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
commit = sys.argv[2]
directory = root / 'vendor/oc-arkive/engineering-judgment'
markdown = directory / 'engineering-judgment.md'
provenance = json.loads((directory / 'provenance.json').read_text(encoding='utf-8'))
expected_markdown = b'## Engineering Judgment\n\nCommitted fixture guidance.\n'
expected_provenance = {
    'schemaVersion': 1,
    'upstreamRepository': 'https://example.test/agent-hive.git',
    'commit': commit,
    'sourcePath': 'packages/opencode-hive/src/agents/engineering-judgment.ts',
    'packageVersion': '9.8.7',
    'sha256': hashlib.sha256(expected_markdown).hexdigest(),
}
if markdown.read_bytes() != expected_markdown:
    raise SystemExit('sync did not extract normalized committed prompt body')
if provenance != expected_provenance:
    raise SystemExit(f'wrong provenance: {provenance!r}')
PY
    then
      pass "67c: sync reads committed Git objects and writes normalized content with deterministic provenance"
    else
      fail "67c: sync output or provenance was incorrect"
    fi
    snapshot67a="$(sha256sum "${REPO_FIXTURE}/${vendor_rel}" "${REPO_FIXTURE}/${provenance_rel}")"
    "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67-second.out" 2>"${TMPDIR}/sync67-second.err"
    snapshot67b="$(sha256sum "${REPO_FIXTURE}/${vendor_rel}" "${REPO_FIXTURE}/${provenance_rel}")"
    [[ "${snapshot67a}" == "${snapshot67b}" ]] && pass "67d: repeated sync is byte deterministic" || fail "67d: repeated sync changed vendor output"

    git -C "${upstream67}" checkout -q -- packages/opencode-hive/src/agents/engineering-judgment.ts
    replace_fixture_text "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts" 'Committed fixture guidance.' 'Replacement object guidance.'
    git -C "${upstream67}" add .
    git -C "${upstream67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm replacement
    replacement67="$(git -C "${upstream67}" rev-parse HEAD)"
    git -C "${upstream67}" replace "${commit67}" "${replacement67}"
    if "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref "${commit67}" >"${TMPDIR}/sync67-replace.out" 2>"${TMPDIR}/sync67-replace.err" &&
      grep -q 'Committed fixture guidance' "${REPO_FIXTURE}/${vendor_rel}" &&
      ! grep -q 'Replacement object guidance' "${REPO_FIXTURE}/${vendor_rel}" &&
      grep -q "${commit67}" "${REPO_FIXTURE}/${provenance_rel}"; then
      pass "67e: sync ignores Git replacement objects for commit and tree identity"
    else
      fail "67e: Git replacement object changed synced content or provenance"
    fi
    git -C "${upstream67}" replace -d "${commit67}" >/dev/null
    git -C "${upstream67}" reset -q --hard "${commit67}"

    redirected67="${TMPDIR}/redirected67"
    mkdir -p "${redirected67}/packages/opencode-hive/src/agents"
    cat > "${redirected67}/packages/opencode-hive/src/agents/engineering-judgment.ts" <<'TS'
export const ENGINEERING_JUDGMENT_PROMPT = `## Engineering Judgment

Ambient GIT_DIR content must not be synced.`;
TS
    cat > "${redirected67}/packages/opencode-hive/package.json" <<'JSON'
{
  "name": "oc-arkive",
  "version": "0.0.1",
  "repository": "https://wrong.example.test/redirected.git"
}
JSON
    git -C "${redirected67}" init -q
    git -C "${redirected67}" add .
    git -C "${redirected67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm redirected
    if GIT_DIR="${redirected67}/.git" "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67-git-dir.out" 2>"${TMPDIR}/sync67-git-dir.err" &&
      grep -q 'Committed fixture guidance' "${REPO_FIXTURE}/${vendor_rel}" &&
      ! grep -q 'Ambient GIT_DIR content' "${REPO_FIXTURE}/${vendor_rel}" &&
      grep -q "${commit67}" "${REPO_FIXTURE}/${provenance_rel}" &&
      grep -q 'https://example.test/agent-hive.git' "${REPO_FIXTURE}/${provenance_rel}"; then
      pass "67e2: sync ignores ambient GIT_DIR repository redirection"
    else
      fail "67e2: ambient GIT_DIR redirected synced content or provenance"
    fi

    if python3 - "${REPO_FIXTURE}/${sync_rel}" "${REPO_FIXTURE}" <<'PY'
import importlib.util
import sys
from pathlib import Path

script = Path(sys.argv[1])
root = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location('sync_engineering_judgment', script)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
output_directory = root / 'vendor/oc-arkive/engineering-judgment'
destination = output_directory / 'write-failure.md'
before = set(output_directory.glob(f'.{destination.name}.*'))
real_named_temporary_file = module.tempfile.NamedTemporaryFile

class FailingWrite:
    def __init__(self, temporary):
        self.temporary = temporary

    def __enter__(self):
        self.temporary.__enter__()
        return self

    def __exit__(self, *args):
        return self.temporary.__exit__(*args)

    @property
    def name(self):
        return self.temporary.name

    def write(self, content):
        self.temporary.write(content[:1])
        self.temporary.flush()
        raise OSError('injected write failure')

def failing_named_temporary_file(*args, **kwargs):
    return FailingWrite(real_named_temporary_file(*args, **kwargs))

module.tempfile.NamedTemporaryFile = failing_named_temporary_file
try:
    module.atomic_write(root, output_directory, destination, b'partial content')
except OSError as error:
    if str(error) != 'injected write failure':
        raise
else:
    raise SystemExit('atomic_write unexpectedly accepted the injected failure')

after = set(output_directory.glob(f'.{destination.name}.*'))
if after != before:
    raise SystemExit(f'partial temporary file leaked: {sorted(after - before)}')
if destination.exists():
    raise SystemExit('failed write created the destination')
PY
    then
      pass "67e3: sync removes partial temporary files after write failure"
    else
      fail "67e3: sync leaked a partial temporary file after write failure"
    fi
  else
    fail "67c: sync failed: $(cat "${TMPDIR}/sync67.err")"
    fail "67d: repeated sync could not be checked"
  fi

  git -C "${upstream67}" checkout -q -- packages/opencode-hive/src/agents/engineering-judgment.ts
  python3 - "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(
    'export const ENGINEERING_JUDGMENT_PROMPT = `unsupported ${interpolation}`;\n',
    encoding='utf-8',
)
PY
  git -C "${upstream67}" add .
  git -C "${upstream67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm interpolation
  if ! "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67-bad.out" 2>"${TMPDIR}/sync67-bad.err" && grep -qi 'interpolation\|unsupported' "${TMPDIR}/sync67-bad.err"; then
    pass "67f: sync rejects interpolated upstream prompt bodies"
  else
    fail "67f: sync accepted interpolation or returned the wrong error"
  fi
else
  fail "67c: sync behavior unavailable"
  fail "67d: repeated sync behavior unavailable"
  fail "67e: Git replacement behavior unavailable"
  fail "67f: interpolation rejection unavailable"
fi

for target67 in "${vendor_rel}" "${provenance_rel}"; do
  build_fixture
  sentinel67="${TMPDIR}/${target67##*/}.sentinel"
  printf 'external sentinel\n' > "${sentinel67}"
  rm "${REPO_FIXTURE}/${target67}"
  ln -s "${sentinel67}" "${REPO_FIXTURE}/${target67}"
  if ! "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref "${commit67}" >"${TMPDIR}/sync67-leaf.out" 2>"${TMPDIR}/sync67-leaf.err" &&
    grep -qi 'symlink\|safe path' "${TMPDIR}/sync67-leaf.err" &&
    [[ "$(cat "${sentinel67}")" == 'external sentinel' ]]; then
    pass "67g: sync rejects ${target67##*/} leaf symlink without overwriting its target"
  else
    fail "67g: sync followed ${target67##*/} leaf symlink or returned the wrong error"
  fi
done

build_fixture
external67="${TMPDIR}/external-vendor67"
mkdir -p "${external67}"
printf 'external sentinel\n' > "${external67}/sentinel"
rm -rf "${REPO_FIXTURE}/vendor/oc-arkive"
ln -s "${external67}" "${REPO_FIXTURE}/vendor/oc-arkive"
if ! "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref "${commit67}" >"${TMPDIR}/sync67-ancestor.out" 2>"${TMPDIR}/sync67-ancestor.err" &&
  grep -qi 'symlink\|safe path' "${TMPDIR}/sync67-ancestor.err" &&
  [[ "$(cat "${external67}/sentinel")" == 'external sentinel' ]] &&
  [[ ! -e "${external67}/engineering-judgment" ]]; then
  pass "67h: sync rejects ancestor symlink without writing outside the repository"
else
  fail "67h: sync followed an ancestor symlink or returned the wrong error"
fi

build_fixture
if "${CURSOR_HELPER}" validate >"${TMPDIR}/validate67.out" 2>"${TMPDIR}/validate67.err"; then
  pass "67i: valid vendored Engineering Judgment passes Cursor validation"
else
  fail "67i: valid vendor failed validation: $(cat "${TMPDIR}/validate67.err")"
fi

printf '\nTampered.\n' >> "${REPO_FIXTURE}/${vendor_rel}"
if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/tamper67.out" 2>"${TMPDIR}/tamper67.err" && grep -Eqi 'hash|sha-?256' "${TMPDIR}/tamper67.err"; then
  pass "67j: content hash tampering is rejected"
else
  fail "67j: content hash tampering was accepted or returned the wrong error"
fi

build_fixture
replace_fixture_text "${REPO_FIXTURE}/${provenance_rel}" '0123456789abcdef0123456789abcdef01234567' 'HEAD'
if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/mutable67.out" 2>"${TMPDIR}/mutable67.err" && grep -qi 'commit\|immutable' "${TMPDIR}/mutable67.err"; then
  pass "67k: mutable provenance refs are rejected"
else
  fail "67k: mutable provenance ref was accepted or returned the wrong error"
fi

build_fixture
printf 'null\n' > "${REPO_FIXTURE}/${provenance_rel}"
if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/root67.out" 2>"${TMPDIR}/root67.err" &&
  grep -qi 'provenance.*object\|object.*provenance' "${TMPDIR}/root67.err" &&
  ! grep -q 'Traceback' "${TMPDIR}/root67.err"; then
  pass "67k2: malformed provenance root is rejected without a traceback"
else
  fail "67k2: malformed provenance root did not produce a controlled validation failure"
fi

for malformed67 in \
  'schemaVersion|true|schemaVersion.*integer.*1' \
  'upstreamRepository|[]|upstreamRepository.*non-empty string' \
  'commit|123|commit.*immutable.*commit' \
  'sourcePath|123|sourcePath.*oc-arkive authority' \
  'packageVersion|[]|packageVersion.*non-empty string' \
  'sha256|123|sha256.*lowercase SHA-256'; do
  IFS='|' read -r field67 value67 error67 <<< "${malformed67}"
  build_fixture
  python3 - "${REPO_FIXTURE}/${provenance_rel}" "${field67}" "${value67}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
field = sys.argv[2]
value = json.loads(sys.argv[3])
provenance = json.loads(path.read_text(encoding='utf-8'))
provenance[field] = value
path.write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8', newline='\n')
PY
  if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/${field67}67.out" 2>"${TMPDIR}/${field67}67.err" &&
    grep -Eqi "${error67}" "${TMPDIR}/${field67}67.err" &&
    ! grep -q 'Traceback' "${TMPDIR}/${field67}67.err"; then
    pass "67k3: malformed provenance ${field67} is rejected without a traceback"
  else
    fail "67k3: malformed provenance ${field67} did not produce a controlled validation failure"
  fi
done

for target67 in "${vendor_rel}" "${provenance_rel}"; do
  build_fixture
  rm "${REPO_FIXTURE}/${target67}"
  ln -s /dev/null "${REPO_FIXTURE}/${target67}"
  if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/symlink67.out" 2>"${TMPDIR}/symlink67.err" && grep -qi 'symlink\|regular file' "${TMPDIR}/symlink67.err"; then
    pass "67l: validation rejects ${target67##*/} leaf symlink"
  else
    fail "67l: validation accepted ${target67##*/} leaf symlink or returned the wrong error"
  fi
done

build_fixture
external_validate67="${TMPDIR}/external-validate67"
mkdir -p "${external_validate67}/engineering-judgment"
cp "${REPO_FIXTURE}/${vendor_rel}" "${external_validate67}/engineering-judgment/engineering-judgment.md"
cp "${REPO_FIXTURE}/${provenance_rel}" "${external_validate67}/engineering-judgment/provenance.json"
rm -rf "${REPO_FIXTURE}/vendor/oc-arkive"
ln -s "${external_validate67}" "${REPO_FIXTURE}/vendor/oc-arkive"
if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/ancestor67.out" 2>"${TMPDIR}/ancestor67.err" && grep -qi 'symlink\|outside' "${TMPDIR}/ancestor67.err"; then
  pass "67m: validation rejects a vendored ancestor symlink"
else
  fail "67m: validation accepted a vendored ancestor symlink or returned the wrong error"
fi

build_fixture
printf '\nhive_forbidden_vendor_token\n' >> "${REPO_FIXTURE}/${vendor_rel}"
python3 - "${REPO_FIXTURE}/${vendor_rel}" "${REPO_FIXTURE}/${provenance_rel}" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

vendor = Path(sys.argv[1])
provenance_path = Path(sys.argv[2])
provenance = json.loads(provenance_path.read_text(encoding='utf-8'))
provenance['sha256'] = hashlib.sha256(vendor.read_bytes()).hexdigest()
provenance_path.write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8', newline='\n')
PY
if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/portable67.out" 2>"${TMPDIR}/portable67.err" && grep -qi 'Hive tool name\|composed Rules' "${TMPDIR}/portable67.err"; then
  pass "67n: complete composed Rules reject forbidden vendored tokens after valid reprovenance"
else
  fail "67n: forbidden vendored token passed composed Rules validation or returned the wrong error"
fi

build_fixture
if "${CURSOR_HELPER}" print-rules >"${TMPDIR}/rules67.out" 2>"${TMPDIR}/rules67.err" && python3 - "${REPO_FIXTURE}" "${TMPDIR}/rules67.out" "${TMPDIR}/rules67.err" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
actual = Path(sys.argv[2]).read_bytes()
stderr = Path(sys.argv[3]).read_bytes()
rules = (root / '.apm/cursor/rules/default-agent.md').read_bytes()
judgment = (root / 'vendor/oc-arkive/engineering-judgment/engineering-judgment.md').read_bytes()
expected = rules + b'\n---\n\n' + judgment
if actual != expected:
    raise SystemExit('print-rules output does not match rules + one separator + vendor')
if actual.count(judgment) != 1 or actual.count(b'\n---\n') != 1:
    raise SystemExit('vendor body or separator was not included exactly once')
if stderr:
    raise SystemExit(f'print-rules emitted status chatter: {stderr!r}')
if b'provenance' in actual.lower() or b'0123456789abcdef0123456789abcdef01234567' in actual:
    raise SystemExit('print-rules leaked provenance chatter')
PY
then
  pass "67o: print-rules emits paste-ready ordered composition exactly once"
else
  fail "67o: print-rules composition or stdout contract is wrong"
fi

if python3 - "${BASELINE_PWD}" "${anchor}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
anchor = sys.argv[2]
selected = {'forager', 'plan-reviewer', 'code-reviewer', 'simplicity-reviewer'}
excluded = {'scout', 'approach-advisor'}
errors = []
for name in selected:
    text = (root / f'.apm/cursor/agents/{name}.md').read_text(encoding='utf-8')
    if text.count(anchor) != 1:
        errors.append(f'{name} anchor count is {text.count(anchor)}')
for name in excluded:
    text = (root / f'.apm/cursor/agents/{name}.md').read_text(encoding='utf-8')
    if 'Engineering Judgment' in text:
        errors.append(f'{name} must remain unchanged')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "67p: selected Cursor roles have one scoped anchor and excluded roles remain unchanged"
else
  fail "67p: Cursor role anchor contract is not satisfied"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
paths = [
    root / 'profiles/base/agent_hive.json',
    root / 'profiles/base/opencode.json',
    *sorted((root / 'profiles/base/plugins').rglob('*')),
    *sorted((root / 'profiles/optional').glob('*.json')),
    *sorted((root / 'profiles/agents').glob('*.md')),
]
for directory in (
    root / '.apm/prompts',
    root / '.apm/skills',
    root / '.apm/agents',
    root / 'profiles/personal/skills',
):
    if not directory.is_dir():
        continue
    paths.extend(path for path in sorted(directory.rglob('*')) if path.is_file())
for path in paths:
    if not path.is_file():
        continue
    text = path.read_text(encoding='utf-8', errors='ignore')
    if '## Engineering Judgment' in text or 'ENGINEERING_JUDGMENT_PROMPT' in text:
        raise SystemExit(f'Engineering Judgment copy leaked into {path.relative_to(root)}')
PY
then
  pass "67q: every installer-owned OpenCode source contains no Engineering Judgment copy"
else
  fail "67q: Engineering Judgment leaked into an OpenCode delivery surface"
fi

tracked_markdown67="${TMPDIR}/tracked-markdown67"
mkdir -p "${tracked_markdown67}"
git -C "${tracked_markdown67}" init -q
printf '%s\n' '*.ignored.md' > "${tracked_markdown67}/.gitignore"
printf '%s\n' '# Canonical Cursor destination' > "${tracked_markdown67}/guide.md"
printf '%s\n' 'Cursor Settings -> Rules' > "${tracked_markdown67}/stale.ignored.md"
git -C "${tracked_markdown67}" add .gitignore guide.md
if tracked_markdown_uses_canonical_cursor_destination "${tracked_markdown67}" >"${TMPDIR}/ignored67r.out" 2>"${TMPDIR}/ignored67r.err"; then
  pass "67r1: ignored untracked stale Markdown is not treated as shipped"
else
  fail "67r1: ignored untracked stale Markdown was treated as shipped"
fi

git -C "${tracked_markdown67}" add -f stale.ignored.md
if ! tracked_markdown_uses_canonical_cursor_destination "${tracked_markdown67}" >"${TMPDIR}/tracked67r.out" 2>"${TMPDIR}/tracked67r.err" &&
  grep -q 'stale.ignored.md' "${TMPDIR}/tracked67r.err"; then
  pass "67r2: tracked stale Markdown is rejected"
else
  fail "67r2: tracked stale Markdown was not rejected"
fi

if tracked_markdown_uses_canonical_cursor_destination "${BASELINE_PWD}"; then
  pass "67r: shipped Markdown uses the canonical Cursor Customize Rules destination"
else
  fail "67r: shipped Markdown contains the obsolete Cursor Settings Rules destination"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
docs = ('README.md', 'CURSOR.md', 'FOR-LLM-AGENTS.md', '.apm/cursor/README.md')
errors = []
for relative in docs:
    text = (root / relative).read_text(encoding='utf-8')
    lowered = text.casefold()
    required = (
        ('current npm `oc-arkive@latest` is 2.3.5', 'published npm version'),
        ('includes engineering judgment', 'published plugin contents'),
        ('opencode receives engineering judgment from the installed plugin', 'OpenCode delivery'),
        ('provenance-pinned vendored snapshot', 'Cursor delivery'),
        ('cursor cannot load the plugin prompt directly', 'Cursor plugin limitation'),
    )
    for phrase, label in required:
        if phrase.casefold() not in lowered:
            errors.append(f'{relative} is missing {label}: {phrase}')
    for obsolete in ('2.3.4', 'postdates tag', 'does not contain engineering judgment', 'does not contain it'):
        if obsolete in lowered:
            errors.append(f'{relative} retains obsolete unpublished-release wording: {obsolete}')

vendor = root / 'vendor/oc-arkive/engineering-judgment/engineering-judgment.md'
provenance = json.loads((vendor.parent / 'provenance.json').read_text(encoding='utf-8'))
expected_release = {
    'commit': '60d55b91f7a5cc4180d7667ed211ee39e77f4333',
    'packageVersion': '2.3.5',
}
for field, expected in expected_release.items():
    if provenance.get(field) != expected:
        errors.append(f'provenance {field} is {provenance.get(field)!r}, expected {expected!r}')
actual_hash = hashlib.sha256(vendor.read_bytes()).hexdigest()
if provenance.get('sha256') != actual_hash:
    errors.append(f'provenance sha256 is {provenance.get("sha256")!r}, expected {actual_hash!r}')

if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "67s: published oc-arkive 2.3.5 documentation and provenance boundary"
else
  fail "67s: published oc-arkive 2.3.5 documentation and provenance boundary"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n=== Summary ===\n'
printf '  Passed: %d\n' "${PASS}"
printf '  Failed: %d\n' "${FAIL}"
if [[ "${FAIL}" -gt 0 ]]; then
  printf '  Failed tests:\n'
  for f in "${FAIL_NAMES[@]}"; do printf '    - %s\n' "${f}"; done
  exit 1
fi
exit 0
