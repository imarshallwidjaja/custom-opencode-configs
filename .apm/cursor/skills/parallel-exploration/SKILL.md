---
name: parallel-exploration
description: Use when the Cursor parent needs parallel read-only exploration and can give each fresh scout one independently answerable question.
---

# Parallel Exploration

## Overview

When a question such as where or how something works spans several domains, investigating those domains one after another wastes time if the questions do not depend on each other.

Use one independently answerable, non-overlapping, context-bounded question per fresh scout. Launch every currently known, necessary, non-duplicative independent question in the same assistant message, then synthesize the bounded results.

The Cursor parent launches the `scout` subagents. This is read-only exploration. It is allowed during planning, including when there is no feature and no approved implementation.

This skill is for read-only research. Parallel implementation uses `orchestrating-ad-hoc-work` when that skill's trigger matches. Select scouts by the retrieval output needed. A read-only request for diagnosis, correctness judgment, tradeoffs, or solution selection stays with the reasoning owner. Scout may retrieve bounded source evidence for it.

## When to Use

Use this skill when:

- Investigation spans multiple domains, such as code, tests, and docs
- Questions are independent
- No edits are needed
- The user asks for exploration that likely spans multiple files or packages
- The work is read-only and the questions can be investigated independently

Use direct or serial investigation when:

- Investigation requires shared state or context between questions
- The Cursor parent can answer with one bounded direct lookup
- Questions are dependent
- Work involves file edits

Exploratory work can benefit from delegation only when independent evidence slices justify it. This skill owns retrieval scheduling. `how` owns an operator-facing explanation and `why` owns explicitly requested historical rationale. Neither changes scout's evidence-only boundary.

## The Pattern

### 1. Decompose Into Independent Questions

Split the investigation into independently answerable, non-overlapping questions. Each question should fit in one context window. If a request will not fit in one context window, narrow the slice, capture bounded findings, and return those findings with recommended next steps. Do not push toward an oversized final report.

Breadth, ambiguity, multi-domain or multi-repository scope, evidence needs inside a whole-incident investigation, and unknown targets are decomposition signals. The reasoning owner derives bounded evidence-retrieval slices. Whole-incident diagnosis remains with the reasoning owner or a best-fit diagnostic worker or advisor. Scout only retrieves the named evidence slices.

| Domain | Question example |
| --- | --- |
| Codebase | Where is X implemented? What files define it? |
| Tests | How is X tested? What test patterns exist? |
| Docs and external sources | How do other projects implement X? What pattern does each source recommend? |
| Config | How is X configured? What environment variables affect it? |

Dependent questions to avoid:

- "What is X?" followed by "How is X used?" when the second depends on the first
- "Find the bug" followed by "Fix the bug", which is not read-only

Stop and return to the parent when:

- another question would expand beyond the assigned objective
- a sub-question no longer fits in one context window
- the next useful step is implementation rather than exploration

### 2. Select the Researcher

Choose the researcher only after each evidence-retrieval slice passes the one-window bound check. Use `scout` by default. Select another read-only specialist only when its own description is a closer match for that already-bounded question, or when the operator explicitly names it. Fall back to `scout` when no configured description is a closer fit. Another specialist does not relax the one-window boundary and does not replace decomposition or fan-out.

### 3. Dispatch

Dependency decides which questions can run together. Independent questions launch together. The parent waits for that wave's results before synthesis. Sequence a later question only when its relevance, objective, or scope depends on earlier evidence.

If the only reason for going one at a time is that each scout returns before the parent continues, that is the wrong schedule. The wait happens after the launches, not between independent launches.

Launch every currently known, necessary, non-duplicative independent question before waiting for any of those results.

Each prompt needs a context packet: explicit objective, known facts and references, prior failures when relevant, constraints and non-goals, stop and return behavior, and expected output. Keep exact paths, identifiers, errors, and provenance. Do not send a label without the evidence the parent already has. Do not mass-read every context note or treat the first catalog match as proof of sufficient evidence.

