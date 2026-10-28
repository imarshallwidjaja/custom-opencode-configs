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
sandbox_agents_skills() {
  AGENTS_SKILLS_DIR="$(mktemp -d "${TMPDIR}/agents-skills.XXXXXX")"
  export AGENTS_SKILLS_DIR
}
sandbox_agents_skills

REPO_FIXTURE="${TMPDIR}/reporoot"
# Cursor skills that Hive also bundles, and the name the Cursor bundle retired.
HIVE_BUNDLED_NAMES="humanizer stop-design-slop stop-slop unslop writing-for-agents writing-for-humans"
HIVE_RETIRED_NAME=writing-policy
# The OpenCode profile supports the oc-arkive v3.0.0 bundle, which still ships writing-policy and lacks unslop.
OPENCODE_HIVE_BUNDLED_NAMES="humanizer stop-design-slop stop-slop writing-for-humans writing-policy"

stub_canonical_skill_tree() {
  local skill_name="$1"
  local skills_root="${2:-.apm/skills}"
  python3 - "$BASELINE_PWD" "$REPO_FIXTURE" "$skill_name" "$skills_root" <<'PY'
import sys
from pathlib import Path

repo = Path(sys.argv[1])
fixture = Path(sys.argv[2])
name = sys.argv[3]
src = repo / sys.argv[4] / name
dest = fixture / sys.argv[4] / name
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
  for skill in connecting-atlassian-tools cymbal hard-cut managing-work-in-jira web-design-guidelines writing-skills; do
    mkdir -p "${REPO_FIXTURE}/.apm/skills/${skill}"
    cat > "${REPO_FIXTURE}/.apm/skills/${skill}/SKILL.md" <<SKILL
---
name: ${skill}
description: Use when testing fixture canonical skill ${skill}.
---
OK
SKILL
  done

  stub_canonical_skill_tree frontend-slides
  stub_canonical_skill_tree drawio-skill
  stub_canonical_skill_tree react-best-practices
  stub_canonical_skill_tree resume-tailoring
  stub_canonical_skill_tree aero-design
  stub_canonical_skill_tree decomposing-work
  stub_canonical_skill_tree running-agile-delivery
  stub_canonical_skill_tree ui-mockups
  stub_canonical_skill_tree writing-work-items
  stub_canonical_skill_tree working-with-atlassian

  # Cursor asset root (.apm/cursor/)
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/agents" "${REPO_FIXTURE}/.apm/cursor/commands" "${REPO_FIXTURE}/.apm/cursor/skills" "${REPO_FIXTURE}/.apm/cursor/rules"

  # Cursor agents
  for agent in approach-advisor code-reviewer forager plan-reviewer scout simplicity-reviewer vulnerability-reviewer; do
    agent_readonly=true
    [[ "${agent}" != forager ]] || agent_readonly=false
    cat > "${REPO_FIXTURE}/.apm/cursor/agents/${agent}.md" <<AGENT
---
name: ${agent}
description: Test agent ${agent}
model: inherit
readonly: ${agent_readonly}
---
Apply the Engineering Judgment section appended to this prompt within this role's current scope and finding bar.
AGENT
  done

  # Cursor commands
  for cmd in compact-summary council-directive council dash-review grill implementation-brief interview vuln-review; do
    echo "# ${cmd}" > "${REPO_FIXTURE}/.apm/cursor/commands/${cmd}.md"
  done

  # Shared prompt-backed commands
  mkdir -p "${REPO_FIXTURE}/.apm/prompts"
  cat > "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" <<'PROMPT'
---
description: Review this session and propose durable agent-memory learnings
---
Propose durable learnings and wait for operator approval before editing memory files.
PROMPT
  cat > "${REPO_FIXTURE}/.apm/prompts/planning-prompt.prompt.md" <<'PROMPT'
---
description: Turn current exploration into a strong planning-agent prompt
---
Write one planning prompt from the exploration so far.
PROMPT
  cat > "${REPO_FIXTURE}/.apm/prompts/interview-drill-down.prompt.md" <<'PROMPT'
---
description: "Interview the operator about a repo-scoped idea. Use for a repo interview."
---
Ask one question at a time.
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
  for skill in adversarial-review agents-md-mastery brainstorming code-design-principles complexity-audit complexity-review finishing-a-development-branch grilling how humanizer orchestrating-ad-hoc-work parallel-exploration pr-writing project-verification stop-slop subagent-delegation systematic-debugging test-driven-development unslop using-git-worktrees verification why writing-for-agents writing-for-humans; do
    mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/${skill}"
    cat > "${REPO_FIXTURE}/.apm/cursor/skills/${skill}/SKILL.md" <<SKILL
---
name: ${skill}
description: Use when testing fixture Cursor skill ${skill}.
---
OK
SKILL
  done

  stub_canonical_skill_tree stop-design-slop .apm/cursor/skills

  mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/references"
  echo "# Patterns" > "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/references/patterns.md"
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/stop-slop/references"
  echo "# Examples" > "${REPO_FIXTURE}/.apm/cursor/skills/stop-slop/references/examples.md"
  echo "# Phrases" > "${REPO_FIXTURE}/.apm/cursor/skills/stop-slop/references/phrases.md"
  echo "# Structures" > "${REPO_FIXTURE}/.apm/cursor/skills/stop-slop/references/structures.md"
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/writing-for-humans/references"
  echo "# Examples" > "${REPO_FIXTURE}/.apm/cursor/skills/writing-for-humans/references/examples.md"
  echo "# Sources" > "${REPO_FIXTURE}/.apm/cursor/skills/writing-for-humans/references/sources.md"

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
  printf '%s\n' '// fixture shell-agents' > "${REPO_FIXTURE}/profiles/base/plugins/shell-agents.js"
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
  if [[ -f "${BASELINE_PWD}/scripts/sync-cursor-hive-skills.py" ]]; then
    cp "${BASELINE_PWD}/scripts/sync-cursor-hive-skills.py" "${REPO_FIXTURE}/scripts/sync-cursor-hive-skills.py"
  fi
  chmod +x "${REPO_FIXTURE}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/install-profile.sh"
  [[ ! -f "${REPO_FIXTURE}/scripts/sync-engineering-judgment.py" ]] || chmod +x "${REPO_FIXTURE}/scripts/sync-engineering-judgment.py"
  [[ ! -f "${REPO_FIXTURE}/scripts/sync-cursor-hive-skills.py" ]] || chmod +x "${REPO_FIXTURE}/scripts/sync-cursor-hive-skills.py"
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

# CLI entry points must not reach installation, validation, or hooks.
printf '=== OpenCode installer argument safety ===\n'
cli_scope="${TMPDIR}/installer-cli"
mkdir -p "${cli_scope}/target/skills" "${cli_scope}/shared" "${cli_scope}/home" "${TMPDIR}/cli-bin"
printf 'existing config\n' > "${cli_scope}/target/opencode.json"
printf 'keep\n' > "${cli_scope}/target/skills/sentinel"
printf 'keep\n' > "${cli_scope}/shared/sentinel"
cat > "${TMPDIR}/cli-bin/cymbal" <<'HOOK'
#!/usr/bin/env bash
printf 'called\n' >> "${HOME}/hook-called"
exit 1
HOOK
chmod +x "${TMPDIR}/cli-bin/cymbal"
cli_before="$(snapshot_tree "${cli_scope}")"
for cli_case in preview help unknown positional empty duplicate-apply duplicate-help conflict reverse-conflict extra; do
  case "${cli_case}" in
    preview) set -- ; expected=0; marker='Would install' ;;
    help) set -- --help; expected=0; marker='Usage:' ;;
    unknown) set -- --unknown; expected=2; marker='Usage:' ;;
    positional) set -- install; expected=2; marker='Usage:' ;;
    empty) set -- ''; expected=2; marker='Usage:' ;;
    duplicate-apply) set -- --apply --apply; expected=2; marker='Usage:' ;;
    duplicate-help) set -- --help --help; expected=2; marker='Usage:' ;;
    conflict) set -- --help --apply; expected=2; marker='Usage:' ;;
    reverse-conflict) set -- --apply --help; expected=2; marker='Usage:' ;;
    extra) set -- --apply extra; expected=2; marker='Usage:' ;;
  esac
  # Invalid settings prove argument handling precedes profile validation.
  for cli_profile in shared missing-profile; do
    cli_status=0
    HOME="${cli_scope}/home" PATH="${TMPDIR}/cli-bin:/usr/bin:/bin" \
      OPENCODE_CONFIG_DIR="${cli_scope}/target" AGENTS_SKILLS_DIR="${cli_scope}/shared" \
      OPENCODE_AGENTS_PROFILE="${cli_profile}" bash "${INSTALL_HELPER}" "$@" \
      >"${TMPDIR}/cli-output" 2>&1 || cli_status=$?
    if [[ "${cli_status}" -eq "${expected}" ]] && grep -q "${marker}" "${TMPDIR}/cli-output" \
      && [[ "${cli_before}" == "$(snapshot_tree "${cli_scope}")" ]]; then
      pass "CLI ${cli_case} (${cli_profile}): expected exit, unchanged targets, no hook"
    else
      fail "CLI ${cli_case} (${cli_profile}): status/output or mutation mismatch"
    fi
  done
done
set --

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
    "every entry must change agent behavior",
    "prune test",
    "progressive placement",
    "write what exists",
    "item-level approval",
    "nested `agents.md`",
    "signal versus noise",
    "cursor user rules",
    "scratchpad",
    "paste-ready",
    "not applied",
    "manual target",
)
missing = [contract for contract in contracts if contract not in lowered]
if missing:
    raise SystemExit(f"skill is missing behavioral contracts: {missing}")
if not re.search(r"cursor user rules are a manual target.{0,200}supplied or visible", lowered, re.DOTALL):
    raise SystemExit("skill must keep Cursor User Rules a manual target that needs supplied or visible text")
if not re.search(r"provisional one-off preference stays in the existing scratchpad.{0,160}(?:repeated|cross-project).{0,80}evidence", lowered, re.DOTALL):
    raise SystemExit("skill must reserve promotion beyond scratchpad for repeated evidence and approval")
if "do not auto-approve" not in lowered:
    raise SystemExit("skill must require operator approval before durable edits")
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
        "no exact-one-read or exact-one-write quota",
        "bounded direct reads stay allowed",
        "non-trivial implementation, test, debug, refactor, integration, and review stay delegate-first",
        ("coordination", "setup"),
        ("trivial conversation", "trivial conversational"),
    ))
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
        "vulnerability-reviewer": (("read-only",), ("vulnerability",), ("operator-requested", "operator requested"), ("scope",)),
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
    if not re.search(
        r"parallel (?:writing )?(?:lanes?|writers?).{0,200}(?:separate )?(?:git )?worktree(?: or |, or |/)isolated (?:project )?copy",
        isolation_text,
        re.DOTALL,
    ):
        errors.append("parallel writers are not required to use a separate worktree or isolated copy")
    if re.search(
        r"(?:"
        r"shared checkout.{0,180}(?:disjoint|non-overlapping).{0,120}(?:serial|one writing lane|together|may share|may use)"
        r"|(?:disjoint|non-overlapping) (?:paths?|ownership|writing lanes?).{0,140}(?:one writing lane|run serially|shared checkout|together)"
        r"|two writers?.{0,60}(?:may|can).{0,80}(?:share|use).{0,80}(?:one |the )?(?:shared )?checkout.{0,80}disjoint"
        r"|one writing lane per owned path"
        r")",
        isolation_text,
        re.DOTALL,
    ):
        errors.append("two writers may share one checkout on disjoint paths")
    if re.search(r"(?:git )?branch (?:isolates? files|provides? (?:file isolation|true write isolation))", isolation_text, re.DOTALL):
        errors.append("a Git branch is incorrectly described as file isolation")

    # The skill handoff procedure below owns the field list; the Rules only point at it.
    require_terms(errors, "default-rule handoff", routing, (
        "self-contained", "primary goal",
        "load `subagent-delegation` before preparing any worker or reviewer packet", "single list of packet fields",
    ))
    require_terms(errors, "skill handoff procedure", lane_prompt, (
        "objective", "expected output", "in scope", "out of scope", "evidence",
        "prior failures", "dependencies", "file ownership", "verification", "blockers", "final summary",
        "artifact", "audience", "voice", "`unslop`", "parent-loaded",
    ))
    anchor_sentence = "Apply the Engineering Judgment section appended to this prompt within this role's current scope and finding bar."
    for name, text in agents.items():
        lowered_agent = text.casefold()
        require_terms(errors, f"{name} prose contract", lowered_agent, (
            "load `unslop`", "handoff states the artifact, audience, voice",
        ))
        policy_text = " ".join(line for line in lowered_agent.splitlines() if "load `unslop`" in line)
        if not re.search(r"cannot be loaded", policy_text):
            errors.append(f"{name} unslop fallback missing unresolved-skill clause")
        if not re.search(r"preserv\w*.{0,60}(?:supplied )?facts", policy_text) or "uncertainty" not in policy_text:
            errors.append(f"{name} unslop fallback must preserve supplied facts and uncertainty")
        if not re.search(r"(?:do not|don't|forbids?).{0,40}invent", policy_text):
            errors.append(f"{name} unslop fallback must forbid invented specifics")
        if "what makes this read as machine-written" in lowered_agent:
            errors.append(f"{name} copied the full finish gate into the agent definition")
        if text.count(anchor_sentence) != 1:
            errors.append(f"{name} must point at the appended Engineering Judgment exactly once")
        if "## engineering judgment" in lowered_agent or "active cursor rules" in lowered_agent or "user rules" in lowered_agent:
            errors.append(f"{name} embeds or inherits Engineering Judgment instead of receiving it at install")
        if "do not launch, ask for, or delegate to other subagents" not in lowered_agent:
            errors.append(f"{name} is not terminal")
        if name != "forager":
            require_terms(errors, f"{name} read-only contract", lowered_agent, (
                "`readonly: true`", "builds, tests", ("name the exact command", "name the command", "for the caller to run"),
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
        "do not delegate implementation", "do not launch, ask for, or delegate to other subagents",
        "commit only when the assignment explicitly authorizes it", "exact commit sha",
        "never reset or clean the whole tree", "reinspect it at coherent work milestones, committed or not,",
    ))
    destination_checkpoint = section(agents["forager"], "Destination Checkpoints")
    require_terms(errors, "forager destination checkpoint drift handling", destination_checkpoint, (
        "relevant, overlapping, uncertain", "stop and preserve the authorized state",
        "with commit authority, preserve a coherent commit and return the verified commit sha",
        "without commit authority, or before any commit exists", "changed and untracked files attributable",
        "claim no commit",
    ))
    if "committed milestones" in destination_checkpoint or "your source pin" in destination_checkpoint:
        errors.append("forager destination checkpoints still assume commit authority")
    require_terms(errors, "default-rule parent contract", lowered_rule, (
        "settle integration authority", "grants no git authority", ("report the blocker", "is a blocker"),
        "native isolation", "confirm", "fresh child", "explicit operator instruction",
        "does not own causal diagnosis", "paired correctness", "adversarial posture",
        "copy such a requirement verbatim into every affected handoff",
        "validated statically", "does not document that every child receives",
    ))
    require_terms(errors, "delegation skill handoff", lowered_skill, (
        "governing workspace root", "binding decisions", "destination identity", "source commit sha",
        "required skills, named exactly", "reviewer packets", "continue an existing child session only when",
        "does not validate those documented capabilities",
    ))

    direct_first = re.compile(r"(?:handle|work|implement).{0,50}(?:directly|itself).{0,40}(?:first|by default)|subagents?.{0,30}(?:optional|only when useful)", re.DOTALL)
    if direct_first.search(lowered_rule):
        errors.append("default Agent Rules contain direct-first policy wording")
    if "draft with `writing-for-humans`" in lowered_rule:
        errors.append("default Agent Rules still draft with writing-for-humans")
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
    "vulnerability-reviewer",
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
write_secret() { mkdir -p "$1/secrets"; printf 'test-key\n' > "$1/secrets/$2"; }
write_secret "${optional_target}" context7
write_secret "${optional_target_failing_cymbal}" context7
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
    "unrelated": {
      "type": "local",
      "command": ["unrelated-server"]
    }
  }
}
JSON
printf '{"custom":"keep"}\n' > "${optional_target}/agent_hive.json"
if PATH="${optional_bin}:/usr/bin:/bin" CYMBAL_HOOK_LOG="${TMPDIR}/cymbal-hook.log" OPENCODE_CONFIG_DIR="${optional_target}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null; then
  if [[ "$(sed -n '1p' "${TMPDIR}/cymbal-hook.log" 2>/dev/null)" == "${optional_target}" && "$(sed -n '2p' "${TMPDIR}/cymbal-hook.log" 2>/dev/null)" == "hook install opencode --scope user" ]]; then
    pass "0a: context-improved installs Cymbal hook for selected config dir"
  else
    fail "0a: context-improved installs Cymbal hook for selected config dir"
  fi
else
  fail "0a: context-improved install with Cymbal should succeed"
fi
if jq -e '(.mcp.unrelated.command == ["unrelated-server"]) and (.mcp.ast_grep.command == ["uvx", "--from", "git+https://github.com/ast-grep/ast-grep-mcp", "--with", "fastmcp", "ast-grep-server"]) and (.mcp.context7.enabled == true) and (.mcp.context7.headers.CONTEXT7_API_KEY == "{file:secrets/context7}")' "${optional_target}/opencode.json" >/dev/null; then
  pass "0b: context-improved preserves unrelated MCPs and adds context tools"
else
  fail "0b: context-improved preserves unrelated MCPs and adds context tools"
fi
if jq -e '. == {"custom":"keep"}' "${optional_target}/agent_hive.json" >/dev/null; then
  pass "0b: context-improved leaves Agent Hive config untouched"
else
  fail "0b: context-improved modified Agent Hive config"
fi
cat > "${optional_bin}/cymbal" <<'SH'
#!/bin/sh
exit 23
SH
printf '{}\n' > "${optional_target_failing_cymbal}/opencode.json"
printf '{}\n' > "${optional_target_failing_cymbal}/agent_hive.json"
if PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${optional_target_failing_cymbal}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>"${TMPDIR}/optional-failing-cymbal.err" && grep -q 'Warning: failed to install optional Cymbal OpenCode hook.' "${TMPDIR}/optional-failing-cymbal.err" && jq -e '(.mcp.ast_grep.command == ["uvx", "--from", "git+https://github.com/ast-grep/ast-grep-mcp", "--with", "fastmcp", "ast-grep-server"]) and (.mcp.context7.enabled == true)' "${optional_target_failing_cymbal}/opencode.json" >/dev/null; then
  pass "0c: failed Cymbal hook warns without failing or rolling back bundle"
else
  fail "0c: failed Cymbal hook should warn without failing or rolling back bundle"
fi

# ---------------------------------------------------------------------------
# 0d. Context-improved does not require an Agent Hive config
# ---------------------------------------------------------------------------
printf '\n=== 0d. Context-improved without Agent Hive ===\n'
td_missing_ah="${TMPDIR}/test-missing-ah"; mkdir -p "${td_missing_ah}"
write_secret "${td_missing_ah}" context7
printf '{"mcp":{}}\n' > "${td_missing_ah}/opencode.json"
if PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_missing_ah}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>&1 \
  && jq -e '(.mcp.ast_grep.command[0] == "uvx") and (.mcp.context7.enabled == true)' "${td_missing_ah}/opencode.json" >/dev/null \
  && [[ ! -e "${td_missing_ah}/agent_hive.json" ]]; then
  pass "0d: context-improved merges OpenCode MCPs without Agent Hive"
else
  fail "0d: context-improved should not require Agent Hive"
fi

# ---------------------------------------------------------------------------
# 0e. Context-improved preserves an existing malformed Agent Hive file
# ---------------------------------------------------------------------------
printf '\n=== 0e. Context-improved leaves Agent Hive file untouched ===\n'
td_malformed_ah="${TMPDIR}/test-malformed-ah"; mkdir -p "${td_malformed_ah}"
write_secret "${td_malformed_ah}" context7
printf '{"mcp":{}}\n' > "${td_malformed_ah}/opencode.json"
printf 'not json\n' > "${td_malformed_ah}/agent_hive.json"
if PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_malformed_ah}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" context-improved >/dev/null 2>&1 \
  && jq -e '(.mcp.ast_grep.command[0] == "uvx") and (.mcp.context7.enabled == true)' "${td_malformed_ah}/opencode.json" >/dev/null \
  && grep -Fqx 'not json' "${td_malformed_ah}/agent_hive.json"; then
  pass "0e: context-improved does not read or alter Agent Hive"
else
  fail "0e: context-improved changed or required Agent Hive"
fi

# ---------------------------------------------------------------------------
# 0f. MCP API keys come from config-relative secret files
# ---------------------------------------------------------------------------
printf '\n=== 0f. MCP secret-file preflights ===\n'
secret_cases=(
  "context-improved:context7"
  "mcp-context7-enabled:context7"
  "keenable:keenable"
)
for secret_case in "${secret_cases[@]}"; do
  snippet="${secret_case%%:*}"
  secret="${secret_case##*:}"
  for state in missing blank; do
    td_secret="${TMPDIR}/test-secret-${snippet}-${state}"; mkdir -p "${td_secret}"
    printf '{"mcp":{}}\n' > "${td_secret}/opencode.json"
    printf '{}\n' > "${td_secret}/agent_hive.json"
    cp "${td_secret}/opencode.json" "${td_secret}/opencode.json.before"
    if [[ "${state}" == "blank" ]]; then
      mkdir -p "${td_secret}/secrets"
      printf ' \n\t\n' > "${td_secret}/secrets/${secret}"
    fi
    if ! PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_secret}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" "${snippet}" >/dev/null 2>"${td_secret}/err" \
      && grep -q "${td_secret}/secrets/${secret}" "${td_secret}/err" \
      && cmp -s "${td_secret}/opencode.json" "${td_secret}/opencode.json.before"; then
      pass "0f: ${snippet} rejects ${state} secrets/${secret} without mutation"
    else
      fail "0f: ${snippet} must reject ${state} secrets/${secret} without mutation"
    fi
  done
done

td_keenable="${TMPDIR}/test-keenable"; mkdir -p "${td_keenable}"
write_secret "${td_keenable}" keenable
printf '{"mcp":{"unrelated":{"type":"local","command":["unrelated-server"]}}}\n' > "${td_keenable}/opencode.json"
if PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_keenable}" OPENCODE_OPTIONAL_SKIP_BACKUP=1 bash "${BASELINE_PWD}/scripts/enable-optional.sh" keenable >/dev/null \
  && jq -e '(.mcp.unrelated.command == ["unrelated-server"]) and (.mcp.keenable == {"type": "remote", "url": "https://api.keenable.ai/mcp", "headers": {"X-API-Key": "{file:secrets/keenable}"}, "enabled": true})' "${td_keenable}/opencode.json" >/dev/null; then
  pass "0f: keenable enables the remote MCP with a relative secret-file header"
else
  fail "0f: keenable enables the remote MCP with a relative secret-file header"
fi

td_write_secret="${TMPDIR}/test-write-secret"
mkdir -p "${td_write_secret}/secrets"
chmod 755 "${td_write_secret}/secrets"
printf 'old-key\n' > "${td_write_secret}/secrets/keenable"
chmod 644 "${td_write_secret}/secrets/keenable"
mode_of() { python3 -c 'import os, sys; print(format(os.stat(sys.argv[1]).st_mode & 0o777, "o"))' "$1"; }
inode_of() { python3 -c 'import os, sys; print(os.stat(sys.argv[1]).st_ino)' "$1"; }
old_inode="$(inode_of "${td_write_secret}/secrets/keenable")"
if printf 'rotated-key\n' | OPENCODE_CONFIG_DIR="${td_write_secret}" "${BASELINE_PWD}/scripts/write-secret.sh" keenable >/dev/null \
  && [[ "$(cat "${td_write_secret}/secrets/keenable")" == "rotated-key" ]] \
  && [[ "$(mode_of "${td_write_secret}/secrets/keenable")" == "600" && "$(mode_of "${td_write_secret}/secrets")" == "700" ]] \
  && [[ "$(inode_of "${td_write_secret}/secrets/keenable")" != "${old_inode}" ]] \
  && [[ "$(ls -A "${td_write_secret}/secrets")" == "keenable" ]]; then
  pass "0f: write-secret replaces a permissive key file with a new mode-600 file"
