---
name: brainstorming
description: Use before creative implementation work to turn rough ideas into scoped, testable designs through focused questions and tradeoff analysis.
---

# Brainstorming Ideas Into Designs

## Overview

Turn ideas into workable designs through short, collaborative dialogue.

Start by understanding the current project context. Ask one question at a time, then present a small design when the goal, constraints, and success criteria are clear enough.

## Process

### Understand The Idea

- Inspect the current project state first: files, docs, and recent commits when available.
- Ask one question per message.
- Prefer multiple-choice questions when they reduce ambiguity.
- Focus on purpose, constraints, users, success criteria, and what is out of scope.

### Explore Approaches

- Offer 2 or 3 viable approaches.
- Name the tradeoffs directly.
- Lead with the recommended option and explain why.
- Remove speculative features before implementation begins.

### Present The Design

- Break the design into short sections.
- Cover architecture, components, data flow, failure handling, and verification.
- Check whether each section is right before moving on.
- Revise when the user corrects the intent or constraints.

## After The Design

- You may present the validated design or summary in chat.
- Write persistent design or planning documents, such as `docs/plans/YYYY-MM-DD-<topic>-design.md`, only after the operator explicitly requests or approves a durable file.
- Use `using-git-worktrees` when isolated implementation work is appropriate.
- Create a concrete implementation plan only when the user wants one or the work is large enough to need sequencing.

## Stop Before Implementation

Brainstorming stops at an approved design or implementation brief. Do not edit product files, create branches, run broad test suites, or start implementation while this skill is active unless the user explicitly moves from design to implementation.

## Final Output

Return a compact design summary with:

- Goal and user-visible outcome.
- Constraints and non-goals.
- Selected approach and why it beats the alternatives.
- Acceptance criteria.
- Files or areas likely to change.
- Risks, open questions, and verification plan.

## Principles

- One question at a time.
- Multiple choice when useful, open-ended when necessary.
- Keep scope small enough to verify.
- Compare alternatives before settling.
- Validate incrementally instead of dumping a full design at once.
