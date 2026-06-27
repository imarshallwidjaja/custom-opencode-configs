---
name: systematic-debugging
description: Use when encountering bugs, test failures, build failures, or unexpected behavior before proposing fixes.
---

# Systematic Debugging

## Core Rule

Find the root cause before changing code.

Do not patch symptoms, loosen contracts, or add fallbacks until you can explain the first wrong behavior and the path that produced it.

## When To Use

- Test failures
- Build failures
- Production bugs
- Unexpected UI, API, or state behavior
- Performance regressions
- Integration failures
- Any issue where a quick fix seems obvious but unproven

## Workflow

### 1. Reproduce

- Read the full error message or failing assertion.
- Capture the exact command, input, or user action.
- Confirm whether the failure is deterministic.
- If it is not reproducible, gather more evidence before fixing.

### 2. Isolate

- Check recent changes.
- Compare broken behavior with a nearby working path.
- Trace the data or control flow across component boundaries.
- Add temporary diagnostics only when they answer a specific question.

### 3. Hypothesize

- State one concrete theory: "I think X causes Y because Z."
- Test the smallest observable part of that theory.
- If the result disproves it, discard the theory instead of layering another fix on top.

### 4. Fix

- Write or identify the smallest failing check that proves the bug.
- Apply one fix aimed at the root cause.
- Run the failing check again, then run the nearest relevant regression checks.

## Multi-Component Evidence

When the issue crosses boundaries, inspect each handoff:

- What data enters this component?
- What data leaves it?
- Which configuration or environment values are visible here?
- Which component first observes or creates the bad state?

## Stop Conditions

- After three failed fixes, stop and reassess the architecture or assumptions.
- If the visible error is a contract, parsing, null, or schema failure, consider `root-cause-finder` before making the downstream layer more permissive.
- If you cannot reproduce the issue, report that limitation explicitly.

## Output

Report:

- Symptom
- Reproduction
- First wrong behavior
- Root cause
- Minimal fix
- Verification command and observed result