else
  fail "0f: write-secret must replace a permissive key file with a new mode-600 file"
fi
if ! printf ' \t\n' | OPENCODE_CONFIG_DIR="${td_write_secret}" "${BASELINE_PWD}/scripts/write-secret.sh" keenable >/dev/null 2>&1 \
  && [[ "$(cat "${td_write_secret}/secrets/keenable")" == "rotated-key" ]] \
  && ! OPENCODE_CONFIG_DIR="${td_write_secret}" "${BASELINE_PWD}/scripts/write-secret.sh" ../keenable </dev/null >/dev/null 2>&1; then
  pass "0f: write-secret rejects blank keys and path-like names without changing the key"
else
  fail "0f: write-secret must reject blank keys and path-like names without changing the key"
fi
mkdir -p "${td_write_secret}/secrets/context7"
printf 'sentinel\n' > "${td_write_secret}/secrets/context7/keep"
if ! printf 'new-key\n' | OPENCODE_CONFIG_DIR="${td_write_secret}" "${BASELINE_PWD}/scripts/write-secret.sh" context7 >"${td_write_secret}/out" 2>"${td_write_secret}/err" \
  && grep -q 'Secret target is not a file' "${td_write_secret}/err" \
  && [[ ! -s "${td_write_secret}/out" && "$(ls -A "${td_write_secret}/secrets/context7")" == "keep" ]] \
  && [[ "$(ls -A "${td_write_secret}/secrets")" == $'context7\nkeenable' ]]; then
  pass "0f: write-secret rejects directory targets without false success or stray key files"
else
  fail "0f: write-secret must reject directory targets"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []
docs = ["README.md", "FOR-LLM-AGENTS.md", "profiles/optional/README.md", "profiles/agents/README.md"]
for name in docs:
    text = (root / name).read_text(encoding="utf-8")
    if re.search(r"read -r?s -p|umask 077", text):
        errors.append(f"{name} has a shell-specific inline secret writer; use scripts/write-secret.sh")
    if re.search(r"test -s [^\n]*secrets/", text):
        errors.append(f"{name} checks secrets with test -s; installers reject whitespace-only files")
readme = (root / "README.md").read_text(encoding="utf-8")
for secret in ("context7", "keenable"):
    if f"./scripts/write-secret.sh {secret}" not in readme:
        errors.append(f"README.md must show ./scripts/write-secret.sh {secret}")
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
PY
then
  pass "0f: docs write secrets with write-secret.sh and check presence the way installers do"
else
  fail "0f: docs write secrets with write-secret.sh and check presence the way installers do"
fi

td_ci_install="${TMPDIR}/test-context-improved-install"
if ! PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_ci_install}" OPENCODE_AGENTS_PROFILE=shared-context-improved bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${TMPDIR}/ci-install.err" \
  && grep -q "${td_ci_install}/secrets/context7" "${TMPDIR}/ci-install.err" \
  && opencode_target_unmodified "${td_ci_install}"; then
  pass "0f: context-improved install preflights secrets/context7 under OPENCODE_CONFIG_DIR before mutation"
else
  fail "0f: context-improved install must preflight secrets/context7 under OPENCODE_CONFIG_DIR before mutation"
fi
write_secret "${td_ci_install}" context7
if PATH="${optional_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td_ci_install}" OPENCODE_AGENTS_PROFILE=shared-context-improved bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${TMPDIR}/ci-install.err" \
  && [[ -f "${td_ci_install}/opencode.json" && "$(cat "${td_ci_install}/secrets/context7")" == "test-key" ]]; then
  pass "0f: context-improved install proceeds and preserves an existing secret file"
else
  fail "0f: context-improved install should proceed with a secret file: $(cat "${TMPDIR}/ci-install.err")"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []
payloads = sorted([root / "profiles/base/opencode.json", *(root / "profiles/optional").glob("opencode.*.json")])
for path in payloads:
    text = path.read_text(encoding="utf-8")
    if "{env:" in text:
        errors.append(f"{path.name} still reads an MCP credential from the environment")
    for ref in re.findall(r"\{file:([^}]+)\}", text):
        if not re.fullmatch(r"secrets/[a-z0-9-]+", ref):
            errors.append(f"{path.name} file reference must be secrets/<name> relative to the config dir: {ref}")
base = json.loads((root / "profiles/base/opencode.json").read_text(encoding="utf-8"))
if "{file:" in json.dumps(base):
    errors.append("base opencode.json must not reference secret files; Opencode fails startup when one is missing")
chrome = json.loads((root / "profiles/optional/opencode.chrome-devtools.json").read_text(encoding="utf-8"))
command = chrome["mcp"]["chrome-devtools"]["command"]
if command != ["npx", "-y", "chrome-devtools-mcp@latest", "--isolated=true", "--category-extensions=true"]:
    errors.append(f"chrome-devtools command={command!r}")
optional = {path.name for path in (root / "profiles/optional").glob("opencode.*.json")}
for blocked in ("railway", "atlassian"):
    if any(blocked in name for name in optional):
        errors.append(f"optional bundles must not include {blocked}")
gitignore = (root / ".gitignore").read_text(encoding="utf-8").splitlines()
if "secrets/" not in gitignore:
    errors.append(".gitignore must ignore secrets/")
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
PY
then
  pass "0f: MCP payloads use relative secret files, Chrome DevTools isolation flags, and no bundled secrets"
else
  fail "0f: MCP payloads use relative secret files, Chrome DevTools isolation flags, and no bundled secrets"
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
sandbox_agents_skills
cp -a "${BASELINE_PWD}/profiles/personal/skills/ivan-writing/." "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/"
CURSOR_CONFIG_DIR="${td3}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td3}/install.log" && pass "3a: opt-in install succeeded" || fail "3b: opt-in install failed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] && pass "3c: ivan-writing SKILL.md" || fail "3d: ivan-writing SKILL.md not found"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/references/registers.md" ]] && pass "3e: registers.md" || fail "3f: registers.md not found"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/references/examples.md" ]] && pass "3g: examples.md" || fail "3h: examples.md not found"
diff -r --exclude=.cursor-managed "${BASELINE_PWD}/profiles/personal/skills/ivan-writing" "${AGENTS_SKILLS_DIR}/ivan-writing" >/dev/null && pass "3: Cursor installs the complete personal source tree" || fail "3: Cursor personal skill differs from source"
[[ ! -e "${td3}/skills/ivan-writing" ]] && pass "3c2: ivan-writing absent from Cursor skills" || fail "3d2: ivan-writing leaked into Cursor skills"
[[ ! -e "${AGENTS_SKILLS_DIR}/stop-design-slop" ]] && pass "3y0: stop-design-slop absent from agents dir" || fail "3z0: stop-design-slop installed into agents dir"
for hive_bundled in ${HIVE_BUNDLED_NAMES}; do
  mkdir -p "${AGENTS_SKILLS_DIR}/${hive_bundled}"
  printf 'stale agents %s\n' "${hive_bundled}" > "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md"
done
hw3_status=0
CURSOR_CONFIG_DIR="${td3}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td3}/install-hive-writing.log" || hw3_status=$?
[[ "${hw3_status}" -eq 1 ]] && pass "3hw-a: reinstall with stale Hive-bundled skills exits 1 after install" || fail "3hw-b: reinstall with stale Hive-bundled skills exited ${hw3_status}: $(cat "${td3}/install-hive-writing.log")"
[[ -f "${td3}/skills/stop-slop/SKILL.md" ]] && pass "3i2: stop-slop installed into Cursor skills" || fail "3j2: stop-slop missing from Cursor skills"
[[ -f "${td3}/skills/stop-slop/references/examples.md" && -f "${td3}/skills/stop-slop/references/phrases.md" && -f "${td3}/skills/stop-slop/references/structures.md" ]] && pass "3i3: stop-slop references installed" || fail "3j3: stop-slop references missing"
[[ -f "${td3}/skills/humanizer/SKILL.md" && -f "${td3}/skills/humanizer/references/patterns.md" ]] && pass "3k2: humanizer and patterns installed into Cursor skills" || fail "3l2: humanizer Cursor copy incomplete"
[[ -f "${td3}/skills/writing-for-humans/SKILL.md" && -f "${td3}/skills/writing-for-humans/references/sources.md" && -f "${td3}/skills/writing-for-humans/references/examples.md" ]] && pass "3ae: writing-for-humans Cursor copy includes references" || fail "3af: writing-for-humans Cursor copy incomplete"
[[ -f "${td3}/skills/unslop/SKILL.md" && -f "${td3}/skills/writing-for-agents/SKILL.md" ]] && pass "3ag2: unslop and writing-for-agents installed into Cursor skills" || fail "3ah2: unslop or writing-for-agents missing from Cursor skills"
[[ ! -e "${td3}/skills/${HIVE_RETIRED_NAME}" ]] && pass "3ai2: retired ${HIVE_RETIRED_NAME} is not installed" || fail "3aj2: retired ${HIVE_RETIRED_NAME} was installed"
for hive_bundled in ${HIVE_BUNDLED_NAMES}; do
  if grep -Fqx "stale agents ${hive_bundled}" "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md" \
    && grep -Fqx "decision needed: conflict: ${AGENTS_SKILLS_DIR}/${hive_bundled} is outside the managed install path ${td3}/skills/${hive_bundled}; left in place" "${td3}/install-hive-writing.log" \
    && ! ls "${td3}/.backup/"*/agents-skills/"${hive_bundled}" >/dev/null 2>&1; then
    pass "3hw: ${hive_bundled} agents-dir copy left in place for a decision"
  else
    fail "3hw: ${hive_bundled} agents-dir copy was removed, backed up, or not reported"
  fi
done
retired_td3="${TMPDIR}/test3-retired"; mkdir -p "${retired_td3}/skills/${HIVE_RETIRED_NAME}"
mkdir -p "${AGENTS_SKILLS_DIR}/${HIVE_RETIRED_NAME}"
printf 'keep agents\n' > "${AGENTS_SKILLS_DIR}/${HIVE_RETIRED_NAME}/SKILL.md"
printf 'keep cursor\n' > "${retired_td3}/skills/${HIVE_RETIRED_NAME}/SKILL.md"
retired3_status=0
CURSOR_CONFIG_DIR="${retired_td3}" bash "${CURSOR_HELPER}" install 2>"${retired_td3}/err" >/dev/null || retired3_status=$?
if [[ "${retired3_status}" -eq 1 ]] \
  && grep -Fqx 'keep agents' "${AGENTS_SKILLS_DIR}/${HIVE_RETIRED_NAME}/SKILL.md" \
  && grep -Fqx 'keep cursor' "${retired_td3}/skills/${HIVE_RETIRED_NAME}/SKILL.md" \
  && grep -Fqx "decision needed: unversioned: ${AGENTS_SKILLS_DIR}/${HIVE_RETIRED_NAME} is not packaged by this install; left in place" "${retired_td3}/err" \
  && grep -Fqx "decision needed: unversioned: ${retired_td3}/skills/${HIVE_RETIRED_NAME} is not packaged by this install; left in place" "${retired_td3}/err" \
  && ! ls "${retired_td3}/.backup/"*/skills/"${HIVE_RETIRED_NAME}" >/dev/null 2>&1; then
  pass "3hr: retired ${HIVE_RETIRED_NAME} is preserved and reported as unversioned in both locations"
else
  fail "3hr: retired ${HIVE_RETIRED_NAME} was removed, backed up, or not reported: $(cat "${retired_td3}/err")"
fi
rm -rf "${AGENTS_SKILLS_DIR:?}/${HIVE_RETIRED_NAME}"
[[ -f "${AGENTS_SKILLS_DIR}/frontend-slides/SKILL.md" ]] && pass "3o: frontend-slides installed" || fail "3p: frontend-slides canonical skill not installed"
[[ -f "${AGENTS_SKILLS_DIR}/frontend-slides/viewport-base.css" ]] && pass "3q: frontend-slides viewport-base.css" || fail "3r: frontend-slides extra file not copied"
[[ -f "${AGENTS_SKILLS_DIR}/frontend-slides/scripts/build-standalone.py" ]] && pass "3ao: frontend-slides build-standalone.py" || fail "3ap: frontend-slides build-standalone.py not copied"
[[ -f "${AGENTS_SKILLS_DIR}/drawio-skill/SKILL.md" ]] && pass "3s: drawio-skill installed" || fail "3t: drawio-skill canonical skill not installed"
[[ -f "${AGENTS_SKILLS_DIR}/drawio-skill/bin/run" ]] && pass "3u: drawio-skill bin/run" || fail "3v: drawio-skill extra file not copied"
[[ -f "${AGENTS_SKILLS_DIR}/drawio-skill/data/shape-index.json.gz" ]] && pass "3w: drawio-skill gzip index" || fail "3x: drawio-skill gzip index not copied"
diff -r "${REPO_FIXTURE}/.apm/skills/ui-mockups" "${AGENTS_SKILLS_DIR}/ui-mockups" >/dev/null && [[ -f "${AGENTS_SKILLS_DIR}/ui-mockups/references/storyboards.md" && -f "${AGENTS_SKILLS_DIR}/ui-mockups/scripts/compose_storyboard.py" && ! -e "${td3}/skills/ui-mockups" ]] && pass "3ar: ui-mockups complete tree installed once into agents dir, not Cursor skills" || fail "3as: ui-mockups tree incomplete or misplaced by Cursor install"
diff -r "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop" "${td3}/skills/stop-design-slop" >/dev/null && [[ -f "${td3}/skills/stop-design-slop/references/review-rubric.md" && -f "${td3}/skills/stop-design-slop/scripts/contrast_check.py" && -f "${td3}/skills/stop-design-slop/assets/salience-hierarchy.svg" && -f "${td3}/skills/stop-design-slop/examples/README.md" ]] && pass "3y: stop-design-slop complete tree installed into Cursor skills" || fail "3z: stop-design-slop Cursor copy incomplete"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]] && pass "3m: marker inside ivan-writing" || fail "3n: marker not inside ivan-writing"
[[ -f "${td3}/skills/agents-md-mastery/SKILL.md" ]] && pass "3ak: Cursor-specific skill still in Cursor skills" || fail "3al: Cursor-specific skill missing from Cursor skills"
cmp -s "${REPO_FIXTURE}/.apm/prompts/reflect.prompt.md" "${td3}/commands/reflect.md" && pass "3ag: canonical reflect content installed byte-for-byte" || fail "3ah: canonical reflect content changed during Cursor install"
cmp -s "${REPO_FIXTURE}/.apm/cursor/skills/agents-md-mastery/SKILL.md" "${td3}/skills/agents-md-mastery/SKILL.md" && pass "3ai: Cursor agents-md-mastery installed byte-for-byte" || fail "3aj: Cursor agents-md-mastery content changed during install"

# ---------------------------------------------------------------------------
# 4. Opt-out leaves managed ivan-writing for a decision
# ---------------------------------------------------------------------------
printf '\n=== 4. Opt-out leaves managed ivan-writing for a decision ===\n'
td4="${TMPDIR}/test4"; mkdir -p "${td4}"
build_fixture
sandbox_agents_skills
CURSOR_CONFIG_DIR="${td4}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td4}/install.log" || fail "4a: install failed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] || fail "4b: pre-check failed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]] || fail "4c: installer did not create marker"
optout4_status=0
CURSOR_CONFIG_DIR="${td4}" bash "${CURSOR_HELPER}" install 2>"${td4}/optout.log" || optout4_status=$?
[[ "${optout4_status}" -eq 1 ]] && pass "4d: opt-out exits 1 after install" || fail "4d: opt-out exited ${optout4_status}: $(cat "${td4}/optout.log")"
[[ -d "${AGENTS_SKILLS_DIR}/ivan-writing" && -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]] && pass "4e: opt-out left managed ivan-writing in place" || fail "4f: opt-out removed ivan-writing"
grep -Fqx "decision needed: unversioned: ${AGENTS_SKILLS_DIR}/ivan-writing is not packaged by this install; left in place" "${td4}/optout.log" && pass "4g: opt-out reports unversioned ivan-writing" || fail "4h: opt-out decision line missing: $(cat "${td4}/optout.log")"
if ls "${td4}/.backup/"*"/agents-skills/ivan-writing" >/dev/null 2>&1; then
  fail "4i: opt-out backed up ivan-writing"
else
  pass "4j: opt-out did not back up ivan-writing"
fi

# ---------------------------------------------------------------------------
# 5. Unowned existing ivan-writing preserved on opt-out (no marker)
# ---------------------------------------------------------------------------
printf '\n=== 5. Unowned existing ivan-writing preserved ===\n'
td5="${TMPDIR}/test5"; mkdir -p "${td5}/skills/ivan-writing"
echo "user content" > "${td5}/skills/ivan-writing/user-file.txt"
build_fixture
sandbox_agents_skills
CURSOR_CONFIG_DIR="${td5}" bash "${CURSOR_HELPER}" install 2>"${td5}/optout.log" || fail "5a: install with unowned ivan-writing failed"
[[ -f "${td5}/skills/ivan-writing/user-file.txt" ]] && pass "5b: unowned preserved" || fail "5c: unowned removed"

# ---------------------------------------------------------------------------
# 5d. Opt-in leaves stale Cursor ivan-writing for a decision
# ---------------------------------------------------------------------------
printf '\n=== 5d. Opt-in leaves stale Cursor ivan-writing for a decision ===\n'
td5d="${TMPDIR}/test5d"; mkdir -p "${td5d}/skills/ivan-writing"
echo "stale ivan-writing" > "${td5d}/skills/ivan-writing/SKILL.md"
build_fixture
sandbox_agents_skills
dry5d_status=0
CURSOR_CONFIG_DIR="${td5d}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install --dry-run >"${td5d}/dry.log" 2>&1 || dry5d_status=$?
[[ "${dry5d_status}" -eq 1 ]] && pass "5d-a: opt-in dry-run exits 1" || fail "5d-b: opt-in dry-run exited ${dry5d_status}"
grep -F "decision needed: conflict: ${td5d}/skills/ivan-writing is outside the managed install path ${AGENTS_SKILLS_DIR}/ivan-writing; left in place" "${td5d}/dry.log" >/dev/null && pass "5d-c: dry-run reports Cursor ivan-writing conflict" || fail "5d-d: dry-run omitted Cursor ivan-writing conflict: $(cat "${td5d}/dry.log")"
[[ -f "${td5d}/skills/ivan-writing/SKILL.md" ]] && pass "5d-c2: dry-run left Cursor ivan-writing in place" || fail "5d-d2: dry-run changed Cursor ivan-writing"
install5d_status=0
CURSOR_CONFIG_DIR="${td5d}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td5d}/install.log" || install5d_status=$?
[[ "${install5d_status}" -eq 1 ]] && pass "5d-e: opt-in install exits 1 after install" || fail "5d-f: opt-in install exited ${install5d_status}: $(cat "${td5d}/install.log")"
grep -Fqx "stale ivan-writing" "${td5d}/skills/ivan-writing/SKILL.md" && pass "5d-g: stale Cursor ivan-writing left in place" || fail "5d-h: stale Cursor ivan-writing was removed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] && pass "5d-i: ivan-writing installed to agents dir" || fail "5d-j: ivan-writing missing from agents dir"
grep -F "decision needed: conflict: ${td5d}/skills/ivan-writing is outside the managed install path ${AGENTS_SKILLS_DIR}/ivan-writing; left in place" "${td5d}/install.log" >/dev/null && pass "5d-k: install reports Cursor ivan-writing conflict" || fail "5d-l: install omitted Cursor ivan-writing conflict"
if ls "${td5d}/.backup/"*"/skills/ivan-writing" >/dev/null 2>&1; then
  fail "5d-m: Cursor ivan-writing was backed up"
else
  pass "5d-n: Cursor ivan-writing was not backed up"
fi

# ---------------------------------------------------------------------------
# 5e. Opt-out leaves Cursor ivan-writing with .cursor-managed for a decision
# ---------------------------------------------------------------------------
printf '\n=== 5e. Opt-out leaves Cursor ivan-writing with .cursor-managed for a decision ===\n'
td5e="${TMPDIR}/test5e"; mkdir -p "${td5e}/skills/ivan-writing"
echo "legacy cursor copy" > "${td5e}/skills/ivan-writing/SKILL.md"
touch "${td5e}/skills/ivan-writing/.cursor-managed"
build_fixture
sandbox_agents_skills
dry5e_status=0
CURSOR_CONFIG_DIR="${td5e}" bash "${CURSOR_HELPER}" install --dry-run >"${td5e}/dry.log" 2>&1 || dry5e_status=$?
[[ "${dry5e_status}" -eq 1 ]] && pass "5e-a: opt-out dry-run exits 1" || fail "5e-b: opt-out dry-run exited ${dry5e_status}"
grep -F "decision needed: unversioned: ${td5e}/skills/ivan-writing is not packaged by this install; left in place" "${td5e}/dry.log" >/dev/null && pass "5e-c: dry-run reports unversioned Cursor ivan-writing" || fail "5e-d: dry-run omitted unversioned Cursor ivan-writing: $(cat "${td5e}/dry.log")"
install5e_status=0
CURSOR_CONFIG_DIR="${td5e}" bash "${CURSOR_HELPER}" install 2>"${td5e}/optout.log" || install5e_status=$?
[[ "${install5e_status}" -eq 1 ]] && pass "5e-e: opt-out install exits 1 after install" || fail "5e-f: opt-out install exited ${install5e_status}: $(cat "${td5e}/optout.log")"
grep -Fqx "legacy cursor copy" "${td5e}/skills/ivan-writing/SKILL.md" && [[ -f "${td5e}/skills/ivan-writing/.cursor-managed" ]] && pass "5e-g: managed Cursor ivan-writing left in place" || fail "5e-h: managed Cursor ivan-writing was removed"
[[ ! -e "${AGENTS_SKILLS_DIR}/ivan-writing" ]] && pass "5e-i: agents-dir ivan-writing not created on opt-out" || fail "5e-j: agents-dir ivan-writing appeared on opt-out"
grep -F "decision needed: unversioned: ${td5e}/skills/ivan-writing is not packaged by this install; left in place" "${td5e}/optout.log" >/dev/null && pass "5e-k: install reports unversioned Cursor ivan-writing" || fail "5e-l: install omitted unversioned Cursor ivan-writing"
if ls "${td5e}/.backup/"*"/skills/ivan-writing" >/dev/null 2>&1; then
  fail "5e-m: Cursor ivan-writing was backed up"
else
  pass "5e-n: Cursor ivan-writing was not backed up"
fi

