---
name: consolidate-test-suites
description: Use when adding, moving, or deleting tests after a bug fix or architecture change to place each invariant in one owning test layer.
---

# Consolidate Test Suites

## Purpose

Place each invariant in one owning test layer and avoid duplicate, weak, or misleading coverage.

## Definitions

- Invariant: the rule that must stay true.
- Owning layer: the lowest layer that can prove that rule.
- Canonical suite: the normal existing suite for that owning layer.

## Hard Rules

- Identify the invariant before adding or moving a test.
- Choose one primary owning layer: unit, integration, or end-to-end.
- Prefer an existing canonical suite.
- Prefer editing an existing test file over creating a new one.
- Do not duplicate the same invariant in multiple layers unless each layer proves a distinct failure mode.
- Do not lock in implementation details unless that implementation unit owns the invariant.

## Owning Layer

Choose unit when one module owns the rule and the behavior reproduces without I/O, persistence, process lifecycle, or multi-component coordination.

Choose integration when the rule lives at a boundary, or depends on serialization, persistence, retries, ordering, IPC, lifecycle, or component coordination.

Choose end-to-end only when the user-visible contract cannot be trusted from lower layers alone.

If torn between unit and integration, choose integration. Do not choose end-to-end just because it is easier.

## Placement Order

1. Add to an existing test in an existing file in the owning layer.
2. Add a new test to an existing canonical file.
3. Create a new file inside the existing canonical suite.
4. Create a standalone regression test only when no canonical suite can express the case cleanly and the case has durable contract value.

## Duplicate Cleanup

- Search for tests asserting the same invariant.
- Keep the strongest owned location.
- Merge unique assertions into that location.
- Delete or simplify weaker duplicates.
- Rename tests by behavior and owner, not by ticket number.

## Output

- Invariant
- Owning layer
- Target suite or file
- Placement action
- Why this layer owns it
- Duplicates merged or deleted
- Verification command and observed result
