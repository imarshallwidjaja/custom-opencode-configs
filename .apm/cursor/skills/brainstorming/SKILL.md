---
name: brainstorming
description: "Use before creative work such as creating features, building components, adding functionality, or modifying behavior."
---

# Brainstorming Ideas Into Designs

## Overview

Understand the project context, desired behavior, constraints, and observable acceptance criteria before editing. Scale dialogue to the decisions still open.

## Choose The Path

For a clear, authorized feature request or concrete corrective feedback, proceed with the smallest coherent implementation through the applicable execution workflow. Do not add a readiness prompt, design approval, or planning handoff by default.

Ask one targeted question when a material ambiguity affects correctness, safety, data scope, persistence, UX, or a public contract. Pause the affected decision until it is resolved; do not guess. Continue independent authorized preparation when safe.

When the user asks to explore, discuss, or design, keep the work exploratory. Reading this skill does not authorize implementation of an advice-only request.

## Collaborative Exploration

Use these steps when exploration is requested or unresolved material choices need dialogue:

- Inspect relevant files, docs, and recent changes.
- Ask one question at a time about purpose, constraints, or success criteria.
- Compare genuinely different approaches when the choice has meaningful trade-offs. Lead with a recommendation and its reasoning.
- Present the design at the level needed to resolve the open choices. Check agreement on material decisions, rather than requiring approval for every section.
- Surface fragile assumptions and remove speculative features.

## After The Design

Keep the design in the conversation unless the user requests a tracked artifact or the repository workflow requires one.

Proceed with implementation when already authorized and material decisions are resolved. Ask for authorization when the request was exploratory only. Use `planning-prompt` or `implementation-brief` only when a handoff is requested or needed by the chosen workflow: these commands prepare handoff prompts, not implementation plans. Do not create a formal plan by default.
