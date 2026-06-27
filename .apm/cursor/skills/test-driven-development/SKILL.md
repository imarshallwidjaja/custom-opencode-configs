---
name: test-driven-development
description: Use when implementing features, bug fixes, or behavior changes; write a failing test first, make it pass with the smallest change, then refactor safely.
---

# Test-Driven Development

## Core Rule

No behavior-changing production code without a failing check first.

If the change is text-only, configuration-only, or otherwise has no executable behavior, use the narrowest file-specific validation instead and state why an automated test does not apply.

## Red, Green, Refactor

### Red

- Write one minimal test that describes the desired behavior.
- Run it and confirm it fails for the expected reason.
- If it passes immediately, the test is not proving new behavior.

### Green

- Implement the smallest change that makes the test pass.
- Do not add adjacent cleanup, extra options, or speculative abstractions.
- Run the same test and confirm it passes.

### Refactor

- Improve names or remove duplication only after the test passes.
- Keep the test green throughout.
- Run the nearest relevant regression checks before finishing.

## Good Tests

- Test one behavior.
- Name the externally visible rule.
- Prefer real code paths over mocks.
- Mock only when the dependency is slow, nondeterministic, external, or not owned by this codebase.
- Include edge cases only when they affect the behavior being changed.

## Bug Fixes

1. Reproduce the bug.
2. Add a failing test that captures the broken rule.
3. Fix the root cause.
4. Confirm the new test fails before the fix and passes after it.
5. Run the owning suite or nearest regression target.

## Test Placement

Use `consolidate-test-suites` when choosing where durable bug-fix coverage belongs. Prefer the lowest layer that owns the invariant and an existing canonical suite.

## Completion Evidence

Report:

- Test added or validation used
- Red result, if applicable
- Green result
- Broader regression command, if run
- Any reason a normal test was not applicable