# ---------------------------------------------------------------------------
# 6. Missing canonical source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 6. Missing canonical source fails before mutation ===\n'
td6="${TMPDIR}/test6"; mkdir -p "${td6}"
rm -rf "${REPO_FIXTURE}/.apm/cursor/skills/humanizer"
! CURSOR_CONFIG_DIR="${td6}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td6}/err" || fail "6a: should have failed"
grep -q 'validation failed.*skills/humanizer' "${td6}/err" && pass "6b: missing Cursor humanizer detected" || fail "6c: wrong error: $(cat ${td6}/err)"
cursor_target_unmodified "${td6}" && pass "6d: no managed paths created" || fail "6e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 7. Wrong-name canonical source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 7. Wrong-name canonical source fails before mutation ===\n'
td7="${TMPDIR}/test7"; mkdir -p "${td7}"
SKILL_FILE="${REPO_FIXTURE}/.apm/cursor/skills/humanizer/SKILL.md"
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
! OPENCODE_CONFIG_DIR="${td11}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" --apply 2>"${td11}/err" || fail "11a: should have failed"
grep -q 'ERROR' "${td11}/err" && pass "11b: personal preflight detected" || fail "11c: wrong error: $(cat ${td11}/err)"
opencode_target_unmodified "${td11}" && pass "11d: no managed paths created" || fail "11e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 12. Shared install independent of personal source
# ---------------------------------------------------------------------------
printf '\n=== 12. Shared install independent of personal source ===\n'
td12="${TMPDIR}/test12"; mkdir -p "${td12}"
sandbox_agents_skills
rm -rf "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing"
OPENCODE_CONFIG_DIR="${td12}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td12}/err" && pass "12a: shared install succeeded" || fail "12b: shared install failed"
cmp -s "${REPO_FIXTURE}/profiles/base/opencode.json" "${td12}/opencode.json" && pass "12c: base opencode payload installed" || fail "12d: installed opencode payload did not come from profiles/base"
cmp -s "${REPO_FIXTURE}/profiles/base/agent_hive.json" "${td12}/agent_hive.json" && pass "12e: base Agent Hive payload installed" || fail "12f: installed Agent Hive payload did not come from profiles/base"
[[ -f "${AGENTS_SKILLS_DIR}/frontend-slides/SKILL.md" ]] && pass "12g: shared frontend-slides installed" || fail "12h: shared frontend-slides missing"
[[ ! -e "${td12}/skills/frontend-slides" ]] && pass "12g2: frontend-slides absent from OpenCode skills" || fail "12h2: frontend-slides leaked into OpenCode skills"
[[ -f "${AGENTS_SKILLS_DIR}/drawio-skill/SKILL.md" ]] && pass "12i: shared drawio-skill installed" || fail "12j: shared drawio-skill missing"
diff -r "${REPO_FIXTURE}/.apm/skills/ui-mockups" "${AGENTS_SKILLS_DIR}/ui-mockups" >/dev/null && [[ ! -e "${td12}/skills/ui-mockups" ]] && pass "12i2: shared ui-mockups tree installed once into agents dir, not OpenCode skills" || fail "12j2: ui-mockups tree incomplete or misplaced by OpenCode install"
for hive_bundled in ${OPENCODE_HIVE_BUNDLED_NAMES}; do
  [[ ! -e "${AGENTS_SKILLS_DIR}/${hive_bundled}" && ! -e "${td12}/skills/${hive_bundled}" ]] && pass "12m0: ${hive_bundled} not created by OpenCode install" || fail "12n0: ${hive_bundled} was created by OpenCode install"
done
for hive_bundled in ${OPENCODE_HIVE_BUNDLED_NAMES}; do
  mkdir -p "${AGENTS_SKILLS_DIR}/${hive_bundled}" "${td12}/skills/${hive_bundled}"
  printf 'stale agents %s\n' "${hive_bundled}" > "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md"
  printf 'stale opencode %s\n' "${hive_bundled}" > "${td12}/skills/${hive_bundled}/SKILL.md"
done
hive12_status=0
OPENCODE_CONFIG_DIR="${td12}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td12}/hive-writing.err" || hive12_status=$?
[[ "${hive12_status}" -eq 1 ]] && pass "12m: reinstall exits 1 after leaving Hive-bundled leftovers" || fail "12n: reinstall with Hive-bundled leftovers exited ${hive12_status}: $(cat "${td12}/hive-writing.err")"
for hive_bundled in ${OPENCODE_HIVE_BUNDLED_NAMES}; do
  if grep -Fqx "stale agents ${hive_bundled}" "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md" \
    && grep -Fqx "stale opencode ${hive_bundled}" "${td12}/skills/${hive_bundled}/SKILL.md" \
    && grep -Fqx "decision needed: conflict: ${AGENTS_SKILLS_DIR}/${hive_bundled} is outside the managed install path Hive materialization; left in place" "${td12}/hive-writing.err" \
    && grep -Fqx "decision needed: conflict: ${td12}/skills/${hive_bundled} is outside the managed install path Hive materialization; left in place" "${td12}/hive-writing.err" \
    && ! ls "${td12}/.backup/"*/agents-skills/"${hive_bundled}" >/dev/null 2>&1; then
    pass "12o: ${hive_bundled} left in agents dir and OpenCode skills for a decision"
  else
    fail "12p: ${hive_bundled} was removed, backed up, or not reported"
  fi
done
[[ -f "${AGENTS_SKILLS_DIR}/writing-work-items/SKILL.md" && -f "${AGENTS_SKILLS_DIR}/decomposing-work/SKILL.md" && -f "${AGENTS_SKILLS_DIR}/running-agile-delivery/SKILL.md" ]] && pass "12q2: other shared skills remain in agents dir" || fail "12r2: a remaining shared skill is missing from agents dir"
[[ -f "${td12}/skills/writing-skills/SKILL.md" ]] && pass "12w: OpenCode-local writing-skills installed" || fail "12x: OpenCode-local writing-skills missing"
retired12=""
for skill12 in using-git-worktrees finishing-a-development-branch consolidate-test-suites root-cause-finder context-mode; do
  if [[ -e "${td12}/skills/${skill12}" ]]; then
    retired12="${retired12} ${skill12}"
  fi
done
[[ -z "${retired12}" ]] && pass "12y: retired OpenCode workflow skills are not installed" || fail "12z: retired OpenCode workflow skills still installed:${retired12}"
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
if ! OPENCODE_CONFIG_DIR="${td12b}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td12b}/err"; then
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
if ! OPENCODE_CONFIG_DIR="${td12c}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td12c}/err"; then
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
sandbox_agents_skills
before13="$(snapshot_tree "${td13}")"
CURSOR_CONFIG_DIR="${td13}" bash "${CURSOR_HELPER}" install --dry-run >"${TMPDIR}/test13-dryrun.log" 2>&1 && pass "13a: dry-run succeeded" || fail "13b: dry-run failed"
after13="$(snapshot_tree "${td13}")"
[[ "${before13}" == "${after13}" ]] && pass "13c: dry-run target tree unchanged" || fail "13d: dry-run mutated target tree"
grep -q 'canonical .apm/skills/frontend-slides' "${TMPDIR}/test13-dryrun.log" && pass "13e: dry-run plans frontend-slides" || fail "13f: dry-run omitted frontend-slides"
grep -q 'canonical .apm/skills/drawio-skill' "${TMPDIR}/test13-dryrun.log" && pass "13g: dry-run plans drawio-skill" || fail "13h: dry-run omitted drawio-skill"
grep -Fq "Would copy skills/stop-design-slop -> ${td13}/skills/stop-design-slop" "${TMPDIR}/test13-dryrun.log" && ! grep -q 'canonical .apm/skills/stop-design-slop' "${TMPDIR}/test13-dryrun.log" && pass "13i: dry-run plans stop-design-slop for Cursor skills only" || fail "13j: dry-run plan for stop-design-slop is not Cursor-only"
grep -q 'skills/writing-for-humans' "${TMPDIR}/test13-dryrun.log" && pass "13k: dry-run plans Cursor writing-for-humans" || fail "13l: dry-run omitted Cursor writing-for-humans"
grep -q "${AGENTS_SKILLS_DIR}/frontend-slides" "${TMPDIR}/test13-dryrun.log" && pass "13q: dry-run destinations use agents dir" || fail "13r: dry-run omitted agents-dir destination"
if grep -q 'canonical .apm/skills/writing-for-humans' "${TMPDIR}/test13-dryrun.log"; then
  fail "13k2: dry-run still plans writing-for-humans as a shared canonical skill"
else
  pass "13l2: dry-run does not plan writing-for-humans as a shared canonical skill"
fi
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
sandbox_agents_skills
CURSOR_CONFIG_DIRS="${td15a};${td15b}" bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/multi.log" && pass "15a: multi-root succeeded" || fail "15b: multi-root failed"
[[ ! -e "${AGENTS_SKILLS_DIR}/stop-slop" ]] && pass "15c: stop-slop absent from agents dir" || fail "15d: stop-slop installed into agents dir"
[[ -f "${td15a}/skills/stop-slop/SKILL.md" && -f "${td15b}/skills/stop-slop/SKILL.md" && -f "${td15a}/skills/stop-slop/references/examples.md" && -f "${td15b}/skills/stop-slop/references/phrases.md" ]] && pass "15e: stop-slop installed into both Cursor targets" || fail "15f: stop-slop missing from a Cursor target"
[[ -f "${AGENTS_SKILLS_DIR}/frontend-slides/SKILL.md" ]] && pass "15k: shared frontend-slides in agents dir" || fail "15l: multi-root missing frontend-slides"
[[ -f "${AGENTS_SKILLS_DIR}/drawio-skill/SKILL.md" ]] && pass "15m: shared drawio-skill in agents dir" || fail "15n: multi-root missing drawio-skill"
diff -r "${REPO_FIXTURE}/.apm/skills/ui-mockups" "${AGENTS_SKILLS_DIR}/ui-mockups" >/dev/null && [[ ! -e "${td15a}/skills/ui-mockups" && ! -e "${td15b}/skills/ui-mockups" ]] && pass "15m2: multi-root ui-mockups tree in agents dir only, not either Cursor target" || fail "15n2: multi-root ui-mockups tree incomplete or misplaced"
[[ ! -e "${AGENTS_SKILLS_DIR}/stop-design-slop" ]] && diff -r "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop" "${td15a}/skills/stop-design-slop" >/dev/null && diff -r "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop" "${td15b}/skills/stop-design-slop" >/dev/null && pass "15o: stop-design-slop installed in full into both Cursor targets, not the agents dir" || fail "15p: multi-root stop-design-slop placement wrong"
[[ ! -e "${AGENTS_SKILLS_DIR}/writing-for-humans" && -f "${td15a}/skills/writing-for-humans/references/sources.md" && -f "${td15b}/skills/writing-for-humans/references/sources.md" ]] && pass "15q: writing-for-humans installed only into Cursor targets" || fail "15r: multi-root writing-for-humans placement wrong"
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
# 16. Opt-in multi-root copies ivan-writing to the agents dir once
# ---------------------------------------------------------------------------
printf '\n=== 16. Opt-in multi-root install ===\n'
td16a="${TMPDIR}/test16a"; td16b="${TMPDIR}/test16b"
mkdir -p "${td16a}" "${td16b}"
build_fixture
sandbox_agents_skills
CURSOR_CONFIG_DIRS="${td16a};${td16b}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${TMPDIR}/multi-optin.log" && pass "16a: opt-in multi-root succeeded" || fail "16b: opt-in multi-root failed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] && pass "16c: ivan-writing in agents dir" || fail "16d: ivan-writing missing from agents dir"
[[ ! -e "${td16a}/skills/ivan-writing" && ! -e "${td16b}/skills/ivan-writing" ]] && pass "16e: ivan-writing absent from both Cursor targets" || fail "16f: ivan-writing leaked into a Cursor target"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/.cursor-managed" ]] && pass "16g: agents-dir marker" || fail "16h: agents-dir marker missing"

# ---------------------------------------------------------------------------
# 17. Stale-marker: deleted managed dir then recreate, opt-out preserves
# ---------------------------------------------------------------------------
printf '\n=== 17. Deleted managed dir recreated by user, opt-out preserves ===\n'
td17="${TMPDIR}/test17"; mkdir -p "${td17}"
build_fixture
sandbox_agents_skills
CURSOR_CONFIG_DIR="${td17}" CURSOR_INSTALL_IVAN_WRITING=1 bash "${CURSOR_HELPER}" install 2>"${td17}/log1" || fail "17a: install failed"
rm -r "${AGENTS_SKILLS_DIR}/ivan-writing"
mkdir -p "${AGENTS_SKILLS_DIR}/ivan-writing"
echo "user file" > "${AGENTS_SKILLS_DIR}/ivan-writing/user.txt"
CURSOR_CONFIG_DIR="${td17}" bash "${CURSOR_HELPER}" install 2>"${td17}/log2" || fail "17b: opt-out failed"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/user.txt" ]] && pass "17c: user-owned recreated dir preserved" || fail "17d: user dir removed despite missing marker"

# ---------------------------------------------------------------------------
# 17b. Stale Cursor shared skill is left for a decision
# ---------------------------------------------------------------------------
printf '\n=== 17b. Stale Cursor shared skill is left for a decision ===\n'
td17b="${TMPDIR}/test17b"; mkdir -p "${td17b}/skills/stop-slop" "${td17b}/skills/stop-design-slop" "${td17b}/skills/hard-cut"
echo "stale stop-slop" > "${td17b}/skills/stop-slop/SKILL.md"
echo "stale cursor stop-design-slop" > "${td17b}/skills/stop-design-slop/SKILL.md"
echo "stale hard-cut" > "${td17b}/skills/hard-cut/SKILL.md"
build_fixture
sandbox_agents_skills
mkdir -p "${AGENTS_SKILLS_DIR}/stop-slop"
echo "stale agents stop-slop" > "${AGENTS_SKILLS_DIR}/stop-slop/SKILL.md"
mkdir -p "${AGENTS_SKILLS_DIR}/stop-design-slop"
echo "stale agents stop-design-slop" > "${AGENTS_SKILLS_DIR}/stop-design-slop/SKILL.md"
install17b_status=0
CURSOR_CONFIG_DIR="${td17b}" bash "${CURSOR_HELPER}" install 2>"${td17b}/install.log" || install17b_status=$?
[[ "${install17b_status}" -eq 1 ]] && pass "17b-a: install exits 1 after reporting decisions" || fail "17b-b: install exited ${install17b_status}: $(cat "${td17b}/install.log")"
grep -Fqx 'OK' "${td17b}/skills/stop-slop/SKILL.md" && [[ -f "${td17b}/skills/stop-slop/references/structures.md" ]] && pass "17b-c: stop-slop replaced in Cursor skills" || fail "17b-d: stale stop-slop was not replaced"
grep -Fqx "stale hard-cut" "${td17b}/skills/hard-cut/SKILL.md" && pass "17b-e: stale hard-cut left in Cursor skills" || fail "17b-f: stale hard-cut was removed"
grep -Fqx "stale agents stop-slop" "${AGENTS_SKILLS_DIR}/stop-slop/SKILL.md" && pass "17b-g: stop-slop left in agents dir" || fail "17b-h: stop-slop was removed from agents dir"
[[ -f "${AGENTS_SKILLS_DIR}/hard-cut/SKILL.md" ]] && pass "17b-i: hard-cut installed to agents dir" || fail "17b-j: hard-cut missing from agents dir"
grep -Fqx "decision needed: conflict: ${td17b}/skills/hard-cut is outside the managed install path ${AGENTS_SKILLS_DIR}/hard-cut; left in place" "${td17b}/install.log" && pass "17b-k: hard-cut conflict reported" || fail "17b-l: hard-cut conflict missing"
grep -Fqx "decision needed: conflict: ${AGENTS_SKILLS_DIR}/stop-slop is outside the managed install path ${td17b}/skills/stop-slop; left in place" "${td17b}/install.log" && pass "17b-m: agents stop-slop conflict reported" || fail "17b-n: agents stop-slop conflict missing"
diff -r "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop" "${td17b}/skills/stop-design-slop" >/dev/null && ! grep -Fq "${td17b}/skills/stop-design-slop is outside" "${td17b}/install.log" && pass "17b-o: Cursor stop-design-slop replaced as the managed destination, not reported" || fail "17b-p: stale Cursor stop-design-slop was kept or reported as a conflict"
grep -Fqx "stale agents stop-design-slop" "${AGENTS_SKILLS_DIR}/stop-design-slop/SKILL.md" && grep -Fqx "decision needed: conflict: ${AGENTS_SKILLS_DIR}/stop-design-slop is outside the managed install path ${td17b}/skills/stop-design-slop; left in place" "${td17b}/install.log" && pass "17b-q: stale agents stop-design-slop left in place and reported" || fail "17b-r: stale agents stop-design-slop removed or not reported"

# ---------------------------------------------------------------------------
# 17c. Personal OpenCode profile installs ivan-writing into the agents dir
# ---------------------------------------------------------------------------
printf '\n=== 17c. Personal OpenCode ivan-writing goes to agents dir ===\n'
td17c="${TMPDIR}/test17c"; mkdir -p "${td17c}"
build_fixture
sandbox_agents_skills
cp -a "${BASELINE_PWD}/profiles/personal/skills/ivan-writing/." "${REPO_FIXTURE}/profiles/personal/skills/ivan-writing/"
cp "${BASELINE_PWD}/profiles/agents/personal-default.md" "${REPO_FIXTURE}/profiles/agents/personal-default.md"
OPENCODE_CONFIG_DIR="${td17c}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" --apply 2>"${td17c}/err" && pass "17c-a: personal install succeeded" || fail "17c-b: personal install failed: $(cat "${td17c}/err")"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] && pass "17c-c: ivan-writing in agents dir" || fail "17c-d: ivan-writing missing from agents dir"
[[ ! -e "${td17c}/skills/ivan-writing" ]] && pass "17c-e: ivan-writing absent from OpenCode skills" || fail "17c-f: ivan-writing leaked into OpenCode skills"
diff -r "${BASELINE_PWD}/profiles/personal/skills/ivan-writing" "${AGENTS_SKILLS_DIR}/ivan-writing" >/dev/null && cmp -s "${BASELINE_PWD}/profiles/agents/personal-default.md" "${td17c}/AGENTS.md" && pass "17c: OpenCode installs the personal source tree and loading guidance" || fail "17c: installed personal source tree or loading guidance differs"

