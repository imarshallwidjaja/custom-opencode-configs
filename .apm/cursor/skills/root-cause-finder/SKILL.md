---
name: root-cause-finder
description: Use when a visible contract, parsing, null, schema, hydration, state ownership, or unexpected request failure may be downstream of an earlier unintended side effect.
---

# Root-Cause Finder

## Core Instruction

Before fixing the error, prove whether the code path that produced it was intended.

Do not stop at the first contract, parsing, type, null, or schema error. Treat it as a possible symptom until the causal path is understood.

## When To Use

- Protocol or deserialization failures
- Missing fields or null payloads
- Restore, hydration, or persistence issues
- State ownership bugs
- Unexpected requests or writes
- Background mutations, observers, subscriptions, lifecycle hooks, or retry paths
- Code review where the visible failure may be downstream noise

## Workflow

1. State the expected behavior in plain language.
2. State the invariant in one sentence.
3. State what definitely did not happen.
4. Trace from the intended action or system event to the observed effect.
5. Ask whether the request, mutation, or side effect should have happened at all.
6. Identify the canonical source of truth and every competing source.
7. Find the first unintended side effect or write.
8. Decide whether a downstream contract fix is still necessary.

## Questions To Answer

- What user action or system event was supposed to happen?
- What exact call path caused this request, response, or mutation?
- Should this side effect have happened under the expected behavior?
- Who owns the state at each layer?
- Is there observer-driven syncing, lifecycle startup code, persistence restore, retry logic, or multiple sources of truth?
- If a contract is violated, is the contract wrong, or did unintended logic reach the contract?

## Rules

- Do not make a contract more permissive unless the observed payload is intended in the final design.
- Prefer fixing the upstream logic bug over accepting bad downstream data.
- Separate symptom, trigger, root cause, minimal safe fix, and architectural follow-up.
- If a low-level fix is still needed, explain why the upstream fix is not sufficient.
- Name the first visible wrong behavior, not only the final error.

## Output

- Expected behavior
- Invariant
- Causal chain
- First unintended side effect
- Canonical source of truth
- Competing sources of truth
- Symptom
- Trigger
- Root cause
- Correct layer to fix first
- Minimal safe fix
- Verification evidence
