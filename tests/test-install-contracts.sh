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

build_fixture() {
  rm -rf "${REPO_FIXTURE}"
  mkdir -p "${REPO_FIXTURE}"

  # Canonical skills (.apm/skills/)
  for skill in humanizer stop-slop context-mode cymbal hard-cut web-design-guidelines writing-skills; do
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

  # Cursor rules
  mkdir -p "${REPO_FIXTURE}/.apm/cursor/rules"
  cat > "${REPO_FIXTURE}/.apm/cursor/rules/default-agent.md" <<'RULES'
# Default Agent
Be helpful. Use plain language. Avoid Hive tools.
RULES

  # Cursor skills
  for skill in brainstorming consolidate-test-suites finishing-a-development-branch root-cause-finder subagent-delegation systematic-debugging test-driven-development use-railway using-git-worktrees verification; do
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

  # Root files
  echo '{}' > "${REPO_FIXTURE}/opencode.json"
  echo '{}' > "${REPO_FIXTURE}/agent_hive.json"
  echo '{}' > "${REPO_FIXTURE}/apm.yml"
  mkdir -p "${REPO_FIXTURE}/scripts"
  printf '#!/bin/true\n' > "${REPO_FIXTURE}/scripts/enable-optional.sh"
  chmod +x "${REPO_FIXTURE}/scripts/enable-optional.sh"

  # Copy real scripts, patching REPO_ROOT
  cp "${BASELINE_PWD}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/cursor-assets.sh"
  cp "${BASELINE_PWD}/scripts/install-profile.sh" "${REPO_FIXTURE}/scripts/install-profile.sh"
  chmod +x "${REPO_FIXTURE}/scripts/cursor-assets.sh" "${REPO_FIXTURE}/scripts/install-profile.sh"
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
[[ -f "${td3}/skills/ivan-writing/.cursor-managed" ]] && pass "3m: marker inside ivan-writing" || fail "3n: marker not inside ivan-writing"

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
[[ -f "${td12}/opencode.json" ]] && pass "12c: config exists" || fail "12d: config missing"
build_fixture

# ---------------------------------------------------------------------------
# 13. Dry-run non-mutation
# ---------------------------------------------------------------------------
printf '\n=== 13. Dry-run non-mutation ===\n'
td13="${TMPDIR}/test13"; mkdir -p "${td13}"
echo "keep" > "${td13}/should_stay.txt"
build_fixture
before13="$(snapshot_tree "${td13}")"
CURSOR_CONFIG_DIR="${td13}" bash "${CURSOR_HELPER}" install --dry-run 2>"${TMPDIR}/test13-dryrun.log" && pass "13a: dry-run succeeded" || fail "13b: dry-run failed"
after13="$(snapshot_tree "${td13}")"
[[ "${before13}" == "${after13}" ]] && pass "13c: dry-run target tree unchanged" || fail "13d: dry-run mutated target tree"

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
[[ -f "${td15a}/agents/forager.md" ]] && pass "15g: first target agent" || fail "15h: first target missing agent"
[[ -f "${td15b}/agents/forager.md" ]] && pass "15i: second target agent" || fail "15j: second target missing agent"

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