printf '\n=== 17c. OpenCode backs up dangling canonical and personal skills ===\n'
for profile17c in shared personal-default; do
  td17c_link="${TMPDIR}/test17c-${profile17c}"
  mkdir -p "${td17c_link}"
  sandbox_agents_skills
  if [[ "${profile17c}" == shared ]]; then skill17c=cymbal; else skill17c=ivan-writing; fi
  ln -s "${td17c_link}/missing-skill" "${AGENTS_SKILLS_DIR}/${skill17c}"
  if OPENCODE_CONFIG_DIR="${td17c_link}" OPENCODE_AGENTS_PROFILE="${profile17c}" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${td17c_link}/err"; then
    backups17c=("${td17c_link}"/.backup/*/agents-skills/"${skill17c}")
    [[ -L "${backups17c[0]}" && "$(readlink "${backups17c[0]}")" == "${td17c_link}/missing-skill" ]] \
      && pass "17c: ${profile17c} backs up dangling ${skill17c}" || fail "17c: ${profile17c} lost dangling ${skill17c} backup"
    [[ -f "${AGENTS_SKILLS_DIR}/${skill17c}/SKILL.md" ]] \
      && pass "17c: ${profile17c} replaces dangling ${skill17c}" || fail "17c: ${profile17c} did not replace dangling ${skill17c}"
  else
    fail "17c: ${profile17c} install failed: $(cat "${td17c_link}/err")"
  fi
done

# ---------------------------------------------------------------------------
# 17d. Installer aborts when AGENTS_SKILLS_DIR equals the harness skills dir
# ---------------------------------------------------------------------------
printf '\n=== 17d. AGENTS_SKILLS_DIR alias to harness skills/ aborts ===\n'
td17d="${TMPDIR}/test17d"; mkdir -p "${td17d}/skills"
echo "keep-opencode" > "${td17d}/skills/sentinel.txt"
build_fixture
AGENTS_SKILLS_DIR="${td17d}/skills"
export AGENTS_SKILLS_DIR
if ! OPENCODE_CONFIG_DIR="${td17d}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td17d}/err"; then
  grep -q 'AGENTS_SKILLS_DIR resolves to the same directory' "${td17d}/err" && pass "17d-a: OpenCode alias aborted" || fail "17d-b: wrong OpenCode alias error: $(cat "${td17d}/err")"
  [[ -f "${td17d}/skills/sentinel.txt" ]] && pass "17d-c: OpenCode skills sentinel preserved" || fail "17d-d: OpenCode skills dir mutated before alias abort"
  [[ ! -f "${td17d}/opencode.json" ]] && pass "17d-e: OpenCode target not installed after alias abort" || fail "17d-f: OpenCode install continued after alias abort"
else
  fail "17d-g: OpenCode install should have aborted when AGENTS_SKILLS_DIR equals skills/"
fi
sandbox_agents_skills

td17d_c="${TMPDIR}/test17d-cursor"; mkdir -p "${td17d_c}/skills/keep-me"
echo "keep-cursor" > "${td17d_c}/skills/keep-me/file.txt"
AGENTS_SKILLS_DIR="${td17d_c}/skills"
export AGENTS_SKILLS_DIR
if ! CURSOR_CONFIG_DIR="${td17d_c}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td17d_c}/err"; then
  grep -q 'AGENTS_SKILLS_DIR resolves to the same directory' "${td17d_c}/err" && pass "17d-h: Cursor alias aborted" || fail "17d-i: wrong Cursor alias error: $(cat "${td17d_c}/err")"
  [[ -f "${td17d_c}/skills/keep-me/file.txt" ]] && pass "17d-j: Cursor skills sentinel preserved" || fail "17d-k: Cursor skills dir mutated before alias abort"
else
  fail "17d-l: Cursor dry-run should have aborted when AGENTS_SKILLS_DIR equals skills/"
fi
sandbox_agents_skills

# ---------------------------------------------------------------------------
# 17e. Alias detection resolves symlinks and missing components without GNU realpath
# ---------------------------------------------------------------------------
printf '\n=== 17e. Portable alias detection without realpath ===\n'
if grep -nE '^[^#]*realpath' "${BASELINE_PWD}/scripts/install-profile.sh" "${BASELINE_PWD}/scripts/cursor-assets.sh" >"${TMPDIR}/test17e-matches"; then
  fail "17e-a: installers still call realpath: $(tr '\n' ' ' < "${TMPDIR}/test17e-matches")"
else
  pass "17e-a: installers do not depend on realpath"
fi
td17e="${TMPDIR}/test17e"
no_realpath_bin="${td17e}/bin"
mkdir -p "${td17e}/real" "${no_realpath_bin}"
ln -s "${td17e}/real" "${td17e}/link"
printf '#!/bin/sh\nexit 97\n' > "${no_realpath_bin}/realpath"
chmod +x "${no_realpath_bin}/realpath"
build_fixture
for alias17e in "${td17e}/link/skills" "${td17e}/missing/../real/skills" "/${td17e}/real/skills"; do
  if ! PATH="${no_realpath_bin}:${PATH}" AGENTS_SKILLS_DIR="${alias17e}" OPENCODE_CONFIG_DIR="${td17e}/real" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${td17e}/err" \
    && grep -q 'AGENTS_SKILLS_DIR resolves to the same directory' "${td17e}/err" && opencode_target_unmodified "${td17e}/real"; then
    pass "17e-b: OpenCode aborts aliased AGENTS_SKILLS_DIR ${alias17e#"${td17e}/"}"
  else
    fail "17e-b: OpenCode did not abort aliased AGENTS_SKILLS_DIR ${alias17e#"${td17e}/"}: $(cat "${td17e}/err")"
  fi
  if ! PATH="${no_realpath_bin}:${PATH}" AGENTS_SKILLS_DIR="${alias17e}" env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td17e}/real" bash "${CURSOR_HELPER}" install --dry-run >/dev/null 2>"${td17e}/err" \
    && grep -q 'AGENTS_SKILLS_DIR resolves to the same directory' "${td17e}/err"; then
    pass "17e-c: Cursor aborts aliased AGENTS_SKILLS_DIR ${alias17e#"${td17e}/"}"
  else
    fail "17e-c: Cursor did not abort aliased AGENTS_SKILLS_DIR ${alias17e#"${td17e}/"}: $(cat "${td17e}/err")"
  fi
done
sandbox_agents_skills
if PATH="${no_realpath_bin}:${PATH}" OPENCODE_CONFIG_DIR="${td17e}/link/opencode" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${td17e}/err" \
  && [[ -f "${td17e}/real/opencode/opencode.json" ]]; then
  pass "17e-d: non-aliased install succeeds without realpath"
else
  fail "17e-d: non-aliased install failed without realpath: $(cat "${td17e}/err")"
fi
grep -Fq "Warning: Agent Hive reads ${HOME}/.config/opencode/agent_hive.json regardless of OPENCODE_CONFIG_DIR" "${td17e}/err" \
  && pass "17e-e: custom config root warns that Agent Hive ignores its agent_hive.json" \
  || fail "17e-e: custom config root did not warn about Agent Hive config location"
mkdir -p "${td17e}/home/.config"
if HOME="${td17e}/home" OPENCODE_CONFIG_DIR="${td17e}/home/.config/../.config/opencode" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${td17e}/err" \
  && ! grep -q 'Agent Hive reads' "${td17e}/err"; then
  pass "17e-f: default config root does not warn about Agent Hive config location"
else
  fail "17e-f: default config root warned or failed: $(cat "${td17e}/err")"
fi
if HOME="${td17e}/home" OPENCODE_CONFIG_DIR="/${td17e}/home/.config/opencode" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${td17e}/err" \
  && ! grep -q 'Agent Hive reads' "${td17e}/err"; then
  pass "17e-g: double-leading-slash default config root does not warn"
else
  fail "17e-g: double-leading-slash default config root warned or failed: $(cat "${td17e}/err")"
fi

# ---------------------------------------------------------------------------
# 22. Unsupported extra file in canonical skill directory
# ---------------------------------------------------------------------------
printf '\n=== 22. Unsupported extra file in canonical skill directory ===\n'
td22="${TMPDIR}/test22"; mkdir -p "${td22}"
touch "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/extra.txt"
! CURSOR_CONFIG_DIR="${td22}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td22}/err" || fail "22a: should have failed"
grep -q -i 'extra\|unsupported' "${td22}/err" && pass "22b: extra file detected" || fail "22c: wrong error: $(cat ${td22}/err)"
cursor_target_unmodified "${td22}" && pass "22d: no managed paths created" || fail "22e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 23. Unsupported extra subdirectory in canonical skill
# ---------------------------------------------------------------------------
printf '\n=== 23. Unsupported extra subdirectory in canonical skill ===\n'
td23="${TMPDIR}/test23"; mkdir -p "${td23}"
mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop/unexpected"
! CURSOR_CONFIG_DIR="${td23}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td23}/err" || fail "23a: should have failed"
grep -q -i 'unexpected\|unsupported' "${td23}/err" && pass "23b: extra subdir detected" || fail "23c: wrong error: $(cat ${td23}/err)"
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
# 26. Nested unsupported file under references/ in stop-design-slop
# ---------------------------------------------------------------------------
printf '\n=== 26. Nested unsupported file under references/ (canonical, Cursor) ===\n'
td26="${TMPDIR}/test26"; mkdir -p "${td26}"
touch "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop/references/extra.txt"
! CURSOR_CONFIG_DIR="${td26}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td26}/err" || fail "26a: should have failed"
grep -q 'extra\|unsupported' "${td26}/err" && pass "26b: nested extra file rejected" || fail "26c: wrong error: $(cat ${td26}/err)"
cursor_target_unmodified "${td26}" && pass "26d: no managed paths created" || fail "26e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 27. Nested subdirectory under references/ in stop-design-slop
# ---------------------------------------------------------------------------
printf '\n=== 27. Nested subdirectory under references/ (canonical, Cursor) ===\n'
td27="${TMPDIR}/test27"; mkdir -p "${td27}"
mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop/references/subdir"
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
! OPENCODE_CONFIG_DIR="${td30}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" --apply 2>"${td30}/err" || fail "30a: should have failed"
grep -q 'subdir\|unsupported' "${td30}/err" && pass "30b: OpenCode personal nested subdir rejected" || fail "30c: wrong error: $(cat ${td30}/err)"
opencode_target_unmodified "${td30}" && pass "30d: no managed paths created" || fail "30e: target mutated"
build_fixture

# ---------------------------------------------------------------------------
# 31. Nested unsupported file under references/ in canonical stop-slop (OpenCode path)
# ---------------------------------------------------------------------------
printf '\n=== 31. Nested unsupported file under references/ (canonical, OpenCode install) ===\n'
td31="${TMPDIR}/test31"; mkdir -p "${td31}"
touch "${REPO_FIXTURE}/.apm/skills/writing-work-items/references/rando.txt"
! OPENCODE_CONFIG_DIR="${td31}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td31}/err" || fail "31a: should have failed"
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
ln -s missing.md "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/references/broken.md"
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
replace_fixture_text "${REPO_FIXTURE}/.apm/skills/writing-work-items/SKILL.md" 'name: writing-work-items' 'name: wrong-name'
! OPENCODE_CONFIG_DIR="${td38}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${TMPDIR}/test38-err" || fail "38a: should have failed"
grep -q 'wrong-name\|frontmatter name\|expected stop-slop' "${TMPDIR}/test38-err" && pass "38b: wrong canonical name rejected" || fail "38c: wrong error: $(cat "${TMPDIR}/test38-err")"
opencode_target_unmodified "${td38}" && pass "38d: no managed paths created" || fail "38e: target mutated"

# ---------------------------------------------------------------------------
# 39. OpenCode validates exact canonical source manifests
# ---------------------------------------------------------------------------
printf '\n=== 39. OpenCode extra canonical source entry rejected ===\n'
td39="${TMPDIR}/test39"; mkdir -p "${td39}"
build_fixture
mkdir -p "${REPO_FIXTURE}/.apm/skills/writing-work-items/references/nested"
printf 'extra\n' > "${REPO_FIXTURE}/.apm/skills/writing-work-items/references/nested/extra.md"
! OPENCODE_CONFIG_DIR="${td39}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${TMPDIR}/test39-err" || fail "39a: should have failed"
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
chmod 000 "${REPO_FIXTURE}/.apm/skills/writing-work-items/references/work-item-templates.md"
! OPENCODE_CONFIG_DIR="${td42}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${TMPDIR}/test42-err" || fail "42a: should have failed"
grep -q 'not readable' "${TMPDIR}/test42-err" && pass "42b: unreadable reference detected" || fail "42c: wrong error: $(cat "${TMPDIR}/test42-err")"
opencode_target_unmodified "${td42}" && pass "42d: no managed paths created" || fail "42e: target mutated"
chmod -R +rwX "${REPO_FIXTURE}/.apm/skills/writing-work-items" 2>/dev/null || true
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
  case "${tool}" in
    cursor)
      printf '%b' "${content}" > "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/SKILL.md"
      ! CURSOR_CONFIG_DIR="${td}" bash "${CURSOR_HELPER}" install --dry-run 2>"${td}/err" || { fail "${tn}a: ${label} should have failed"; return; }
      cursor_target_unmodified "${td}" && pass "${tn}d: ${label} no managed paths" || fail "${tn}e: ${label} target mutated"
      ;;
    opencode)
      printf '%b' "${content}" > "${REPO_FIXTURE}/.apm/skills/writing-work-items/SKILL.md"
      ! OPENCODE_CONFIG_DIR="${td}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td}/err" || { fail "${tn}a: ${label} should have failed"; return; }
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
# 62. Shared install copies base plugins without wiping other plugins
# ---------------------------------------------------------------------------
printf '\n=== 62. Shared install copies base plugins ===\n'
td62="${TMPDIR}/test62"; mkdir -p "${td62}/plugins"
printf '%s\n' '// keep me' > "${td62}/plugins/unrelated.js"
printf '%s\n' '// previous shell-agents' > "${td62}/plugins/shell-agents.js"
OPENCODE_CONFIG_DIR="${td62}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td62}/err" && pass "62a: shared install succeeded" || fail "62b: shared install failed: $(cat "${td62}/err")"
for plugin_name in dcg-guard.js shell-agents.js; do
  cmp -s "${REPO_FIXTURE}/profiles/base/plugins/${plugin_name}" "${td62}/plugins/${plugin_name}" && pass "62c: ${plugin_name} installed" || fail "62d: ${plugin_name} not copied from profiles/base/plugins"
done
backup62="$(find "${td62}/.backup" -name shell-agents.js -type f 2>/dev/null | head -n 1)"
[[ -n "${backup62}" && "$(cat "${backup62}")" == "// previous shell-agents" ]] && pass "62g: replaced shell-agents plugin backed up" || fail "62h: replaced shell-agents plugin not backed up"
[[ -f "${td62}/plugins/unrelated.js" ]] && pass "62e: existing unrelated plugin preserved" || fail "62f: existing plugins directory was wiped"
build_fixture

# ---------------------------------------------------------------------------
# 63. Missing base plugin source fails before mutation
# ---------------------------------------------------------------------------
printf '\n=== 63. Missing base plugin source fails before mutation ===\n'
for plugin_name in dcg-guard.js shell-agents.js; do
  td63="${TMPDIR}/test63-${plugin_name}"; mkdir -p "${td63}"
  printf '{"existing":"opencode"}\n' > "${td63}/opencode.json"
  printf '{"existing":"agent_hive"}\n' > "${td63}/agent_hive.json"
  cp "${td63}/opencode.json" "${td63}/opencode.json.before"
  cp "${td63}/agent_hive.json" "${td63}/agent_hive.json.before"
  rm -f "${REPO_FIXTURE}/profiles/base/plugins/${plugin_name}"
  if ! OPENCODE_CONFIG_DIR="${td63}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td63}/err"; then
    grep -q "ERROR.*${plugin_name}" "${td63}/err" && pass "63a: missing ${plugin_name} exits non-zero" || fail "63b: wrong error: $(cat "${td63}/err")"
    if cmp -s "${td63}/opencode.json" "${td63}/opencode.json.before" && cmp -s "${td63}/agent_hive.json" "${td63}/agent_hive.json.before" && [[ ! -e "${td63}/plugins" ]]; then
      pass "63c: existing target config unmodified without ${plugin_name}"
    else
      fail "63d: existing target config mutated without ${plugin_name}"
    fi
  else
    fail "63e: install should have failed when profiles/base/plugins/${plugin_name} is absent"
  fi
  build_fixture
done

# ---------------------------------------------------------------------------
# 63f. Malformed writing-policy source fails before OpenCode target mutation
# ---------------------------------------------------------------------------
printf '\n=== 63f. Malformed writing-policy fails before mutation ===\n'
td63f="${TMPDIR}/test63f"; mkdir -p "${td63f}"
printf '{"existing":"opencode"}\n' > "${td63f}/opencode.json"
printf '{"existing":"agent_hive"}\n' > "${td63f}/agent_hive.json"
cp "${td63f}/opencode.json" "${td63f}/opencode.json.before"
cp "${td63f}/agent_hive.json" "${td63f}/agent_hive.json.before"
printf 'not a skill\n' > "${REPO_FIXTURE}/.apm/skills/writing-work-items/SKILL.md"
if ! OPENCODE_CONFIG_DIR="${td63f}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td63f}/err"; then
  grep -q 'writing-work-items' "${td63f}/err" && pass "63f-a: malformed writing-work-items exits non-zero" || fail "63f-b: wrong error: $(cat "${td63f}/err")"
  if cmp -s "${td63f}/opencode.json" "${td63f}/opencode.json.before" && cmp -s "${td63f}/agent_hive.json" "${td63f}/agent_hive.json.before"; then
    pass "63f-c: existing target config unmodified"
  else
    fail "63f-d: existing target config mutated"
  fi
else
  fail "63f-e: install should have failed when writing-work-items source is malformed"
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
if PATH="${cymbal_bin}:/usr/bin:/bin" CYMBAL_HOOK_LOG="${TMPDIR}/install-cymbal-hook.log" OPENCODE_CONFIG_DIR="${td64}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply >/dev/null; then
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
if PATH="${cymbal_bin}:/usr/bin:/bin" OPENCODE_CONFIG_DIR="${td64_fail}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${TMPDIR}/install-failing-cymbal.err" && grep -q 'Warning: failed to install optional Cymbal OpenCode hook.' "${TMPDIR}/install-failing-cymbal.err" && [[ -f "${td64_fail}/opencode.json" ]]; then
  pass "64c: failed Cymbal hook warns without failing base install"
else
  fail "64c: failed Cymbal hook should warn without failing base install"
fi
build_fixture

# ---------------------------------------------------------------------------
# 65. Repository payloads use the portable Luna/Sol Hive policy
# ---------------------------------------------------------------------------
printf '\n=== 65. Repository OpenAI-only payload contracts ===\n'
if python3 - "${BASELINE_PWD}" <<'PY'
import json
import re
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

allowed_models = {"openai/gpt-6-luna", "openai/gpt-6.1-sol"}
blocked_substrings = ("opencode-go/", "magic-compact", "opencode-go-multi-auth")
for path, value in walk(hive):
    if not isinstance(value, str):
        continue
    if path.endswith(".model") and value not in allowed_models:
        errors.append(f"{hive_path.name} {path}={value}")

for path, value in walk(opencode):
    if not isinstance(value, str):
        continue
    if any(part in value for part in blocked_substrings):
        errors.append(f"{open_path.name} {path}={value}")
    if path.endswith(".model") and value not in allowed_models:
        errors.append(f"{open_path.name} {path}={value}")

plugin = opencode.get("plugin") or []
if "oc-arkive@latest" not in plugin:
    errors.append("opencode.json missing oc-arkive@latest")
if "opencode-gpt-imagegen" not in plugin:
    errors.append("opencode.json missing opencode-gpt-imagegen")
for entry in plugin:
    if not isinstance(entry, str) or entry.startswith(("file:", "/", "./", "../", "~")):
        errors.append(f"opencode.json plugin must be a package reference, got {entry!r}")
if opencode.get("snapshot") is not False or opencode.get("autoupdate") is not False:
    errors.append("opencode.json must set snapshot and autoupdate to false")
open_agents = opencode.get("agent") or {}
if open_agents.get("explore") != {"disable": True}:
    errors.append(f"built-in explore must be disabled without a model override: {open_agents.get('explore')!r}")
if open_agents.get("compaction") != {"model": "openai/gpt-6-luna", "variant": "medium"}:
    errors.append(f"compaction agent={open_agents.get('compaction')!r}")
for key in ("small_model", "permission", "disabled_providers"):
    if key in opencode:
        errors.append(f"opencode.json must not set {key}")
if set(opencode.get("provider") or {}) != {"openai"}:
    errors.append(f"opencode.json providers={sorted(opencode.get('provider') or {})}, expected only openai")

required_custom = {
    "documentation-reviewer",
    "adversarial-documentation-reviewer",
    "ui-reviewer",
}
custom = hive.get("customAgents") or {}
agents = hive.get("agents") or {}
missing = sorted(required_custom - set(custom))
if missing:
    errors.append(f"missing customAgents: {missing}")
if "code-reviewer-documentation" in custom:
    errors.append("legacy customAgents.code-reviewer-documentation still present")
if "code-reviewer-ui" in custom:
    errors.append("legacy customAgents.code-reviewer-ui still present")

def declared_skills(entry):
    return list((entry or {}).get("autoLoadSkills") or [])

def configured_inherited_skills(name):
    # Repository-controlled base+custom merge/dedup. Not the runtime-effective Hive list.
    if name in custom:
        merged = declared_skills(agents.get((custom[name] or {}).get("baseAgent"))) + declared_skills(custom[name])
    else:
        merged = declared_skills(agents.get(name))
    seen = set()
    out = []
    for skill in merged:
        if skill in seen:
            continue
        seen.add(skill)
        out.append(skill)
    return out

docs_depth = ("writing-for-humans",)
docs_specialists = {
    "forager-documents": docs_depth,
    "documentation-reviewer": docs_depth,
    "adversarial-documentation-reviewer": ("adversarial-review",) + docs_depth,
}

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

exact_seats = {
    "forager-smart": ("openai/gpt-6.1-sol", "xhigh"),
    "forager-capable": ("openai/gpt-6.1-sol", "xhigh"),
    "forager-documents": ("openai/gpt-6-luna", "high"),
    "forager-ui": ("openai/gpt-6.1-sol", "medium"),
    "adversarial-plan-reviewer": ("openai/gpt-6.1-sol", "xhigh"),
    "adversarial-documentation-reviewer": ("openai/gpt-6.1-sol", "medium"),
    "adversarial-code-reviewer": ("openai/gpt-6.1-sol", "xhigh"),
    "adversarial-simplicity-reviewer": ("openai/gpt-6.1-sol", "xhigh"),
    "adversarial-approach-advisor": ("openai/gpt-6.1-sol", "xhigh"),
    "ui-design-advisor": ("openai/gpt-6.1-sol", "medium"),
    "approach-advisor-xhigh-reasoning": ("openai/gpt-6.1-sol", "max"),
    "ui-reviewer": ("openai/gpt-6.1-sol", "medium"),
    "documentation-reviewer": ("openai/gpt-6-luna", "high"),
    "hive-master": ("openai/gpt-6.1-sol", "medium"),
    "architect-planner": ("openai/gpt-6.1-sol", "xhigh"),
    "swarm-orchestrator": ("openai/gpt-6.1-sol", "medium"),
    "scout-researcher": ("openai/gpt-6-luna", "high"),
    "forager-worker": ("openai/gpt-6.1-sol", "medium"),
    "hive-helper": ("openai/gpt-6-luna", "medium"),
    "plan-reviewer": ("openai/gpt-6.1-sol", "medium"),
    "code-reviewer": ("openai/gpt-6.1-sol", "medium"),
    "simplicity-reviewer": ("openai/gpt-6.1-sol", "medium"),
    "approach-advisor": ("openai/gpt-6.1-sol", "xhigh"),
    "vulnerability-reviewer": ("openai/gpt-6.1-sol", "max"),
    "hive-builder": ("openai/gpt-6.1-sol", "medium"),
    "taskTraceSummarizer": ("openai/gpt-6-luna", "medium"),
}
seats = {**agents, **custom, "taskTraceSummarizer": hive.get("taskTraceSummarizer") or {}}
if set(seats) != set(exact_seats):
    errors.append(f"unexpected role set: {sorted(set(seats) ^ set(exact_seats))}")
for name, expected in exact_seats.items():
    entry = seats.get(name) or {}
    actual = (entry.get("model"), entry.get("variant"))
    if actual != expected:
        errors.append(f"{name} model/variant={actual!r}, expected {expected!r}")
for name, entry in custom.items():
    if entry.get("baseAgent") not in agents:
        errors.append(f"{name} has unsupported baseAgent {entry.get('baseAgent')!r}")
for name, group in groups.items():
    unknown = set(group.get("members") or []) - (set(agents) | set(custom))
    if unknown:
        errors.append(f"council.groups.{name} references unknown roles: {sorted(unknown)}")
minimal_members = (groups.get("minimal-change") or {}).get("members") or []
if "adversarial-simplicity-reviewer" not in minimal_members or "adversarial-code-reviewer" in minimal_members:
    errors.append(f"council.groups.minimal-change must use adversarial-simplicity-reviewer: {minimal_members!r}")
if "disableMcps" in hive:
    errors.append("base agent_hive.json must not disable Hive research MCPs")
if "sandbox" in hive:
    errors.append("base agent_hive.json must omit sandbox")

orchestration_skills = {
    "hive-master": ["parallel-exploration"],
    "architect-planner": ["brainstorming", "writing-plans", "parallel-exploration", "dispatching-parallel-agents", "background-delegation"],
    "swarm-orchestrator": ["dispatching-parallel-agents", "parallel-exploration", "background-delegation", "executing-plans"],
    "hive-builder": ["parallel-exploration", "dispatching-parallel-agents", "background-delegation"],
    "scout-researcher": ["cymbal"],
    "forager-worker": ["verification"],
}
for name, expected in orchestration_skills.items():
    if (agents.get(name) or {}).get("autoLoadSkills") != expected:
        errors.append(f"{name} must autoload {expected!r}")
for name, entry in custom.items():
    if name.startswith("adversarial-"):
        if "adversarial-review" not in (entry.get("autoLoadSkills") or []):
            errors.append(f"{name} must autoload adversarial-review")
        description = entry.get("description", "")
        if "in addition to" not in description:
            errors.append(f"{name} must supplement the first review pass")
        if name in {
            "adversarial-plan-reviewer",
            "adversarial-documentation-reviewer",
            "adversarial-approach-advisor",
        } and "do not replace" not in description:
            errors.append(f"{name} must keep the do-not-replace clause")
for name, phrases in {
    "adversarial-code-reviewer": ("failure-sensitive logic", "unresolved correctness risk", "Skip routine, localized behavior changes"),
    "code-reviewer": ("failure-sensitive logic", "Skip the adversarial pass for routine, localized behavior changes"),
    "adversarial-simplicity-reviewer": ("introduces or expands abstractions", "materially larger"),
    "forager-smart": ("mechanism is unsettled", "substantive dead end", "Named changes stay with forager-worker or forager-capable"),
    "forager-capable": ("Use up front only when", "use forager-worker", "goes to forager-smart"),
    "scout-researcher": ("Search agent", "decomposed and fanned out", "parallel dispatches"),
}.items():
    if any(phrase not in (seats.get(name) or {}).get("description", "") for phrase in phrases):
        errors.append(f"{name} is missing its dispatch boundary")

for path, value in walk(hive):
    if value == "verification-before-completion":
        errors.append(f"deprecated verification-before-completion at {path}")
    if value in {"ivan-writing", "impeccable"}:
        errors.append(f"shared Agent Hive config contains personal-only skill {value} at {path}")

depth = {"writing-for-humans", "humanizer", "stop-slop"}
router = "writing-policy"
configured_no_skills = {"hive-helper"}
for name, expected in docs_specialists.items():
    skills = configured_inherited_skills(name)
    missing_docs = [skill for skill in expected if skill not in skills]
    if missing_docs:
        errors.append(f"{name} configured inherited skills missing {missing_docs}")
    rewrite_overlays = {"humanizer", "stop-slop"}.intersection(skills)
    if rewrite_overlays:
        errors.append(f"{name} must load rewrite overlays conditionally, not auto-load {sorted(rewrite_overlays)}")
    depth_indexes = [skills.index(skill) for skill in depth if skill in skills]
    if router not in skills or (depth_indexes and skills.index(router) > min(depth_indexes)):
        errors.append(f"{name} must keep {router} ahead of prose depth skills")
for name in ("forager-ui", "ui-reviewer", "ui-design-advisor"):
    skills = configured_inherited_skills(name)
    if "web-design-guidelines" not in skills or "stop-design-slop" not in skills:
        errors.append(f"{name} configured inherited skills missing UI guidance")
for name in list(agents) + list(custom):
    skills = configured_inherited_skills(name)
    declared = declared_skills(custom.get(name) if name in custom else agents.get(name))
    if name in configured_no_skills:
        if skills:
            errors.append(f"{name} must have no configured auto-loaded skills")
        continue
    if name not in docs_specialists and router in skills:
        errors.append(f"{name} must not auto-load {router}; only document-focused roles do")
    if name in docs_specialists and router not in declared:
        errors.append(f"{name} must declare {router} itself")
    if name not in docs_specialists and depth.intersection(skills):
        errors.append(f"{name} must not auto-load prose depth skills {sorted(depth.intersection(skills))}")
if configured_inherited_skills("forager-documents")[:2] != ["verification", router]:
    errors.append("forager-documents configured inherited skills must start with verification then writing-policy")

# The Cursor bundle routes prose through unslop, which is imported whole; keep only the routing contract the Rules and agents rely on.
skill_path = root / ".apm/cursor/skills/unslop/SKILL.md"
if not skill_path.is_file():
    errors.append("missing .apm/cursor/skills/unslop/SKILL.md")
else:
    skill_text = skill_path.read_text(encoding="utf-8")
    lowered_skill = skill_text.casefold()
    if "name: unslop" not in skill_text.split("\n---\n", 2)[0]:
        errors.append("unslop frontmatter name is wrong")
    for required in ("parent-loaded skills do not imply child loading", "artifact", "audience", "writing-for-humans", "writing-for-agents", "humanizer", "stop-slop", "stop-design-slop"):
        if required not in lowered_skill:
            errors.append(f"unslop is missing {required!r}")
    if "ivan-writing" in lowered_skill.replace("a personal voice overlay", ""):
        errors.append("portable unslop must not name ivan-writing")
for retired_name in ("writing-policy",):
    if (root / ".apm/cursor/skills" / retired_name).exists():
        errors.append(f"retired {retired_name} is still in the Cursor skill set")

if list((root / "profiles/optional").glob("agent_hive.*.json")):
    errors.append("optional bundles must not overlay Agent Hive config")

retrieval_rule = (
    "Prefer retrieved evidence over model memory. Use configured search and fetch tools for externally "
    "verifiable facts you would otherwise infer or recall, especially releases, prices, current documentation, "
    "and company identity; assess source authority, recency, and conflicts."
)
for profile_path in sorted((root / "profiles/agents").glob("*.md")):
    text = profile_path.read_text(encoding="utf-8")
    if "verification-before-completion" in text:
        errors.append(f"{profile_path.relative_to(root)} still references verification-before-completion")
    rel = str(profile_path.relative_to(root))
    if profile_path.name == "README.md":
        continue
    if re.search(r"\b[Ll]oad `ast-grep`", text):
        errors.append(f"{rel} must not require the retired ast-grep skill")
    if "| Syntax-aware structural search | `ast-grep` MCP tools |" not in text:
        errors.append(f"{rel} must retain ast-grep MCP routing")
    if retrieval_rule not in text:
        errors.append(f"{rel} must carry the retrieved-evidence rule")
    if "`explore`" in text:
        errors.append(f"{rel} must not route to the disabled built-in explore agent")
    prose_sections = re.findall(r"^## Prose policy\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
    if len(prose_sections) != 1:
        errors.append(f"{rel} must have one short Prose policy section")
    else:
        prose = prose_sections[0]
        if "Use `writing-policy` for human-facing prose and prose handoffs." not in prose:
            errors.append(f"{rel} must reference writing-policy in its Prose policy section")
        if "conditional depth-skill routing" not in prose or "required output format" not in prose:
            errors.append(f"{rel} must retain conditional prose routing and required output format")
        if len(prose.split()) > 100:
            errors.append(f"{rel} Prose policy must stay a short pointer, not copy the finish gate")
    if "## Prose Finish Gate" in text:
        errors.append(f"{rel} must not copy the Prose Finish Gate")
    if "Draft with `writing-for-humans`" in text:
        errors.append(f"{rel} still drafts with writing-for-humans")
    if "Require each child to load those skills itself" not in text:
        errors.append(f"{rel} must require each child to load the named skills itself")
    if "Write in Ivan's voice by default" in text:
        errors.append(f"{rel} still defaults to Ivan voice")
    if rel.startswith("profiles/agents/personal-"):
        if "technical or product prose prepared to or as Ivan" not in text or "published, submitted, or sent as Ivan" not in text:
            errors.append(f"{rel} must load ivan-writing for technical/product prose to or as Ivan and authored prose")
        if "preserve requested neutral, team, or third-party authorship" not in text:
            errors.append(f"{rel} must preserve requested authorship")
        if "Internal worker reports stay neutral" not in text:
            errors.append(f"{rel} must keep internal worker reports neutral unless requested")
        if "PR and review drafts require explicit operator selection of personal voice under `pr-writing`." not in text:
            errors.append(f"{rel} must require explicit personal-voice selection for PR and review drafts")
    elif "ivan-writing" in text:
        errors.append(f"{rel} must not reference ivan-writing")

cursor_rules = (root / ".apm/cursor/rules/default-agent.md").read_text(encoding="utf-8")
if retrieval_rule not in cursor_rules:
    errors.append("default-agent.md must carry the retrieved-evidence rule")
if "ivan-writing" not in cursor_rules:
    errors.append("default-agent.md must mention ivan-writing")
elif "installed or configured" not in cursor_rules:
    errors.append("default-agent.md must load ivan-writing only when installed or configured")
if "published, submitted, or sent as Ivan" not in cursor_rules:
    errors.append("default-agent.md must load ivan-writing for published/submitted/sent prose")
if "technical or product prose prepared to or as Ivan" not in cursor_rules:
    errors.append("default-agent.md must load ivan-writing for technical/product prose to or as Ivan")
if "preserve requested neutral, team, or third-party authorship" not in cursor_rules:
    errors.append("default-agent.md must preserve requested authorship")
if "PR and review drafts require explicit operator selection of personal voice under `pr-writing`." not in cursor_rules:
    errors.append("default-agent.md must require explicit personal-voice selection for PR and review drafts")

if not plugin_path.is_file():
    errors.append("profiles/base/plugins/dcg-guard.js missing")
else:
    text = plugin_path.read_text(encoding="utf-8")
    if "Bun.which(\"dcg\")" not in text or "tool.execute.before" not in text:
        errors.append("dcg-guard.js is not the Destructive Command Guard adapter")
shell_agents = root / "profiles/base/plugins/shell-agents.js"
if not shell_agents.is_file():
    errors.append("profiles/base/plugins/shell-agents.js missing")
else:
    text = shell_agents.read_text(encoding="utf-8")
    if "tool.execute.after" not in text or 'ctx.tool.hook("execute.after"' not in text:
        errors.append("shell-agents.js is not the shell AGENTS.md discovery plugin")
shell_tests = root / "tests/shell-agents.test.js"
if not shell_tests.is_file() or 'from "../profiles/base/plugins/shell-agents.js"' not in shell_tests.read_text(encoding="utf-8"):
    errors.append("tests/shell-agents.test.js must exercise profiles/base/plugins/shell-agents.js")

if errors:
    print("\n".join(errors))
    raise SystemExit(1)
print("ok")
PY
then
  pass "65a: base payloads enforce portable Luna/Sol Hive roles and efforts"
else
  fail "65b: base payloads enforce portable Luna/Sol Hive roles and efforts"
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
anchor='Apply the Engineering Judgment section appended to this prompt within this role'"'"'s current scope and finding bar.'

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

  git -C "${upstream67}" checkout -q -- packages/opencode-hive/src/agents/engineering-judgment.ts
  python3 - "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(
    'export const ENGINEERING_JUDGMENT_PROMPT = `## Engineering Judgment\n\nLoad \\`code-design-principles\\`.\n`;\n',
    encoding='utf-8',
)
PY
  git -C "${upstream67}" add .
  git -C "${upstream67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm escaped-backtick
  if "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67-backtick.out" 2>"${TMPDIR}/sync67-backtick.err" &&
    python3 - "${REPO_FIXTURE}/${vendor_rel}" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding='utf-8')
if 'Load `code-design-principles`.' not in text or '\\`' in text:
    raise SystemExit('vendored markdown did not contain a real backtick')
PY
  then
    pass "67f2: sync unescapes a template backtick into the vendored markdown"
  else
    fail "67f2: sync did not unescape a template backtick: $(cat "${TMPDIR}/sync67-backtick.err")"
  fi

  python3 - "${upstream67}/packages/opencode-hive/src/agents/engineering-judgment.ts" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
path.write_text(
    'export const ENGINEERING_JUDGMENT_PROMPT = `## Engineering Judgment\n\nLine\\nbreak.\n`;\n',
    encoding='utf-8',
)
PY
  git -C "${upstream67}" add .
  git -C "${upstream67}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm other-escape
  if ! "${REPO_FIXTURE}/${sync_rel}" --source-repo "${upstream67}" --ref HEAD >"${TMPDIR}/sync67-escape.out" 2>"${TMPDIR}/sync67-escape.err" && grep -qi 'escape\|unsupported' "${TMPDIR}/sync67-escape.err"; then
    pass "67f3: sync rejects an unsupported escape in the upstream prompt"
  else
    fail "67f3: sync accepted an unsupported escape or returned the wrong error"
  fi
else
  fail "67c: sync behavior unavailable"
  fail "67d: repeated sync behavior unavailable"
  fail "67e: Git replacement behavior unavailable"
  fail "67f: interpolation rejection unavailable"
  fail "67f2: escaped backtick sync unavailable"
  fail "67f3: unsupported escape rejection unavailable"
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
selected = {'forager', 'scout', 'plan-reviewer', 'code-reviewer', 'simplicity-reviewer', 'approach-advisor', 'vulnerability-reviewer'}
errors = []
for name in selected:
    text = (root / f'.apm/cursor/agents/{name}.md').read_text(encoding='utf-8')
    if text.count(anchor) != 1:
        errors.append(f'{name} anchor count is {text.count(anchor)}')
    if '## Engineering Judgment' in text:
        errors.append(f'{name} embeds the snapshot instead of receiving it at install')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "67p: every Cursor role points once at the Engineering Judgment appended at install"
else
  fail "67p: Cursor role anchor contract is not satisfied"
fi

# 67p2. Installed agent prompts: source frontmatter first, then the pinned snapshot exactly once.
td67t="${TMPDIR}/cursor67t"
mkdir -p "${td67t}"
sandbox_agents_skills
dry67t_out="${TMPDIR}/dry67t.out"
env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td67t}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install --dry-run >"${dry67t_out}" 2>"${TMPDIR}/dry67t.err" || true
env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td67t}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install >"${TMPDIR}/install67t.out" 2>"${TMPDIR}/install67t.err" || true
if python3 - "${BASELINE_PWD}" "${td67t}" "${dry67t_out}" <<'PY'
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
target = Path(sys.argv[2])
dry_run = Path(sys.argv[3]).read_text(encoding='utf-8')
judgment = (root / 'vendor/oc-arkive/engineering-judgment/engineering-judgment.md').read_bytes()
errors = []
names = sorted(path.stem for path in (root / '.apm/cursor/agents').glob('*.md'))
if len(names) != 7:
    errors.append(f'expected seven agents, found {names}')
for name in names:
    source = (root / f'.apm/cursor/agents/{name}.md').read_bytes()
    installed = (target / f'agents/{name}.md').read_bytes()
    expected = source + b'\n---\n\n' + judgment
    if installed != expected:
        errors.append(f'installed {name} is not source + separator + pinned snapshot')
    if not installed.startswith(b'---\nname: ' + name.encode() + b'\n'):
        errors.append(f'installed {name} lost its frontmatter')
    if installed.count(b'## Engineering Judgment') != 1:
        errors.append(f'installed {name} must carry Engineering Judgment exactly once')
    printed = subprocess.run([str(root / 'scripts/cursor-assets.sh'), 'print-agent', name], capture_output=True, check=False)
    if printed.returncode != 0 or printed.stdout != installed:
        errors.append(f'print-agent {name} does not match the installed prompt')
    line = f'Would copy agents/{name}.md with pinned Engineering Judgment appended -> {target}/agents/{name}.md'
    if line not in dry_run:
        errors.append(f'dry-run does not describe the composed {name} prompt')
unknown = subprocess.run([str(root / 'scripts/cursor-assets.sh'), 'print-agent', 'not-an-agent'], capture_output=True, check=False)
if unknown.returncode == 0:
    errors.append('print-agent accepted an unknown agent name')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "67p2: installed agent prompts, print-agent, and the dry-run plan agree on source + pinned Engineering Judgment"
else
  fail "67p2: installed agent prompts do not match the composed source, print-agent, or dry-run plan"
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
        ('provenance-pinned to oc-arkive 5.1.0', 'Engineering Judgment provenance pin'),
        ('opencode receives engineering judgment from the installed plugin', 'OpenCode delivery'),
        ('cursor cannot load the plugin prompt directly', 'Cursor plugin limitation'),
        ('each installed agent file carries', 'agent composition'),
    )
    for phrase, label in required:
        if phrase.casefold() not in lowered:
            errors.append(f'{relative} is missing {label}: {phrase}')
    if 'oc-arkive@latest` is 4.0.0' in lowered or 'oc-arkive@latest is 4.0.0' in lowered or 'oc-arkive@latest` is 2.3.5' in lowered or 'oc-arkive@latest is 2.3.5' in lowered:
        errors.append(f'{relative} still claims oc-arkive@latest equals a fixed version')
    for obsolete in ('2.3.4', 'postdates tag', 'does not contain engineering judgment', 'does not contain it'):
        if obsolete in lowered:
            errors.append(f'{relative} retains obsolete unpublished-release wording: {obsolete}')

vendor = root / 'vendor/oc-arkive/engineering-judgment/engineering-judgment.md'
provenance = json.loads((vendor.parent / 'provenance.json').read_text(encoding='utf-8'))
expected_release = {
    'commit': 'd8de1e7691ebf3716afc0e3469c8743ca64169fb',
    'packageVersion': '5.1.0',
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
  pass "67s: Engineering Judgment provenance pin and documentation boundary"
else
  fail "67s: Engineering Judgment provenance pin and documentation boundary"
fi

# ---------------------------------------------------------------------------
# 68. Cursor Hive-shared skill vendoring and OpenCode unshadow
# ---------------------------------------------------------------------------
printf '\n=== 68. Cursor Hive-shared skill vendoring and OpenCode unshadow ===\n'
build_fixture
hive_skill_sync_rel='scripts/sync-cursor-hive-skills.py'
hive_skill_provenance_rel='vendor/oc-arkive/cursor-skills/provenance.json'

if python3 - "${BASELINE_PWD}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
skills = root / '.apm' / 'skills'
missing = []
for name in (
    'brainstorming',
    'systematic-debugging',
    'test-driven-development',
    'using-git-worktrees',
    'finishing-a-development-branch',
    'consolidate-test-suites',
    'root-cause-finder',
):
    path = skills / name
    if path.exists() or path.is_symlink():
        missing.append(str(path.relative_to(root)))
if missing:
    raise SystemExit('OpenCode fork directories still present: ' + ', '.join(missing))
if (skills / 'ast-grep').exists():
    raise SystemExit('ast-grep must remain unpackaged')
PY
then
  pass "68a: OpenCode does not package Hive-overlapping or retired workflow skill forks"
else
  fail "68a: OpenCode still packages Hive-overlapping or retired workflow skill forks"
fi

td68b="${TMPDIR}/opencode68b"
mkdir -p "${td68b}"
sandbox_agents_skills
for hive_bundled in ${OPENCODE_HIVE_BUNDLED_NAMES}; do
  mkdir -p "${AGENTS_SKILLS_DIR}/${hive_bundled}" "${td68b}/skills/${hive_bundled}"
  printf 'stale agents %s\n' "${hive_bundled}" > "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md"
  printf 'stale opencode %s\n' "${hive_bundled}" > "${td68b}/skills/${hive_bundled}/SKILL.md"
done
install68b_status=0
OPENCODE_CONFIG_DIR="${td68b}" OPENCODE_AGENTS_PROFILE=shared bash "${BASELINE_PWD}/scripts/install-profile.sh" --apply >"${TMPDIR}/install68b.out" 2>"${TMPDIR}/install68b.err" || install68b_status=$?
if [[ "${install68b_status}" -eq 1 ]]; then
  if python3 - "${td68b}" "${AGENTS_SKILLS_DIR}" "${TMPDIR}/install68b.err" <<'PY'
import sys
from pathlib import Path

target = Path(sys.argv[1])
agents = Path(sys.argv[2])
err = Path(sys.argv[3]).read_text(encoding='utf-8')
skills = target / 'skills'
errors = []
for name in ('brainstorming', 'systematic-debugging', 'test-driven-development', 'ast-grep', 'using-git-worktrees', 'finishing-a-development-branch', 'consolidate-test-suites', 'root-cause-finder', 'context-mode'):
    if (skills / name).exists():
        errors.append(f'installed OpenCode skill {name}')
    if name in ('brainstorming', 'systematic-debugging', 'test-driven-development', 'ast-grep') and (agents / name).exists():
        errors.append(f'installed agents skill {name}')
for name in ('humanizer', 'stop-design-slop', 'stop-slop', 'writing-for-humans', 'writing-policy'):
    if (skills / name / 'SKILL.md').read_text(encoding='utf-8') != f'stale opencode {name}\n':
        errors.append(f'{name} OpenCode copy was not left in place')
    if (agents / name / 'SKILL.md').read_text(encoding='utf-8') != f'stale agents {name}\n':
        errors.append(f'{name} agents copy was not left in place')
    for existing, managed in (
        (skills / name, 'Hive materialization'),
        (agents / name, 'Hive materialization'),
    ):
        line = f'decision needed: conflict: {existing} is outside the managed install path {managed}; left in place'
        if line not in err:
            errors.append(f'missing decision line for {existing}')
for name in ('writing-work-items', 'decomposing-work', 'running-agile-delivery'):
    if not (agents / name / 'SKILL.md').is_file():
        errors.append(f'missing shared skill {name} in agents dir')
if not (skills / 'writing-skills' / 'SKILL.md').is_file():
    errors.append('missing OpenCode-local skill writing-skills')
if errors:
    raise SystemExit('\n'.join(errors))
PY
  then
    pass "68b: temp OpenCode install omits Hive-overlapping forks, leaves Hive-bundled copies, and reports them"
  else
    fail "68b: temp OpenCode install leaked forks, dropped managed skills, or missed a decision line"
  fi
else
  fail "68b: temp OpenCode install exited ${install68b_status}: $(cat "${TMPDIR}/install68b.err")"
fi

if python3 - "${BASELINE_PWD}" <<'PY'
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
provenance_path = root / 'vendor/oc-arkive/cursor-skills/provenance.json'
if provenance_path.is_symlink() or not provenance_path.is_file():
    raise SystemExit('cursor-skills provenance.json must be a regular file')
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('cursor_hive_skills_sync', root / 'scripts/sync-cursor-hive-skills.py')
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)
provenance = json.loads(provenance_path.read_text(encoding='utf-8'))
errors = []
if provenance.get('schemaVersion') != 2:
    errors.append('provenance schemaVersion must be 2')
if provenance.get('commit') != 'd8de1e7691ebf3716afc0e3469c8743ca64169fb' or provenance.get('packageVersion') != '5.1.0':
    errors.append(f'unexpected Hive skill pin: {provenance.get("commit")!r} {provenance.get("packageVersion")!r}')
engineering = json.loads((root / 'vendor/oc-arkive/engineering-judgment/provenance.json').read_text(encoding='utf-8'))
if engineering.get('commit') != provenance.get('commit') or engineering.get('packageVersion') != provenance.get('packageVersion'):
    errors.append('skills and Engineering Judgment must share one source pin')
skills = provenance.get('skills')
if not isinstance(skills, dict) or set(skills) != set(sync.IMPORTED_SKILLS):
    errors.append('provenance skills must be exactly the sync script IMPORTED_SKILLS')
for name in sorted(set(skills or {}) & set(sync.IMPORTED_SKILLS)):
    directory = root / '.apm/cursor/skills' / name
    listed = skills[name]['files']
    actual = sorted(path.relative_to(directory).as_posix() for path in directory.rglob('*') if path.is_file())
    if sorted(listed) != actual:
        errors.append(f'{name} tree differs from provenance: {sorted(set(listed) ^ set(actual))}')
        continue
    for relative, entry in listed.items():
        if hashlib.sha256((directory / relative).read_bytes()).hexdigest() != entry['installedSha256']:
            errors.append(f'{name}/{relative} installedSha256 does not match')
    for relative in listed:
        if not relative.endswith('.md') or sync.ATTRIBUTION_NAMES.match(Path(relative).name):
            continue
        text = (directory / relative).read_text(encoding='utf-8')
        for pattern, label in sync.RESIDUE_PATTERNS:
            if pattern.search(text):
                errors.append(f'{name}/{relative} still contains {label} after Cursor rendering')
# Skills named by imported skills must be delivered: verification and
# systematic-debugging route to project-verification, which ships as a full tree.
for name in ('verification', 'systematic-debugging'):
    if '`project-verification`' not in (root / '.apm/cursor/skills' / name / 'SKILL.md').read_text(encoding='utf-8'):
        errors.append(f'{name} no longer names project-verification; revisit the dependency closure')
if sorted(skills.get('project-verification', {}).get('files', {})) != ['LICENSE.pstack', 'SKILL.md', 'UPSTREAM.md', 'references/formal-verification.md']:
    errors.append('project-verification must be imported as its complete tree')
for retired in sync.RETIRED_SKILLS:
    if (root / '.apm/cursor/skills' / retired).exists():
        errors.append(f'retired skill {retired} is still present')
for required in ('LICENSE.pstack',):
    if not (root / '.apm/cursor/skills/verification' / required).is_file():
        errors.append(f'verification is missing {required}')
if not (root / '.apm/cursor/skills/humanizer/check.py').is_file():
    errors.append('humanizer is missing its check.py script')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "68e: vendored Cursor Hive skills are full trees pinned by per-file hashes, share the Engineering Judgment pin, and carry licenses and scripts"
else
  fail "68e: vendored Cursor Hive skills do not match provenance, share one pin, or lost licenses and scripts"
fi

if "${BASELINE_PWD}/scripts/cursor-assets.sh" validate >"${TMPDIR}/validate68f.out" 2>"${TMPDIR}/validate68f.err"; then
  pass "68f: real worktree Cursor validation passes with Hive skill provenance present"
else
  fail "68f: real worktree Cursor validation failed: $(cat "${TMPDIR}/validate68f.err")"
fi

if [[ ! -e "${REPO_FIXTURE}/${hive_skill_provenance_rel}" ]] && "${CURSOR_HELPER}" validate >"${TMPDIR}/validate68g.out" 2>"${TMPDIR}/validate68g.err"; then
  pass "68g: fixture without cursor-skills provenance still validates"
else
  fail "68g: fixture without cursor-skills provenance failed validation or unexpectedly shipped provenance"
fi

# Builds a committed upstream skill source from the sync script's own import
# list and rewrite table, with host sections and attribution files. A mutation
# argument breaks one rule the sync must enforce.
cat > "${TMPDIR}/make-upstream68.py" <<'PY'
import importlib.util
import os
import subprocess
import sys
from pathlib import Path

script, destination, mutation = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('cursor_hive_skills_sync', script)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)
skills = destination / 'packages/opencode-hive/skills'
for name in sync.IMPORTED_SKILLS:
    files = {
        'SKILL.md': f'---\nname: {name}\ndescription: Use when testing fixture {name}.\n---\n\n# {name}\n\nShared text for {name}.\n\n',
    }
    for relative, old, _new in sync.CURSOR_REWRITES.get(name, ()):
        files[relative] = files.get(relative, '') + old + '\n\n'
    files['references/notes.md'] = f'# Notes for {name}\n'
    files['UPSTREAM.md'] = 'Attribution mentions hive_status and skill({ name: "x" }) from the source.\n'
    files['LICENSE'] = f'MIT fixture license for {name}\n'
    if name == 'humanizer':
        files['check.py'] = '#!/usr/bin/env python3\nprint("ok")\n'
    if name == 'brainstorming':
        files['SKILL.md'] += (
            'Shared before.\n'
            '<!-- hive-host opencode-v1 -->\n'
            'V1 ONLY TEXT\n'
            '<!-- /hive-host -->\n'
            '<!-- hive-host opencode-v2 -->\n'
            'V2 ONLY TEXT\n'
            '<!-- /hive-host -->\n'
            'Shared after.\n'
        )
    if mutation == 'unknown-host' and name == 'how':
        files['SKILL.md'] += '<!-- hive-host cursor -->\nx\n<!-- /hive-host -->\n'
    if mutation == 'unclosed' and name == 'how':
        files['SKILL.md'] += '<!-- hive-host opencode-v1 -->\nx\n'
    if mutation == 'stray-close' and name == 'how':
        files['SKILL.md'] += '<!-- /hive-host -->\n'
    if mutation == 'inline-marker' and name == 'how':
        files['SKILL.md'] += 'text <!-- hive-host opencode-v1 --> inline\n'
    if mutation == 'residue' and name == 'how':
        files['SKILL.md'] += 'Load it with skill({ name: "verification" }).\n'
    prose_residue = {
        'residue-native-skill': 'Load it with the native skill tool.\n',
        'residue-hive': 'Follow the Hive plan before editing.\n',
        'residue-opencode': 'Run this inside OpenCode.\n',
        'residue-oc-arkive': 'Install oc-arkive first.\n',
    }
    if mutation in prose_residue and name == 'how':
        files['SKILL.md'] += prose_residue[mutation]
    if mutation == 'drift' and name == 'grilling':
        relative, old, _new = sync.CURSOR_REWRITES['grilling'][0]
        files[relative] = files[relative].replace(old, 'changed upstream wording')
    for relative, content in files.items():
        path = skills / name / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding='utf-8')
(destination / 'packages/opencode-hive/package.json').write_text(
    '{\n  "name": "oc-arkive",\n  "version": "9.8.7",\n  "repository": {"type": "git", "url": "https://example.test/agent-hive.git"}\n}\n',
    encoding='utf-8',
)
environment = {key: value for key, value in os.environ.items() if not key.startswith('GIT_')}
environment.update(GIT_AUTHOR_NAME='Fixture', GIT_AUTHOR_EMAIL='fixture@example.test', GIT_COMMITTER_NAME='Fixture', GIT_COMMITTER_EMAIL='fixture@example.test')
for command in (['init', '-q'], ['add', '.'], ['commit', '-qm', 'fixture']):
    subprocess.run(['git', '-C', str(destination), *command], check=True, env=environment)
PY
cat > "${TMPDIR}/tree-digest68.py" <<'PY'
import hashlib
import sys
from pathlib import Path

root = Path(sys.argv[1])
digest = hashlib.sha256()
for path in sorted(root.rglob('*')):
    if path.is_file():
        digest.update(path.relative_to(root).as_posix().encode())
        digest.update(path.read_bytes())
print(digest.hexdigest())
PY
sync68_digest() { python3 "${TMPDIR}/tree-digest68.py" "${REPO_FIXTURE}/.apm/cursor/skills"; python3 "${TMPDIR}/tree-digest68.py" "${REPO_FIXTURE}/vendor/oc-arkive/cursor-skills"; }

upstream68="${TMPDIR}/upstream68"
mkdir -p "${upstream68}"
python3 "${TMPDIR}/make-upstream68.py" "${REPO_FIXTURE}/${hive_skill_sync_rel}" "${upstream68}" none
commit68="$(git -C "${upstream68}" rev-parse HEAD)"
printf '%s\n' 'dirty checkout must not be read' > "${upstream68}/packages/opencode-hive/skills/brainstorming/SKILL.md"
mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/writing-policy" "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/stale-dir"
printf 'retired\n' > "${REPO_FIXTURE}/.apm/cursor/skills/writing-policy/SKILL.md"
printf 'stale\n' > "${REPO_FIXTURE}/.apm/cursor/skills/humanizer/stale-dir/old.txt"
local68_before="$(cat "${REPO_FIXTURE}/.apm/cursor/skills/subagent-delegation/SKILL.md")"

if [[ -x "${REPO_FIXTURE}/${hive_skill_sync_rel}" ]]; then
  if "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref HEAD >"${TMPDIR}/sync68.out" 2>"${TMPDIR}/sync68.err"; then
    printf '%s\n' "${local68_before}" > "${TMPDIR}/local68-before.txt"
    if python3 - "${REPO_FIXTURE}" "${commit68}" "${TMPDIR}/sync68.out" "${TMPDIR}/local68-before.txt" <<'PY'
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
commit = sys.argv[2]
output = Path(sys.argv[3]).read_text(encoding='utf-8')
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('cursor_hive_skills_sync', root / 'scripts/sync-cursor-hive-skills.py')
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)
skills = root / '.apm/cursor/skills'
errors = []
provenance = json.loads((root / 'vendor/oc-arkive/cursor-skills/provenance.json').read_text(encoding='utf-8'))
if (provenance['schemaVersion'], provenance['commit'], provenance['packageVersion'], provenance['upstreamRepository']) != (2, commit, '9.8.7', 'https://example.test/agent-hive.git'):
    errors.append(f'wrong provenance header: {provenance!r}')
if set(provenance['skills']) != set(sync.IMPORTED_SKILLS):
    errors.append('provenance must list exactly the imported skills')
for name in sync.IMPORTED_SKILLS:
    directory = skills / name
    listed = provenance['skills'][name]['files']
    actual = sorted(path.relative_to(directory).as_posix() for path in directory.rglob('*') if path.is_file())
    if sorted(listed) != actual:
        errors.append(f'{name} tree {actual} differs from provenance {sorted(listed)}')
        continue
    for relative, entry in listed.items():
        if hashlib.sha256((directory / relative).read_bytes()).hexdigest() != entry['installedSha256']:
            errors.append(f'{name}/{relative} installed hash is wrong')
    for required in ('SKILL.md', 'LICENSE', 'UPSTREAM.md', 'references/notes.md'):
        if required not in listed:
            errors.append(f'{name} dropped {required}')
    for relative, old, new in sync.CURSOR_REWRITES.get(name, ()):
        text = (directory / relative).read_text(encoding='utf-8')
        if new not in text or (old not in new and old in text):
            errors.append(f'{name}/{relative} rewrite was not applied exactly')
brainstorming = (skills / 'brainstorming/SKILL.md').read_text(encoding='utf-8')
if 'V1 ONLY TEXT' in brainstorming or 'V2 ONLY TEXT' in brainstorming or 'hive-host' in brainstorming:
    errors.append('host sections were not dropped from brainstorming')
if 'Shared before.\nShared after.' not in brainstorming and 'Shared before.\n\nShared after.' not in brainstorming:
    errors.append('shared text around the dropped host sections was not kept')
if 'dirty checkout' in brainstorming:
    errors.append('sync read the dirty working tree instead of the committed source')
attribution = (skills / 'humanizer/UPSTREAM.md').read_text(encoding='utf-8')
if 'hive_status' not in attribution or 'skill({ name: "x" })' not in attribution:
    errors.append('attribution files must keep their source wording')
if not (skills / 'humanizer/check.py').is_file():
    errors.append('script was not synced')
if (skills / 'writing-policy').exists() or 'removed stale imported skill writing-policy' not in output:
    errors.append('retired skill was not removed and reported')
if (skills / 'humanizer/stale-dir').exists() or 'removed stale file humanizer/stale-dir/old.txt' not in output:
    errors.append('stale file inside an imported skill was not removed and reported')
if (skills / 'subagent-delegation/SKILL.md').read_text(encoding='utf-8') != Path(sys.argv[4]).read_text(encoding='utf-8'):
    errors.append('a locally maintained skill was touched')
source = json.loads(json.dumps(provenance))['skills']['humanizer']['files']['UPSTREAM.md']
if source['sourceSha256'] != hashlib.sha256(attribution.encode('utf-8')).hexdigest():
    errors.append('attribution sourceSha256 must equal its installed bytes')
if errors:
    raise SystemExit('\n'.join(errors))
PY
    then
      pass "68i: sync reads committed Git objects, renders host sections for Cursor, applies exact rewrites, keeps licenses, scripts, and attribution, and reports stale files and retired skills"
    else
      fail "68i: sync output, rendering, or provenance was incorrect"
    fi

    if "${CURSOR_HELPER}" validate >"${TMPDIR}/validate68i.out" 2>"${TMPDIR}/validate68i.err"; then
      pass "68i2: validation accepts the synced tree, including attribution files that name the source runtime"
    else
      fail "68i2: validation rejected the freshly synced tree: $(cat "${TMPDIR}/validate68i.err")"
    fi

    digest68_first="$(sync68_digest)"
    "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref HEAD >"${TMPDIR}/sync68b.out" 2>"${TMPDIR}/sync68b.err"
    [[ "${digest68_first}" == "$(sync68_digest)" ]] && pass "68j: repeated sync from the same commit is byte-for-byte deterministic" || fail "68j: repeated sync changed the output tree or provenance"

    git -C "${upstream68}" checkout -q -- packages/opencode-hive/skills/brainstorming/SKILL.md
    printf '%s\n' 'Replacement object guidance.' > "${upstream68}/packages/opencode-hive/skills/how/references/notes.md"
    git -C "${upstream68}" add .
    git -C "${upstream68}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm replacement
    replacement68="$(git -C "${upstream68}" rev-parse HEAD)"
    git -C "${upstream68}" replace "${commit68}" "${replacement68}"
    if "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref "${commit68}" >"${TMPDIR}/sync68-replace.out" 2>"${TMPDIR}/sync68-replace.err" &&
      grep -q 'Notes for how' "${REPO_FIXTURE}/.apm/cursor/skills/how/references/notes.md" &&
      ! grep -q 'Replacement object guidance' "${REPO_FIXTURE}/.apm/cursor/skills/how/references/notes.md" &&
      grep -q "${commit68}" "${REPO_FIXTURE}/${hive_skill_provenance_rel}"; then
      pass "68k: skill sync ignores Git replacement objects for commit and tree identity"
    else
      fail "68k: Git replacement object changed synced skill content or provenance"
    fi
    git -C "${upstream68}" replace -d "${commit68}" >/dev/null
    git -C "${upstream68}" reset -q --hard "${commit68}"

    redirected68="${TMPDIR}/redirected68"
    mkdir -p "${redirected68}/packages/opencode-hive/skills/how"
    printf '%s\n' 'Ambient GIT_DIR content must not be synced.' > "${redirected68}/packages/opencode-hive/skills/how/SKILL.md"
    cat > "${redirected68}/packages/opencode-hive/package.json" <<'JSON'
{
  "name": "oc-arkive",
  "version": "0.0.1",
  "repository": "https://wrong.example.test/redirected.git"
}
JSON
    git -C "${redirected68}" init -q
    git -C "${redirected68}" add .
    git -C "${redirected68}" -c user.name=Fixture -c user.email=fixture@example.test commit -qm redirected
    if GIT_DIR="${redirected68}/.git" "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref HEAD >"${TMPDIR}/sync68-git-dir.out" 2>"${TMPDIR}/sync68-git-dir.err" &&
      ! grep -q 'Ambient GIT_DIR content' "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md" &&
      grep -q "${commit68}" "${REPO_FIXTURE}/${hive_skill_provenance_rel}" &&
      grep -q 'https://example.test/agent-hive.git' "${REPO_FIXTURE}/${hive_skill_provenance_rel}"; then
      pass "68l: skill sync ignores ambient GIT_DIR repository redirection"
    else
      fail "68l: ambient GIT_DIR redirected synced skill content or provenance"
    fi

    skill68="${REPO_FIXTURE}/.apm/cursor/skills/verification"
    cp "${skill68}/SKILL.md" "${TMPDIR}/verification68.bak"
    printf '\nTampered.\n' >> "${skill68}/SKILL.md"
    if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/tamper68.out" 2>"${TMPDIR}/tamper68.err" &&
      grep -Eqi 'sha-?256' "${TMPDIR}/tamper68.err"; then
      pass "68m: installed file hash tampering is rejected when provenance is present"
    else
      fail "68m: hash tampering was accepted or returned the wrong error"
    fi
    cp "${TMPDIR}/verification68.bak" "${skill68}/SKILL.md"
    printf 'extra\n' > "${skill68}/EXTRA.md"
    if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/extra68.out" 2>"${TMPDIR}/extra68.err" &&
      grep -q 'EXTRA.md is not listed in provenance' "${TMPDIR}/extra68.err"; then
      pass "68m2: an unlisted file in an imported skill is rejected"
    else
      fail "68m2: unlisted file was accepted or returned the wrong error: $(cat "${TMPDIR}/extra68.err")"
    fi
    rm -f "${skill68}/EXTRA.md"
    mv "${skill68}/LICENSE.pstack" "${TMPDIR}/license68.bak" 2>/dev/null || mv "${skill68}/LICENSE" "${TMPDIR}/license68.bak"
    if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/missing68.out" 2>"${TMPDIR}/missing68.err" &&
      grep -q 'is listed in provenance but missing' "${TMPDIR}/missing68.err"; then
      pass "68m3: a missing licence or reference file is rejected"
    else
      fail "68m3: missing file was accepted or returned the wrong error: $(cat "${TMPDIR}/missing68.err")"
    fi
    mv "${TMPDIR}/license68.bak" "${skill68}/LICENSE" 2>/dev/null || true
    "${CURSOR_HELPER}" validate >/dev/null 2>&1 && pass "68m4: restored tree validates again" || fail "68m4: restored tree no longer validates"

    for mutation68 in unknown-host unclosed stray-close inline-marker residue residue-native-skill residue-hive residue-opencode residue-oc-arkive drift; do
      broken68="${TMPDIR}/broken68-${mutation68}"
      case "${mutation68}" in
        residue) expected68='native skill call' ;;
        residue-native-skill) expected68='OpenCode native skill reference' ;;
        residue-hive) expected68='Hive runtime name' ;;
        residue-opencode | residue-oc-arkive) expected68='OpenCode runtime name' ;;
        *) expected68='Cursor Hive skills sync failed' ;;
      esac
      mkdir -p "${broken68}"
      python3 "${TMPDIR}/make-upstream68.py" "${REPO_FIXTURE}/${hive_skill_sync_rel}" "${broken68}" "${mutation68}"
      digest68_before="$(sync68_digest)"
      if ! "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${broken68}" --ref HEAD >"${broken68}/out" 2>"${broken68}/err" \
        && grep -q 'Cursor Hive skills sync failed' "${broken68}/err" \
        && grep -q "${expected68}" "${broken68}/err" \
        && [[ "${digest68_before}" == "$(sync68_digest)" ]]; then
        pass "68r: sync rejects ${mutation68} before writing anything"
      else
        fail "68r: sync accepted ${mutation68} or wrote output before failing: $(cat "${broken68}/err")"
      fi
    done

    # Earlier provenance never grants deletion rights: a hostile or malformed
    # prior file must fail the sync before it touches the shared skill set, a
    # sentinel in .apm/skills, or a locally owned Cursor skill.
    mkdir -p "${REPO_FIXTURE}/.apm/skills/sentinel-shared" "${REPO_FIXTURE}/.apm/cursor/skills/local-user-skill"
    printf 'keep\n' > "${REPO_FIXTURE}/.apm/skills/sentinel-shared/SKILL.md"
    printf 'keep\n' > "${REPO_FIXTURE}/.apm/cursor/skills/local-user-skill/SKILL.md"
    provenance68="${REPO_FIXTURE}/${hive_skill_provenance_rel}"
    cp "${provenance68}" "${TMPDIR}/provenance68.good"
    tree68_digest() { python3 "${TMPDIR}/tree-digest68.py" "${REPO_FIXTURE}/.apm"; python3 "${TMPDIR}/tree-digest68.py" "${REPO_FIXTURE}/vendor"; }
    for case68 in traversal absolute nested uppercase empty-name stop-design-slop local-user-skill not-object skills-missing skills-list invalid-json; do
      python3 - "${provenance68}" "${case68}" <<'PY'
import json
import sys
from pathlib import Path

path, case = Path(sys.argv[1]), sys.argv[2]
names = {
    'traversal': '../../skills',
    'absolute': '/tmp/outside-skill',
    'nested': 'writing-policy/../local-user-skill',
    'uppercase': 'Writing_Policy',
    'empty-name': '',
    'stop-design-slop': 'stop-design-slop',
    'local-user-skill': 'local-user-skill',
}
if case in names:
    text = json.dumps({'skills': {names[case]: {}}})
elif case == 'not-object':
    text = '[]'
elif case == 'skills-missing':
    text = '{}'
elif case == 'skills-list':
    text = '{"skills": ["writing-policy"]}'
else:
    text = '{'
path.write_text(text, encoding='utf-8')
PY
      tree68_before="$(tree68_digest)"
      if ! "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref HEAD >"${TMPDIR}/prev68-${case68}.out" 2>"${TMPDIR}/prev68-${case68}.err" \
        && grep -q 'Cursor Hive skills sync failed' "${TMPDIR}/prev68-${case68}.err" \
        && [[ "${tree68_before}" == "$(tree68_digest)" ]] \
        && [[ -f "${REPO_FIXTURE}/.apm/skills/sentinel-shared/SKILL.md" && -f "${REPO_FIXTURE}/.apm/cursor/skills/local-user-skill/SKILL.md" && -f "${REPO_FIXTURE}/.apm/cursor/skills/stop-design-slop/SKILL.md" ]]; then
        pass "68s0: prior provenance ${case68} fails the sync without touching any file"
      else
        fail "68s0: prior provenance ${case68} was accepted or changed files: $(cat "${TMPDIR}/prev68-${case68}.err")"
      fi
    done
    # Absent or valid prior metadata still syncs, removes only the retired skill, and leaves local skills alone.
    mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/writing-policy"
    printf 'retired\n' > "${REPO_FIXTURE}/.apm/cursor/skills/writing-policy/SKILL.md"
    rm -f "${provenance68}"
    if "${REPO_FIXTURE}/${hive_skill_sync_rel}" --source-repo "${upstream68}" --ref HEAD >"${TMPDIR}/prev68-first.out" 2>"${TMPDIR}/prev68-first.err" \
      && [[ ! -e "${REPO_FIXTURE}/.apm/cursor/skills/writing-policy" && -f "${REPO_FIXTURE}/.apm/skills/sentinel-shared/SKILL.md" && -f "${REPO_FIXTURE}/.apm/cursor/skills/local-user-skill/SKILL.md" ]]; then
      pass "68s1: first sync without provenance succeeds, removes only the retired skill, and keeps local skills"
    else
      fail "68s1: first sync without provenance failed or removed the wrong directory: $(cat "${TMPDIR}/prev68-first.err")"
    fi
  else
    fail "68i: skill sync failed: $(cat "${TMPDIR}/sync68.err")"
    fail "68k: Git replacement behavior unavailable"
    fail "68l: ambient GIT_DIR behavior unavailable"
    fail "68m: provenance tamper check unavailable"
  fi
else
  fail "68i: skill sync behavior unavailable"
  fail "68k: Git replacement behavior unavailable"
  fail "68l: ambient GIT_DIR behavior unavailable"
  fail "68m: provenance tamper check unavailable"
fi
build_fixture

if python3 - "${BASELINE_PWD}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
old_cursor = '| Implementing a feature or bugfix | `test-driven-development` and `consolidate-test-suites` |'
old_profile = '| Implementing a feature or bugfix in code | `test-driven-development` and `consolidate-test-suites` |'
selected_tdd = 'Loading `test-driven-development` means TDD was selected.'
errors = []
cursor_rules = (root / '.apm/cursor/rules/default-agent.md').read_text(encoding='utf-8')
if old_cursor in cursor_rules:
    errors.append('default-agent.md still auto-loads TDD on every feature/bugfix')
if 'consolidate-test-suites' in cursor_rules:
    errors.append('default-agent.md still mentions consolidate-test-suites')
if 'root-cause-finder' in cursor_rules:
    errors.append('default-agent.md still mentions root-cause-finder')
if selected_tdd not in cursor_rules:
    errors.append('default-agent.md must load TDD only when TDD is selected')
for relative in (
    'profiles/agents/shared.md',
    'profiles/agents/shared-context-improved.md',
    'profiles/agents/personal-default.md',
    'profiles/agents/personal-context-improved.md',
):
    text = (root / relative).read_text(encoding='utf-8')
    if old_profile in text:
        errors.append(f'{relative} still auto-loads TDD on every feature/bugfix')
    if 'consolidate-test-suites' in text:
        errors.append(f'{relative} still mentions consolidate-test-suites')
    if '| Starting isolated feature work' in text or '| Starting isolated feature work or executing an approved implementation plan |' in text:
        errors.append(f'{relative} still loads using-git-worktrees for isolated work')
    if selected_tdd not in text:
        errors.append(f'{relative} must load TDD only when TDD is selected')
tdd = (root / '.apm/cursor/skills/test-driven-development/SKILL.md').read_text(encoding='utf-8')
if not tdd.startswith('---\n'):
    errors.append('TDD skill missing YAML frontmatter')
else:
    closing = tdd.find('\n---\n', 4)
    if closing < 0:
        errors.append('TDD skill frontmatter is not closed')
    else:
        description = None
        for line in tdd[4:closing].splitlines():
            if line.startswith('description:'):
                description = line.split(':', 1)[1].strip()
                break
        if not description:
            errors.append('TDD skill frontmatter has no description')
        else:
            if 'TDD has been selected' not in description:
                errors.append('TDD skill description must say TDD has been selected')
            if 'Use when implementing features' in description:
                errors.append('TDD skill description still uses feature auto-load wording')
if 'Name the invariant' not in tdd:
    errors.append('TDD skill RED must name the invariant and owning layer')
if 'deterministic' not in tdd or 'durable contract value' not in tdd:
    errors.append('TDD skill standalone regression rule must require a deterministic durable contract')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "68o: TDD is loaded only when selected; skill description is not auto-load wording"
else
  fail "68o: TDD auto-trigger wording was not updated"
fi

# Commit authority settled before placement follows a lane through recovery,
# result identity, integration, and closure: a commit-authorized lane returns a
# verified commit, a lane that must not commit returns its dirty candidate.
if python3 - "${BASELINE_PWD}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]) / '.apm/cursor'
orchestration = ' '.join((root / 'skills/orchestrating-ad-hoc-work/SKILL.md').read_text(encoding='utf-8').split())
forager = ' '.join((root / 'agents/forager.md').read_text(encoding='utf-8').split())
delegation = ' '.join((root / 'skills/subagent-delegation/SKILL.md').read_text(encoding='utf-8').split())
finishing = ' '.join((root / 'skills/finishing-a-development-branch/SKILL.md').read_text(encoding='utf-8').split())
errors = []
for label, text, terms in (
    ('orchestration (commit-authorized lane)', orchestration, (
        'With commit authority, merge the pinned commit into the clean integration checkout',
        'a commit it verified in its own session',
        'with commit authority that is a committed, integrated predecessor',
    )),
    ('orchestration (lane that must not commit)', orchestration, (
        'never gains it from a failure, a retry, or a successor',
        'creates no commit and returns the base identity, the attributable changed and untracked files, and the checks it ran against that dirty tree',
        'never describes HEAD as covering the uncommitted result',
        'apply only the attributable changed and untracked files of the verified dirty candidate',
        'when it holds no conflicting user work',
        "the result to return under the lane's original commit authority",
        'or the applied uncommitted change set',
    )),
    ('forager', forager, (
        'any assignment that says not to commit',
        'never claim HEAD covers the dirty result',
        'Without commit authority, the base branch and commit, the changed and untracked files attributable to this assignment',
    )),
    ('delegation', delegation, ('A child without commit authority returns the base identity',)),
    ('finishing', finishing, ('an uncommitted change set applied to the destination',)),
):
    for term in terms:
        if term not in text:
            errors.append(f'{label} is missing: {term}')
for stale in ('verified, committed, integrated predecessor', 'and the commit to return', 'returns a commit it verified in its own session: a new commit, or the existing candidate when it needed no edits.\n'):
    if stale in orchestration:
        errors.append(f'orchestration still requires a commit unconditionally: {stale!r}')
for sentence in re.split(r'(?<=[.!?]) ', orchestration):
    if ('pinned commit' in sentence or 'returns a commit' in sentence) and 'commit authority' not in sentence and 'Merge the pinned' not in sentence and 'With commit authority' not in sentence:
        errors.append(f'unconditional commit requirement: {sentence}')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "68o2: commit authority follows a lane through recovery, result identity, integration, and closure"
else
  fail "68o2: orchestration, forager, delegation, or finishing guidance contradicts no-commit lanes"
fi

td68p="${TMPDIR}/cursor68p"
mkdir -p "${td68p}"
sandbox_agents_skills
for hive_bundled in ${HIVE_BUNDLED_NAMES}; do
  mkdir -p "${AGENTS_SKILLS_DIR}/${hive_bundled}"
  printf 'stale agents %s\n' "${hive_bundled}" > "${AGENTS_SKILLS_DIR}/${hive_bundled}/SKILL.md"
done
install68p_status=0
env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td68p}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install >"${TMPDIR}/install68p.out" 2>"${TMPDIR}/install68p.err" || install68p_status=$?
if [[ "${install68p_status}" -eq 1 ]]; then
  if python3 - "${BASELINE_PWD}" "${td68p}" "${AGENTS_SKILLS_DIR}" "${TMPDIR}/install68p.err" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
installed = Path(sys.argv[2])
agents = Path(sys.argv[3])
err = Path(sys.argv[4]).read_text(encoding='utf-8')
provenance = json.loads((root / 'vendor/oc-arkive/cursor-skills/provenance.json').read_text(encoding='utf-8'))
errors = []
for name, entry in provenance['skills'].items():
    installed_directory = installed / 'skills' / name
    actual_files = sorted(path.relative_to(installed_directory).as_posix() for path in installed_directory.rglob('*') if path.is_file())
    if actual_files != sorted(entry['files']):
        errors.append(f'installed {name} tree differs from provenance: {sorted(set(actual_files) ^ set(entry["files"]))}')
        continue
    for relative, hashes in entry['files'].items():
        target = installed_directory / relative
        if target.is_symlink() or not target.is_file():
            errors.append(f'installed {name}/{relative} must be a regular file')
            continue
        actual = hashlib.sha256(target.read_bytes()).hexdigest()
        if actual != hashes['installedSha256']:
            errors.append(f'installed {name}/{relative} sha256 is {actual}, expected {hashes["installedSha256"]}')
# The imported skills are covered by the provenance loop above; only the locally owned stop-design-slop needs its own byte check.
local_files = ('SKILL.md', 'assets/salience-hierarchy.svg', 'examples/README.md', 'references/review-rubric.md', 'scripts/audit_ui.py', 'scripts/contrast_check.py', 'LICENSE.impeccable')
for relative in local_files:
    source = root / '.apm/cursor/skills/stop-design-slop' / relative
    target = installed / 'skills/stop-design-slop' / relative
    if target.is_symlink() or not target.is_file():
        errors.append(f'installed stop-design-slop/{relative} must be a regular file')
    elif source.read_bytes() != target.read_bytes():
        errors.append(f'installed stop-design-slop/{relative} does not match the Cursor copy')
for name in ('humanizer', 'stop-design-slop', 'stop-slop', 'unslop', 'writing-for-agents', 'writing-for-humans'):
    stale = agents / name / 'SKILL.md'
    if not stale.is_file() or stale.read_text(encoding='utf-8') != f'stale agents {name}\n':
        errors.append(f'{name} agents copy was not left in place')
    line = f'decision needed: conflict: {agents / name} is outside the managed install path {installed / "skills" / name}; left in place'
    if line not in err:
        errors.append(f'missing decision line for {agents / name}')
if (installed / 'skills' / 'writing-policy').exists():
    errors.append('retired writing-policy was installed')
if errors:
    raise SystemExit('\n'.join(errors))
PY
  then
    pass "68p: temp Cursor install of vendored Hive skills matches provenance installedSha256"
  else
    fail "68p: temp Cursor install did not match provenance installedSha256 or missed a decision line"
  fi
else
  fail "68p: temp Cursor install from real worktree helper exited ${install68p_status}: $(cat "${TMPDIR}/install68p.err")"
fi

printf '\n=== 68q. Cursor installer leaves leftover retired skills for a decision ===\n'
td68q="${TMPDIR}/cursor68q"
mkdir -p "${td68q}/skills/consolidate-test-suites" "${td68q}/skills/root-cause-finder"
printf '%s\n' 'stale leftover consolidate-test-suites' > "${td68q}/skills/consolidate-test-suites/SKILL.md"
printf '%s\n' 'stale leftover root-cause-finder' > "${td68q}/skills/root-cause-finder/SKILL.md"
sandbox_agents_skills
dry68q_status=0
env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td68q}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install --dry-run >"${TMPDIR}/dry68q.out" 2>"${TMPDIR}/dry68q.err" || dry68q_status=$?
if [[ "${dry68q_status}" -eq 1 ]]; then
  grep -Fqx "decision needed: unversioned: ${td68q}/skills/consolidate-test-suites is not packaged by this install; left in place" "${TMPDIR}/dry68q.err" && pass "68q-a: dry-run reports leftover consolidate-test-suites" || fail "68q-b: dry-run omitted leftover consolidate-test-suites: $(cat "${TMPDIR}/dry68q.err")"
  grep -Fqx "decision needed: unversioned: ${td68q}/skills/root-cause-finder is not packaged by this install; left in place" "${TMPDIR}/dry68q.err" && pass "68q-c: dry-run reports leftover root-cause-finder" || fail "68q-d: dry-run omitted leftover root-cause-finder: $(cat "${TMPDIR}/dry68q.err")"
  grep -Fqx 'stale leftover consolidate-test-suites' "${td68q}/skills/consolidate-test-suites/SKILL.md" && grep -Fqx 'stale leftover root-cause-finder' "${td68q}/skills/root-cause-finder/SKILL.md" && pass "68q-c2: dry-run left retired skills in place" || fail "68q-d2: dry-run changed retired skills"
else
  fail "68q-a: leftover Cursor retired-skill dry-run exited ${dry68q_status}: $(cat "${TMPDIR}/dry68q.err")"
fi
install68q_status=0
env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td68q}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install >"${TMPDIR}/install68q.out" 2>"${TMPDIR}/install68q.err" || install68q_status=$?
if [[ "${install68q_status}" -eq 1 ]]; then
  grep -Fqx 'stale leftover consolidate-test-suites' "${td68q}/skills/consolidate-test-suites/SKILL.md" && pass "68q-e: leftover Cursor consolidate-test-suites left in place" || fail "68q-f: leftover Cursor consolidate-test-suites was removed"
  grep -Fqx 'stale leftover root-cause-finder' "${td68q}/skills/root-cause-finder/SKILL.md" && pass "68q-g: leftover Cursor root-cause-finder left in place" || fail "68q-h: leftover Cursor root-cause-finder was removed"
  [[ -f "${td68q}/skills/using-git-worktrees/SKILL.md" ]] && pass "68q-i: Cursor using-git-worktrees still installed" || fail "68q-j: Cursor using-git-worktrees missing"
  [[ -f "${td68q}/skills/finishing-a-development-branch/SKILL.md" ]] && pass "68q-k: Cursor finishing-a-development-branch still installed" || fail "68q-l: Cursor finishing-a-development-branch missing"
  grep -Fqx "decision needed: unversioned: ${td68q}/skills/consolidate-test-suites is not packaged by this install; left in place" "${TMPDIR}/install68q.err" && pass "68q-m: install reports leftover consolidate-test-suites" || fail "68q-n: install omitted leftover consolidate-test-suites"
  grep -Fqx "decision needed: unversioned: ${td68q}/skills/root-cause-finder is not packaged by this install; left in place" "${TMPDIR}/install68q.err" && pass "68q-o: install reports leftover root-cause-finder" || fail "68q-p: install omitted leftover root-cause-finder"
  if ls "${td68q}/.backup/"*"/skills/consolidate-test-suites" >/dev/null 2>&1 || ls "${td68q}/.backup/"*"/skills/root-cause-finder" >/dev/null 2>&1; then
    fail "68q-q: retired Cursor skills were backed up"
  else
    pass "68q-r: retired Cursor skills were not backed up"
  fi
else
  fail "68q-e: leftover Cursor retired-skill install exited ${install68q_status}: $(cat "${TMPDIR}/install68q.err")"
fi

# ---------------------------------------------------------------------------
# 68s. Delivered prompts are usable without Agent Hive
# ---------------------------------------------------------------------------
printf '\n=== 68s. Delivered prompts reject Hive runtime syntax and broken references ===\n'

# Each case mutates one delivered asset in a fresh fixture, then expects validation to fail naming the cause.
expect_validate_fail() {
  local label="$1" expected="$2" log="${TMPDIR}/validate-leak.err"
  if ! "${CURSOR_HELPER}" validate >"${TMPDIR}/validate-leak.out" 2>"${log}" && grep -Fq -- "${expected}" "${log}"; then
    pass "68s: ${label}"
  else
    fail "68s: ${label}: $(cat "${log}")"
  fi
  build_fixture
}

build_fixture
printf '\n<!-- hive-host opencode-v1 -->\nV1\n<!-- /hive-host -->\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "skill with a leaked host section marker is rejected" "Hive host section marker"

printf '\nLoad it with skill({ name: "verification" }).\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "skill with a native skill call is rejected" "native skill call"

printf '\nCall hive_status first.\n' >> "${REPO_FIXTURE}/.apm/cursor/agents/forager.md"
expect_validate_fail "agent naming a Hive tool is rejected" "Hive tool name"

printf '\nDispatch hive-builder.\n' >> "${REPO_FIXTURE}/.apm/cursor/commands/grill.md"
expect_validate_fail "command naming a Hive role is rejected" "Hive role identifier"

printf '\nRead .hive/features first.\n' >> "${REPO_FIXTURE}/.apm/cursor/rules/default-agent.md"
expect_validate_fail "Rules naming Hive state paths are rejected" "Hive state path"

printf '\nUse task(subagent_type) here.\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "OpenCode task call syntax is rejected" "OpenCode-only tool call"

printf '\nSee writing-plans for the plan.\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "reference to a Hive skill Cursor does not ship is rejected" "references skill writing-plans"

printf '\nLoad writing-policy first.\n' >> "${REPO_FIXTURE}/.apm/cursor/agents/scout.md"
expect_validate_fail "reference to the retired writing-policy is rejected" "references skill writing-policy"

mkdir -p "${REPO_FIXTURE}/.apm/cursor/skills/how/references"
printf '\nSee [notes](references/missing.md).\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "link to a missing skill file is rejected" "links to a missing file"

printf '\nSee [outside](../humanizer/SKILL.md).\n' >> "${REPO_FIXTURE}/.apm/cursor/skills/how/SKILL.md"
expect_validate_fail "link out of its skill is rejected" "links outside its skill"

sed -i 's/^readonly: true$/readonly: false/' "${REPO_FIXTURE}/.apm/cursor/agents/scout.md"
expect_validate_fail "read-only role with readonly false is rejected" "readonly must be true"

sed -i 's/^readonly: false$/readonly: true/' "${REPO_FIXTURE}/.apm/cursor/agents/forager.md"
expect_validate_fail "write-capable forager with readonly true is rejected" "readonly must be false"

python3 - "${REPO_FIXTURE}/.apm/cursor/agents/code-reviewer.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
path.write_text(path.read_text(encoding='utf-8').replace("Apply the Engineering Judgment section appended to this prompt within this role's current scope and finding bar.", "Apply Engineering Judgment from active Cursor Rules within this role's current scope and finding bar."), encoding='utf-8')
PY
expect_validate_fail "agent that relies on Rules inheritance is rejected" "appended Engineering Judgment guidance exactly once"

printf '\n## Engineering Judgment\n\nCopied by hand.\n' >> "${REPO_FIXTURE}/.apm/cursor/agents/plan-reviewer.md"
expect_validate_fail "agent embedding the snapshot is rejected" "must not embed Engineering Judgment"

cp "${REPO_FIXTURE}/.apm/prompts/planning-prompt.prompt.md" "${REPO_FIXTURE}/.apm/cursor/commands/planning-prompt.md"
expect_validate_fail "shared command duplicated under Cursor commands is rejected" "stale duplicate commands/planning-prompt.md"

rm -f "${REPO_FIXTURE}/.apm/prompts/interview-drill-down.prompt.md"
expect_validate_fail "shared command without its canonical source is rejected" "missing canonical shared command source"

# Installers agree on the Hive-bundled and retired classification.
if python3 - "${BASELINE_PWD}" <<'PY'
import importlib.util
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])

def array(path, name):
    match = re.search(rf'^{name}=\(\n(.*?)\n\)', (root / path).read_text(encoding='utf-8'), re.MULTILINE | re.DOTALL)
    if not match:
        raise SystemExit(f'{path} has no {name} array')
    return {line.strip() for line in match.group(1).splitlines() if line.strip() and not line.strip().startswith('#')}

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('cursor_hive_skills_sync', root / 'scripts/sync-cursor-hive-skills.py')
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)
errors = []
cursor_bundled = array('scripts/cursor-assets.sh', 'HIVE_BUNDLED_SKILLS')
opencode_bundled = array('scripts/install-profile.sh', 'HIVE_BUNDLED_SKILLS')
# The Cursor bundle is pinned to a newer Agent Hive source than the OpenCode baseline, so the two sets differ on purpose.
if cursor_bundled != {'humanizer', 'stop-design-slop', 'stop-slop', 'unslop', 'writing-for-agents', 'writing-for-humans'}:
    errors.append(f'Cursor Hive-bundled skills drifted: {sorted(cursor_bundled)}')
if opencode_bundled != {'humanizer', 'stop-design-slop', 'stop-slop', 'writing-for-humans', 'writing-policy'}:
    errors.append(f'OpenCode Hive-bundled skills must match the oc-arkive v3.0.0 baseline: {sorted(opencode_bundled)}')
if 'writing-policy' in cursor_bundled:
    errors.append('retired writing-policy must not be classified as Hive-bundled for Cursor')
if 'writing-policy' not in array('scripts/cursor-assets.sh', 'RETIRED_SKILLS') or 'writing-policy' not in array('scripts/cursor-assets.sh', 'RETIRED_AGENTS_SKILLS'):
    errors.append('cursor-assets.sh must report a leftover writing-policy in the Cursor and agents skills directories')
cursor_skills = array('scripts/cursor-assets.sh', 'SKILLS')
if not set(sync.IMPORTED_SKILLS) <= cursor_skills:
    errors.append(f'imported skills missing from the Cursor install list: {sorted(set(sync.IMPORTED_SKILLS) - cursor_skills)}')
if set(sync.RETIRED_SKILLS) & cursor_skills:
    errors.append('a retired skill is still in the Cursor install list')
if not cursor_bundled <= (cursor_skills):
    errors.append('every Hive-bundled skill must be installed for Cursor')
shared_commands = array('scripts/cursor-assets.sh', 'SHARED_COMMANDS')
prompts = {path.name[:-len('.prompt.md')] for path in (root / '.apm/prompts').glob('*.prompt.md')}
if shared_commands != prompts:
    errors.append(f'shared commands {sorted(shared_commands)} differ from .apm/prompts {sorted(prompts)}')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "68t: each installer classifies Hive-bundled and retired skills for its own baseline, and sync, install list, and shared commands agree"
else
  fail "68t: installer classification, sync list, or shared command list drifted"
fi

# Shared prompts keep argument handling that works in OpenCode and Cursor.
if python3 - "${BASELINE_PWD}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []
for name in ('planning-prompt', 'interview-drill-down', 'reflect'):
    text = (root / f'.apm/prompts/{name}.prompt.md').read_text(encoding='utf-8')
    if '$ARGUMENTS' not in text or 'interpolated' not in text:
        errors.append(f'{name} must treat $ARGUMENTS as input only when it was interpolated')
    if 'literal' not in text:
        errors.append(f'{name} must handle a literal $ARGUMENTS token')
    if '`question` tool' in text:
        errors.append(f'{name} names an OpenCode-only question tool')
    if (root / f'.apm/cursor/commands/{name}.md').exists():
        errors.append(f'{name} has a divergent Cursor copy')
if errors:
    raise SystemExit('\n'.join(errors))
PY
then
  pass "68u: shared prompts handle interpolated and literal arguments and have no divergent Cursor copy"
else
  fail "68u: shared prompt argument handling or single-source contract is wrong"
fi

# ---------------------------------------------------------------------------
# 69. OpenCode installer upserts shared Atlassian skills and preserves unmanaged skills
# ---------------------------------------------------------------------------
printf '\n=== 69. OpenCode installer upserts shared Atlassian skills and preserves unmanaged skills ===\n'
build_fixture
sandbox_agents_skills
td69="${TMPDIR}/test69"
for shared69 in connecting-atlassian-tools managing-work-in-jira working-with-atlassian; do
  mkdir -p "${AGENTS_SKILLS_DIR}/${shared69}"
  printf 'old managed skill: %s\n' "${shared69}" > "${AGENTS_SKILLS_DIR}/${shared69}/SKILL.md"
done
mkdir -p "${AGENTS_SKILLS_DIR}/user-managed"
printf 'user-managed-sentinel\n' > "${AGENTS_SKILLS_DIR}/user-managed/SKILL.md"
mkdir -p "${td69}/skills/impeccable" "${td69}/skills/context-mode" "${td69}/skills/cymbal" "${td69}/skills/brainstorming" "${td69}/skills/ivan-writing" \
  "${td69}/skills/using-git-worktrees" "${td69}/skills/finishing-a-development-branch" "${td69}/skills/consolidate-test-suites" "${td69}/skills/root-cause-finder"
printf '%s\n' 'impeccable-sentinel-keep' > "${td69}/skills/impeccable/SENTINEL"
printf '%s\n' 'stale-opencode-local' > "${td69}/skills/context-mode/SKILL.md"
printf '%s\n' 'stale leftover cymbal' > "${td69}/skills/cymbal/SKILL.md"
printf '%s\n' 'stale leftover brainstorming' > "${td69}/skills/brainstorming/SKILL.md"
printf '%s\n' 'unowned-ivan-writing' > "${td69}/skills/ivan-writing/SKILL.md"
printf '%s\n' 'stale leftover using-git-worktrees' > "${td69}/skills/using-git-worktrees/SKILL.md"
printf '%s\n' 'stale leftover finishing-a-development-branch' > "${td69}/skills/finishing-a-development-branch/SKILL.md"
printf '%s\n' 'stale leftover consolidate-test-suites' > "${td69}/skills/consolidate-test-suites/SKILL.md"
printf '%s\n' 'stale leftover root-cause-finder' > "${td69}/skills/root-cause-finder/SKILL.md"
printf '%s\n' 'keep-file' > "${td69}/skills/keep.txt"
install69_status=0
OPENCODE_CONFIG_DIR="${td69}" OPENCODE_AGENTS_PROFILE=shared bash "${INSTALL_HELPER}" --apply 2>"${td69}/err" || install69_status=$?
[[ "${install69_status}" -eq 1 ]] && pass "69a: shared install exits 1 after reporting decisions" || fail "69b: shared install exited ${install69_status}: $(cat "${td69}/err")"
for shared69 in connecting-atlassian-tools managing-work-in-jira working-with-atlassian; do
  if cmp -s "${REPO_FIXTURE}/.apm/skills/${shared69}/SKILL.md" "${AGENTS_SKILLS_DIR}/${shared69}/SKILL.md" \
    && grep -Fqx "old managed skill: ${shared69}" "${td69}/.backup/"*/"agents-skills/${shared69}/SKILL.md" \
    && [[ ! -e "${td69}/skills/${shared69}" && ! -L "${td69}/skills/${shared69}" ]]; then
    pass "69a: ${shared69} replaced in agents dir, backed up, and left out of OpenCode skills"
  else
    fail "69b: ${shared69} was not upserted into the agents dir"
  fi
done
if cmp -s "${REPO_FIXTURE}/.apm/skills/working-with-atlassian/references/jql-essentials.md" "${AGENTS_SKILLS_DIR}/working-with-atlassian/references/jql-essentials.md"; then
  pass "69a2: working-with-atlassian reference installed with the packaged skill"
else
  fail "69b2: working-with-atlassian reference missing or stale"
fi
grep -Fqx 'user-managed-sentinel' "${AGENTS_SKILLS_DIR}/user-managed/SKILL.md" && pass "69a: unrelated shared skill preserved" || fail "69b: unrelated shared skill changed"
if grep -Fqx 'impeccable-sentinel-keep' "${td69}/skills/impeccable/SENTINEL"; then
  pass "69c: unmanaged impeccable survived"
else
  fail "69d: unmanaged impeccable was deleted or changed"
fi
grep -Fqx 'stale-opencode-local' "${td69}/skills/context-mode/SKILL.md" \
  && grep -Fqx "decision needed: unversioned: ${td69}/skills/context-mode is not packaged by this install; left in place" "${td69}/err" \
  && pass "69e: stale context-mode left in place as unversioned" || fail "69f: stale context-mode was removed or not reported"
grep -Fqx 'stale leftover cymbal' "${td69}/skills/cymbal/SKILL.md" \
  && grep -Fqx "decision needed: conflict: ${td69}/skills/cymbal is outside the managed install path ${AGENTS_SKILLS_DIR}/cymbal; left in place" "${td69}/err" \
  && pass "69g: leftover shared cymbal left in OpenCode skills" || fail "69h: leftover shared cymbal was removed or not reported"
cmp -s "${REPO_FIXTURE}/.apm/skills/cymbal/SKILL.md" "${AGENTS_SKILLS_DIR}/cymbal/SKILL.md" && pass "69i: shared cymbal installed into agents dir" || fail "69j: shared cymbal missing or wrong in agents dir"
grep -Fqx 'stale leftover brainstorming' "${td69}/skills/brainstorming/SKILL.md" \
  && grep -Fqx "decision needed: conflict: ${td69}/skills/brainstorming is outside the managed install path Hive materialization; left in place" "${td69}/err" \
  && pass "69k: leftover Hive brainstorming left in place" || fail "69l: leftover Hive brainstorming was removed or not reported"
retired69_missing=""
for skill69r in using-git-worktrees finishing-a-development-branch consolidate-test-suites root-cause-finder context-mode; do
  if ! grep -Fqx "stale leftover ${skill69r}" "${td69}/skills/${skill69r}/SKILL.md" \
    && ! grep -Fqx 'stale-opencode-local' "${td69}/skills/${skill69r}/SKILL.md"; then
    retired69_missing="${retired69_missing} ${skill69r}"
  fi
  if ! grep -Fqx "decision needed: unversioned: ${td69}/skills/${skill69r} is not packaged by this install; left in place" "${td69}/err"; then
    retired69_missing="${retired69_missing} ${skill69r}-line"
  fi
done
[[ -z "${retired69_missing}" ]] && pass "69k2: leftover retired OpenCode workflow skills left in place and reported" || fail "69l2: leftover retired OpenCode workflow skills missing or unreported:${retired69_missing}"
grep -Fqx 'unowned-ivan-writing' "${td69}/skills/ivan-writing/SKILL.md" && pass "69m: unowned ivan-writing preserved on shared install" || fail "69n: unowned ivan-writing was stripped on shared install"
grep -Fqx 'keep-file' "${td69}/skills/keep.txt" && pass "69o: unmanaged skills file survived" || fail "69p: unmanaged skills file was deleted"
missing69=""
for skill69 in writing-skills; do
  if [[ ! -f "${td69}/skills/${skill69}/SKILL.md" ]]; then
    missing69="${missing69} ${skill69}"
  fi
done
[[ -z "${missing69}" ]] && pass "69q: OpenCode-local writing-skills present" || fail "69r: missing OpenCode-local skills:${missing69}"
ls "${td69}/.backup/"*"/skills/impeccable/SENTINEL" >/dev/null 2>&1 && pass "69s: whole-skills backup includes unmanaged skill" || fail "69t: no whole-skills backup of unmanaged skill"

printf '\n=== 69b. Personal OpenCode install leaves leftover ivan-writing for a decision ===\n'
build_fixture
sandbox_agents_skills
td69b="${TMPDIR}/test69b"
mkdir -p "${td69b}/skills/ivan-writing" "${td69b}/skills/keep-me"
printf '%s\n' 'stale leftover ivan-writing' > "${td69b}/skills/ivan-writing/SKILL.md"
printf '%s\n' 'keep-me-sentinel' > "${td69b}/skills/keep-me/file.txt"
install69b_status=0
OPENCODE_CONFIG_DIR="${td69b}" OPENCODE_AGENTS_PROFILE=personal-default bash "${INSTALL_HELPER}" --apply 2>"${td69b}/err" || install69b_status=$?
[[ "${install69b_status}" -eq 1 ]] && pass "69b-a: personal install exits 1 after reporting the leftover" || fail "69b-b: personal install exited ${install69b_status}: $(cat "${td69b}/err")"
grep -Fqx 'stale leftover ivan-writing' "${td69b}/skills/ivan-writing/SKILL.md" \
  && grep -Fqx "decision needed: conflict: ${td69b}/skills/ivan-writing is outside the managed install path ${AGENTS_SKILLS_DIR}/ivan-writing; left in place" "${td69b}/err" \
  && pass "69b-c: leftover ivan-writing left in OpenCode skills" || fail "69b-d: leftover ivan-writing was removed or not reported"
[[ -f "${AGENTS_SKILLS_DIR}/ivan-writing/SKILL.md" ]] && pass "69b-e: ivan-writing installed to agents dir" || fail "69b-f: ivan-writing missing from agents dir"
grep -Fqx 'keep-me-sentinel' "${td69b}/skills/keep-me/file.txt" && pass "69b-g: unmanaged skill preserved on personal install" || fail "69b-h: unmanaged skill removed on personal install"
if grep -F 'keep-me' "${td69b}/err" | grep -F 'decision needed:' >/dev/null; then
  fail "69b-i: unmanaged skill was reported"
else
  pass "69b-j: unmanaged skill was not reported"
fi

printf '\n=== 69c. Installers upsert shared Atlassian skills, including a dangling symlink ===\n'
# working-with-atlassian and managing-work-in-jira are directories;
# connecting-atlassian-tools is a dangling symlink that -e alone would miss.
seed_atlassian_sentinels() {
  local dir="$1" name
  for name in managing-work-in-jira working-with-atlassian; do
    mkdir -p "${dir}/${name}"
    printf 'old managed skill: %s\n' "${name}" > "${dir}/${name}/SKILL.md"
  done
  ln -s "${dir}/missing-target" "${dir}/connecting-atlassian-tools"
  mkdir -p "${dir}/user-managed"
  printf 'user-managed-sentinel\n' > "${dir}/user-managed/SKILL.md"
}
check_upserted_atlassian() {
  local label="$1" backup_root="$2" harness_skills="$3" source_root="$4" name
  for name in connecting-atlassian-tools managing-work-in-jira working-with-atlassian; do
    if cmp -s "${source_root}/.apm/skills/${name}/SKILL.md" "${AGENTS_SKILLS_DIR}/${name}/SKILL.md" \
      && [[ ! -e "${harness_skills}/${name}" && ! -L "${harness_skills}/${name}" ]]; then
      pass "${label}: ${name} installed into agents dir"
    else
      fail "${label}: ${name} missing from agents dir or copied into harness skills"
    fi
  done
  if cmp -s "${source_root}/.apm/skills/working-with-atlassian/references/jql-essentials.md" "${AGENTS_SKILLS_DIR}/working-with-atlassian/references/jql-essentials.md"; then
    pass "${label}: working-with-atlassian reference installed"
  else
    fail "${label}: working-with-atlassian reference missing or stale"
  fi
  grep -Fqx 'old managed skill: working-with-atlassian' "${backup_root}/agents-skills/working-with-atlassian/SKILL.md" \
    && pass "${label}: directory backed up before replacement" || fail "${label}: directory backup missing"
  [[ -L "${backup_root}/agents-skills/connecting-atlassian-tools" ]] \
    && pass "${label}: dangling symlink backed up as a symlink" || fail "${label}: dangling symlink backup missing"
  [[ ! -L "${AGENTS_SKILLS_DIR}/connecting-atlassian-tools" && -f "${AGENTS_SKILLS_DIR}/connecting-atlassian-tools/SKILL.md" ]] \
    && pass "${label}: dangling symlink replaced by packaged skill" || fail "${label}: dangling symlink was not replaced"
  grep -Fqx 'user-managed-sentinel' "${AGENTS_SKILLS_DIR}/user-managed/SKILL.md" \
    && pass "${label}: unrelated shared skill preserved" || fail "${label}: unrelated shared skill changed"
}

build_fixture
sandbox_agents_skills
td69c="${TMPDIR}/test69c-opencode"
seed_atlassian_sentinels "${AGENTS_SKILLS_DIR}"
if OPENCODE_CONFIG_DIR="${td69c}" bash "${INSTALL_HELPER}" --apply >/dev/null 2>"${TMPDIR}/test69c.err"; then
  check_upserted_atlassian "69c-opencode" "$(ls -d "${td69c}/.backup/"* | head -n 1)" "${td69c}/skills" "${REPO_FIXTURE}"
else
  fail "69c-opencode: install failed: $(cat "${TMPDIR}/test69c.err")"
fi

sandbox_agents_skills
td69c_cursor="${TMPDIR}/test69c-cursor"
seed_atlassian_sentinels "${AGENTS_SKILLS_DIR}"
if env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td69c_cursor}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install --dry-run >"${TMPDIR}/dry69c.out" 2>"${TMPDIR}/dry69c.err"; then
  missing69c=""
  for name in connecting-atlassian-tools managing-work-in-jira working-with-atlassian; do
    grep -Fqx "Would copy canonical .apm/skills/${name} -> ${AGENTS_SKILLS_DIR}/${name}" "${TMPDIR}/dry69c.out" || missing69c="${missing69c} ${name}"
  done
  [[ -z "${missing69c}" ]] && pass "69c-cursor: dry-run plans each shared install" || fail "69c-cursor: dry-run omitted:${missing69c}"
  if grep -q 'formerly managed' "${TMPDIR}/dry69c.out"; then
    fail "69c-cursor: dry-run still plans shared skill removal"
  else
    pass "69c-cursor: dry-run does not plan shared skill removal"
  fi
  [[ -d "${AGENTS_SKILLS_DIR}/working-with-atlassian" && -L "${AGENTS_SKILLS_DIR}/connecting-atlassian-tools" ]] \
    && grep -Fqx 'old managed skill: working-with-atlassian' "${AGENTS_SKILLS_DIR}/working-with-atlassian/SKILL.md" \
    && pass "69c-cursor: dry-run leaves existing skills in place" || fail "69c-cursor: dry-run mutated existing skills"
