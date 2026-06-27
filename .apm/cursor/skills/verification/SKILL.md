---
name: verification
description: Use before claiming work is complete, fixed, passing, or ready; requires fresh command or tool evidence matched to the claim.
---

# Verification

## Purpose

Verification is the evidence protocol for completion claims. It is not a confidence statement, code review, or plan review.

## Core Rule

No completion claim without fresh evidence from this session.

Reading code is not verification. Similar checks, stale logs, and assumptions are not verification.

## Workflow

For each claim:

1. State the claim.
2. Choose the check that would fail if the claim were false.
3. Run the command or observable tool check.
4. Read the output, exit code, status, screenshot, or generated artifact.
5. Compare expected and actual results.
6. Report the command and observed result before claiming success.

## Minimum Useful Checks

- Prompt or docs change: syntax, frontmatter, link, count, conflict-marker, or content-specific grep checks.
- Logic change: relevant tests plus one edge or error path when practical.
- Public API or CLI change: build/typecheck plus a consumer-style invocation or test.
- Bug fix: reproduce the original symptom when practical, then verify the fix.
- Refactor: existing behavior tests and a public-surface check when exposed.
- Config change: parser validation, dry run, or the command that exercises the config.

Scale checks up for persistence, auth, deployment, destructive operations, or concurrency. Scale checks down only for trivial text edits, and say exactly what was checked.

## Failure Handling

If a check fails:

- Quote the relevant output.
- State expected versus actual.
- Mark the result as failed.
- Do not explain away the failure unless repository documentation proves it is intentional.

Use partial only for environmental limits such as missing credentials, unavailable services, or missing local dependencies.

## Output Format

```markdown
## Verification Evidence

**Claim**: <claim>
**Command/tool run**: <exact command or tool>
**Output observed**: <relevant output>
**Result**: PASS | FAIL | PARTIAL
```

## Anti-Rationalization Checks

If you are about to write "should work", "looks correct", "probably passes", or "too small to test", stop and run a check.