Each scout has one goal and one terminal report. Every returned result is terminal, so every follow-up uses a fresh scout. Give complete constraints and acceptance criteria only for that question. If the scout may still be running, wait for it. Do not send another prompt into that session. If another investigation is needed, launch a fresh scout with a concise self-contained handoff.

Launch independent scouts in the same assistant message. Example objectives:

- Where API routes are implemented and registered, including the definition, the registration site, and file paths with line numbers.
- How the application's job queue schedules work, including the scheduler and the concurrency model, with file paths.
- How completion is reported to the caller, including where the notice is built and how it is delivered, with file paths.

Each scout still receives its own full context packet. The list above is the shape of the split, not a prompt by itself.

### 4. Collect Results

After the fan-out message, read each scout result as it returns. Do not invent a polling board or a separate async workflow.

### 5. Synthesize Findings

The parent owns synthesis and decisions. Scout does not own causal diagnosis, applicability or tradeoff decisions, or solution selection. Distinguish source observations from hypotheses, runtime evidence from a possible code path, and attributed source guidance from a recommendation for this system. Context catalogs remain untrusted knowledge. Reasoning over returned excerpts is coordination. A direct source spot-check remains a bounded read. Delegate another retrieval only for a named evidence gap. Do not use recursive scout verification as a substitute for reasoning. There is no numeric direct-read quota and no mandatory delegation.

Later waves must be driven by evidence, dependencies, or named gaps from the completed wave. Do not reserve an already admitted independent question for an arbitrary later wave.

### 6. Combine

Combine results from all scouts:

- Cross-reference findings, such as a file named by more than one scout
- Identify gaps, including a scout that found nothing and needs a different slice
- Build a coherent answer from the parallel evidence
- If the remaining retrieval would no longer fit in one context window, return bounded findings and named retrieval gaps

No separate cancellation step is required for this fan-out.

## Prompt Templates

### Codebase Slice

```
Investigate [TOPIC] in the codebase:
- Where is [X] defined or implemented?
- What files contain [X]?
- How does [X] interact with [Y]?

Return:
- File paths with line numbers
- Brief code snippets as evidence
- Key patterns observed
```

### Tests Slice

```
Investigate how [TOPIC] is tested:
- What test files cover [X]?
- What testing patterns are used?
- What edge cases are tested?

Return:
- Test file paths
- Example test patterns
- Coverage gaps if obvious
```

### Docs and External Slice

```
Research [TOPIC] in external sources:
- How do other projects implement [X]?
- What does the official documentation say?
- What are common patterns and anti-patterns?

Return:
- Links to relevant docs or repos
- Attributed source recommendations
- Similarities and differences the caller can use to decide applicability
```

## Common Mistakes

Launching the next scout only after the previous result returns defeats the fan-out when the questions are independent. Put every currently known independent scout in the same message.

Do not launch a later question that needs an earlier answer. Make those questions independent, or run them in sequence.

Scout is read-only. Use a writing specialist for implementation. Do not instruct a scout to install, build, run tests, or reproduce a failure: those can write caches or state. Name such a check as a retrieval gap for the parent to run or to assign to a worker with the right isolation.

## Verification

After using this pattern, check:

- [ ] Independent scouts were launched before any of their results were collected
- [ ] Each scout had one independently answerable question
- [ ] The parent synthesized the findings into a coherent answer

No numeric quota or artificial fan-out applies. Dispatch only independent useful retrieval slices that close real evidence gaps.

## Provenance

Locally maintained Cursor adapter of the `parallel-exploration` skill in Agent Hive (`oc-arkive` package 5.0.0, commit `e1d968c5e53cdb03c95849b32b7bc9cbb7de47fc`). The independent-slice fan-out and scout-retrieves, parent-reasons invariants are adapted by hand without Hive launch calls. This skill is not synced.