else
  fail "69c-cursor: dry-run failed: $(cat "${TMPDIR}/dry69c.err")"
fi
if env -u CURSOR_CONFIG_DIRS CURSOR_CONFIG_DIR="${td69c_cursor}" "${BASELINE_PWD}/scripts/cursor-assets.sh" install >/dev/null 2>"${TMPDIR}/install69c.err"; then
  check_upserted_atlassian "69c-cursor" "$(ls -d "${td69c_cursor}/.backup/"* | head -n 1)" "${td69c_cursor}/skills" "${BASELINE_PWD}"
else
  fail "69c-cursor: install failed: $(cat "${TMPDIR}/install69c.err")"
fi

# ---------------------------------------------------------------------------
# Frontend slides standalone packager
# ---------------------------------------------------------------------------
printf '\n=== Frontend slides standalone packager ===\n'
packager="${BASELINE_PWD}/.apm/skills/frontend-slides/scripts/build-standalone.py"
packager_fixture="${TMPDIR}/standalone-packager"
mkdir -p "${packager_fixture}/deck/assets" "${packager_fixture}/outside"
python3 - "${packager_fixture}" <<'PY'
import sys
from pathlib import Path

root = Path(sys.argv[1])
deck = root / "deck"
(deck / "pixel one.png").write_bytes(b"\x89PNG\r\nfixture")
(deck / "shape(1).svg").write_bytes(b"<svg>quoted</svg>")
(deck / "texture.png").write_bytes(b"unquoted whitespace")
(deck / "assets" / "nested.png").write_bytes(b"nested relative path")
(root / "outside" / "secret.bin").write_bytes(b"OUTSIDE_SECRET_BYTES")
(deck / "source.html").write_text(
    """<!doctype html>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter">
<script>const FILE_NAME = "source.html";</script>
<img src = "pixel%20one.png">
<img src="assets/nested.png">
<img src="HTTPS://example.test/remote.png">
<style>
.quoted { background: url("shape(1).svg"); }
.unquoted { background: url( texture.png ); }
.remote { background: url(HTTP://example.test/remote.svg); }
</style>
""",
    encoding="utf-8",
)
PY

packaged_output="${packager_fixture}/deck/packed-'slash\\name.html"
if python3 "${packager}" "${packager_fixture}/deck/source.html" -o "${packaged_output}" --skip-fonts >"${packager_fixture}/success.out" 2>"${packager_fixture}/success.err"; then
  pass "standalone packager handles supported local URL syntax"
else
  fail "standalone packager rejected supported local URL syntax: $(cat "${packager_fixture}/success.err")"
fi
if python3 - "${packaged_output}" <<'PY'
import json
import re
import sys
from pathlib import Path

html = Path(sys.argv[1]).read_text(encoding="utf-8")
assert len(re.findall(r"data:[^;]+;base64,", html)) == 4
assert "pixel%20one.png" not in html
assert "assets/nested.png" not in html
assert "shape(1).svg" not in html
assert "texture.png" not in html
assert "HTTPS://example.test/remote.png" in html
assert "HTTP://example.test/remote.svg" in html
assert "https://fonts.googleapis.com/css2?family=Inter" in html
match = re.search(r"const\s+FILE_NAME\s*=\s*(\"(?:\\.|[^\"\\])*\")\s*;", html)
assert match
assert json.loads(match.group(1)) == Path(sys.argv[1]).name
PY
then
  pass "standalone output inlines locals and preserves remote URLs safely"
else
  fail "standalone output content or FILE_NAME was incorrect"
fi

repacked_output="${packager_fixture}/deck/repacked.html"
if python3 "${packager}" "${packaged_output}" -o "${repacked_output}" --skip-fonts >"${packager_fixture}/repack.out" 2>"${packager_fixture}/repack.err" &&
   python3 - "${repacked_output}" <<'PY'
import sys
from pathlib import Path

html = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "pixel%20one.png" not in html
assert "assets/nested.png" not in html
assert "shape(1).svg" not in html
assert "texture.png" not in html
assert html.count(";base64,") == 4
PY
then
  pass "standalone output repackages idempotently"
else
  fail "standalone output did not repackage idempotently: $(cat "${packager_fixture}/repack.err")"
fi

collision_source="${packager_fixture}/deck/collision.html"
cp "${packager_fixture}/deck/source.html" "${collision_source}"
collision_before="$(sha256sum "${collision_source}")"
if ! python3 "${packager}" "${collision_source}" -o "${collision_source}" --skip-fonts >"${packager_fixture}/collision.out" 2>"${packager_fixture}/collision.err" &&
   [[ "${collision_before}" == "$(sha256sum "${collision_source}")" ]]; then
  pass "standalone source-output collision preserves source"
else
  fail "standalone source-output collision did not fail safely"
fi

missing_source="${packager_fixture}/deck/missing.html"
missing_output="${packager_fixture}/deck/missing-output.html"
printf '<img src="missing.png">\n' > "${missing_source}"
if ! python3 "${packager}" "${missing_source}" -o "${missing_output}" --skip-fonts >"${packager_fixture}/missing.out" 2>"${packager_fixture}/missing.err" &&
   [[ ! -e "${missing_output}" ]]; then
  pass "standalone missing local asset produces no output"
else
  fail "standalone missing local asset did not fail safely"
fi

outside_secret="${packager_fixture}/outside/secret.bin"
ln -s "${outside_secret}" "${packager_fixture}/deck/secret-link.bin"
absolute_encoded="$(python3 - "${outside_secret}" <<'PY'
import sys
from urllib.parse import quote

print(quote(sys.argv[1], safe=""))
PY
)"
escape_labels=("plain traversal" "encoded traversal" "encoded absolute path" "symlink escape")
escape_refs=("../outside/secret.bin" "%2e%2e/outside/secret.bin" "${absolute_encoded}" "secret-link.bin")
for escape_index in "${!escape_refs[@]}"; do
  escape_slug="${escape_index}"
  escape_source="${packager_fixture}/deck/escape-${escape_slug}.html"
  escape_output="${packager_fixture}/deck/escape-${escape_slug}-output.html"
  printf '<img src="%s">\n' "${escape_refs[${escape_index}]}" > "${escape_source}"
  if ! python3 "${packager}" "${escape_source}" -o "${escape_output}" --skip-fonts >"${packager_fixture}/escape-${escape_slug}.out" 2>"${packager_fixture}/escape-${escape_slug}.err" &&
     [[ ! -e "${escape_output}" ]] &&
     ! grep -q 'T1VUU0lERV9TRUNSRVRfQllURVM=' "${packager_fixture}/escape-${escape_slug}.err"; then
    pass "standalone rejects ${escape_labels[${escape_index}]}"
  else
    fail "standalone did not safely reject ${escape_labels[${escape_index}]}"
  fi
done

if python3 -B - "${packager}" "${packager_fixture}/deck" <<'PY'
import contextlib
import io
import runpy
import sys
from pathlib import Path
from unittest.mock import patch
from urllib.error import URLError

module = runpy.run_path(sys.argv[1])
local = module['inline_local_assets']
fonts = module['inline_google_fonts']
untouched = '''<!-- <img src="missing.png"> -->
<img data-src="missing.png" title='src="missing.png"'>
<script>const template = '<img src="missing.png">'; const css = 'url(missing.png)';</script>
<style>/* url(missing.png) */ .text::after { content: "url(missing.png)"; }</style>'''
assert local(untouched, Path(sys.argv[2])) == (untouched, 0, [])
html, count, missing = local(
    '<IMG SRC = "shape(1).svg#symbol"><div STYLE="background: url(texture.png)"></div>',
    Path(sys.argv[2]),
)
assert count == 2 and not missing
assert ';base64,' in html and '#symbol"' in html
assert 'texture.png' not in html

for separator in ('\u2028', '\f'):
    source = f'<p>one{separator}two</p>\n<img src="texture.png">'
    html, count, missing = local(source, Path(sys.argv[2]))
    data_uri = module['file_to_data_uri'](Path(sys.argv[2]) / 'texture.png')
    assert html == source.replace('src="texture.png"', f'src="{data_uri}"')
    assert count == 1 and not missing

stylesheet = 'https://fonts.googleapis.com/css2?family=Test&display=swap'
font = 'https://fonts.gstatic.com/test.woff2'
css = '@font-face { src: url(' + font + '); }'
link = '<LINK REL="stylesheet" HREF = "' + stylesheet.replace('&', '&amp;') + '">'
preconnect = '<link rel="preconnect" href="https://fonts.gstatic.com">'
script = '<script>const tag = ' + repr(link) + ';</script>'
source = preconnect + link + script
calls = []
def fetch(url):
    calls.append(url)
    return {stylesheet: css.encode(), font: b'font fixture'}[url]

with patch.dict(fonts.__globals__, fetch_url=fetch):
    result, count = fonts(source)
assert count == 1 and calls == [stylesheet, font]
assert 'data:font/woff2;base64,' in result
assert preconnect not in result and script in result

for failed_url in (stylesheet, font):
    def fail_fetch(url):
        if url == failed_url:
            raise URLError('deterministic fixture failure')
        return fetch(url)
    warning = io.StringIO()
    with patch.dict(fonts.__globals__, fetch_url=fail_fetch), contextlib.redirect_stderr(warning):
        result, count = fonts(source)
    assert result == source and count == 0
    assert 'Warning:' in warning.getvalue() and 'keeping original font link' in warning.getvalue()
print('Markup contexts, fragments, font success and both failure paths passed')
PY
then
  pass "standalone markup boundaries, fragments and mocked font outcomes"
else
  fail "standalone markup boundaries, fragments or mocked font outcomes"
fi

# ---------------------------------------------------------------------------
# 70. Shared skill manifests match the packaged shared skills
# ---------------------------------------------------------------------------
printf '\n=== 70. Shared skill manifests ===\n'
if python3 - "${BASELINE_PWD}" <<'PY'
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []

def bash_array(path, name):
    text = (root / path).read_text(encoding="utf-8")
    match = re.search(rf"^{name}=\(\n(.*?)^\)", text, re.MULTILINE | re.DOTALL)
    if not match:
        errors.append(f"{path} is missing {name}")
        return set()
    return set(match.group(1).split())

opencode_shared = bash_array("scripts/install-profile.sh", "SHARED_SKILLS")
opencode_local = bash_array("scripts/install-profile.sh", "OPENCODE_LOCAL_SKILLS")
cursor_shared = bash_array("scripts/cursor-assets.sh", "CANONICAL_SKILLS")
packaged = {path.name for path in (root / ".apm/skills").iterdir() if path.is_dir()}
if opencode_shared != cursor_shared:
    errors.append(f"OpenCode and Cursor shared skills differ: {sorted(opencode_shared ^ cursor_shared)}")
if opencode_shared | opencode_local != packaged:
    errors.append(f"installer manifests and .apm/skills differ: {sorted((opencode_shared | opencode_local) ^ packaged)}")
if "aero-design" not in packaged:
    errors.append("aero-design is not packaged")
for skill in ("connecting-atlassian-tools", "managing-work-in-jira", "ui-mockups", "working-with-atlassian"):
    if skill not in packaged:
        errors.append(f"{skill} is not packaged")
    if skill not in opencode_shared:
        errors.append(f"{skill} is missing from OpenCode shared skills")
    if skill not in cursor_shared:
        errors.append(f"{skill} is missing from Cursor canonical skills")
cursor_skills = bash_array("scripts/cursor-assets.sh", "SKILLS")
mockups = root / ".apm/skills/ui-mockups"
for link in re.findall(r"\]\((references/[^)\s]+)\)", (mockups / "SKILL.md").read_text(encoding="utf-8")):
    if not (mockups / link).is_file():
        errors.append(f"ui-mockups links to missing file {link}")
if not (mockups / "scripts/compose_storyboard.py").is_file():
    errors.append("ui-mockups is missing its storyboard helper")
for script in ("scripts/install-profile.sh", "scripts/cursor-assets.sh"):
    if "stop-design-slop" not in bash_array(script, "HIVE_BUNDLED_SKILLS"):
        errors.append(f"{script} does not report stop-design-slop leftovers as Hive-bundled")
if "stop-design-slop" in opencode_shared | cursor_shared or "stop-design-slop" in packaged:
    errors.append("stop-design-slop must not be a shared canonical skill under .apm/skills")
if "stop-design-slop" not in cursor_skills or not (root / ".apm/cursor/skills/stop-design-slop/SKILL.md").is_file():
    errors.append("stop-design-slop is not packaged as a Cursor skill")
for script in ("scripts/install-profile.sh", "scripts/cursor-assets.sh"):
    if "SHARED_RETIRED_SKILLS" in (root / script).read_text(encoding="utf-8"):
        errors.append(f"{script} still names SHARED_RETIRED_SKILLS")
for skill in sorted(packaged):
    for path in (root / ".apm/skills" / skill).rglob("*.md"):
        text = path.read_text(encoding="utf-8", errors="ignore")
        related = re.search(r"^## Related Skills\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL)
        if not related:
            continue
        for name in re.findall(r"^- `([a-z0-9-]+)`", related.group(1), re.MULTILINE):
            if name not in packaged:
                errors.append(f"{path.relative_to(root)} points to unpackaged skill {name}")
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
PY
then
  pass "70a: installer manifests, packaged skills, and Related Skills references agree"
else
  fail "70a: installer manifests, packaged skills, and Related Skills references agree"
fi

# ---------------------------------------------------------------------------
# 71. Unreadable leftover Cursor skill does not block a managed install
# ---------------------------------------------------------------------------
printf '\n=== 71. Unreadable leftover Cursor skill does not block a managed install ===\n'
if [[ "$(id -u)" -eq 0 ]]; then
  pass "71: SKIP - effective UID is root; kernel bypasses permission bits"
else
  td71="${TMPDIR}/test71"
  mkdir -p "${td71}/skills/cymbal"
  printf '%s\n' 'unreadable leftover cymbal' > "${td71}/skills/cymbal/SKILL.md"
  chmod 000 "${td71}/skills/cymbal/SKILL.md"
  build_fixture
  sandbox_agents_skills
  dry71_status=0
  env -u CURSOR_CONFIG_DIRS -u CURSOR_INSTALL_IVAN_WRITING CURSOR_CONFIG_DIR="${td71}" bash "${CURSOR_HELPER}" install --dry-run >"${td71}/dry.out" 2>"${td71}/dry.err" || dry71_status=$?
  [[ "${dry71_status}" -eq 1 ]] && pass "71a: dry-run exits 1" || fail "71b: dry-run exited ${dry71_status}: $(cat "${td71}/dry.err")"
  grep -F "Would copy canonical .apm/skills/cymbal -> ${AGENTS_SKILLS_DIR}/cymbal" "${td71}/dry.out" >/dev/null && pass "71c: dry-run plans the managed cymbal copy" || fail "71d: dry-run stopped before the managed copy plan: $(cat "${td71}/dry.out")"
  grep -Fqx "decision needed: conflict: ${td71}/skills/cymbal is outside the managed install path ${AGENTS_SKILLS_DIR}/cymbal; left in place" "${td71}/dry.err" && pass "71e: dry-run reports leftover cymbal" || fail "71f: dry-run omitted leftover cymbal: $(cat "${td71}/dry.err")"
  [[ ! -e "${AGENTS_SKILLS_DIR}/cymbal" && "$(stat -c '%a' "${td71}/skills/cymbal/SKILL.md")" == "0" ]] && pass "71g: dry-run left the unreadable skill in place" || fail "71h: dry-run changed the unreadable skill"
  install71_status=0
  env -u CURSOR_CONFIG_DIRS -u CURSOR_INSTALL_IVAN_WRITING CURSOR_CONFIG_DIR="${td71}" bash "${CURSOR_HELPER}" install >"${td71}/install.out" 2>"${td71}/install.err" || install71_status=$?
  [[ "${install71_status}" -eq 1 ]] && pass "71i: install exits 1" || fail "71j: install exited ${install71_status}: $(cat "${td71}/install.err")"
  [[ -f "${td71}/skills/agents-md-mastery/SKILL.md" ]] && pass "71k: install wrote a managed Cursor skill" || fail "71l: managed Cursor skill missing"
  grep -Fqx 'OK' "${AGENTS_SKILLS_DIR}/cymbal/SKILL.md" && pass "71m: install wrote managed cymbal" || fail "71n: managed cymbal missing"
  [[ -e "${td71}/skills/cymbal/SKILL.md" && "$(stat -c '%a' "${td71}/skills/cymbal/SKILL.md")" == "0" ]] && pass "71o: install left the unreadable skill in place" || fail "71p: install removed or rewrote the unreadable skill"
  grep -Fqx "decision needed: conflict: ${td71}/skills/cymbal is outside the managed install path ${AGENTS_SKILLS_DIR}/cymbal; left in place" "${td71}/install.err" && pass "71q: install reports leftover cymbal" || fail "71r: install omitted leftover cymbal: $(cat "${td71}/install.err")"
  if grep -q 'not readable' "${td71}/dry.err" "${td71}/install.err"; then
    fail "71s: preflight aborted on the report-only skill"
  else
    pass "71t: preflight did not abort on the report-only skill"
  fi
  chmod 644 "${td71}/skills/cymbal/SKILL.md"
  grep -Fqx 'unreadable leftover cymbal' "${td71}/skills/cymbal/SKILL.md" && pass "71u: leftover cymbal content unchanged" || fail "71v: leftover cymbal content changed"
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
