---
name: running-agile-delivery
description: Use when the user or project explicitly adopts this agile delivery method for product delivery cadence, backlog governance, wave review gates, retrospectives, and delivery measurement. Also use for explicit requests to explain or assess the method without activating it. Ordinary local implementation plans, debugging, code review, and ad-hoc subagent handoffs do not trigger this skill; Jira use or backlog drafting alone does not adopt its governance.
---

# Running Agile Delivery

## Applicability

Apply this governance only when the user or project has explicitly adopted it for the product delivery work. An explicit request to explain or assess the method permits advice, not activation. Jira use, backlog drafting, ordinary local implementation plans, debugging, code review, and ad-hoc subagent handoffs do not by themselves activate backlog items, waves, or human review gates.

This skill covers delivery roles, backlog discipline, wave execution, review gates, and improvement. Load `decomposing-work` when designing the backlog breakdown and `writing-work-items` when authoring or reviewing its items; neither is a prerequisite for every cadence or reporting task.

## Roles

| Contribution | Owner |
|--------------|-------|
| Architectural judgement, domain context, quality standards | Humans |
| Execution speed, parallel capacity, consistency | Agents |
| Review | Shared, with humans holding the final gate |

You can outsource execution but not understanding. A human who cannot explain what a wave delivered has lost the plot regardless of how green the checks are.

Agent autonomy is earned through measured evidence, not assumed capability. Early work is human-directed: tight specs, every output reviewed. Expand agent scope (larger items, less prescriptive specs, coordination across items) only where measured outcomes justify the trust, and contract it again when the evidence turns. The measurement section below provides the evidence.

## Backlog Discipline

- Every work request becomes a work item before implementation begins. No item, no work. This applies to bug reports, ideas mid-conversation, and "quick fixes" alike; unrecorded work is invisible to planning, review, and retrospectives.
- One request containing multiple pieces of work becomes multiple items. A request is an inbox entry; items are the unit of execution.
- Classify items with a small `dimension:value` label taxonomy, one value per dimension per item:

| Dimension | Example values |
|-----------|----------------|
| phase | discovery, build, hardening |
| priority | p1, p2, p3 |
| effort | xs, s, m, l, xl |
| category | feature, defect, debt, docs |

Keep the taxonomy small and stable; a taxonomy nobody can remember is decoration.

- Prioritise with priority ranking, but treat the dependency graph as the real sequencer. A p1 item blocked by an unbuilt foundation is not next; the foundation is. Priority says what matters, the graph says what is possible now.

## Wave Execution

Rules for the executing wave:

1. **One branch or workspace per item.** Each contributor works in isolation on the artefacts their item owns. Exclusive ownership plus isolated workspaces is what makes zero-conflict integration the norm.
2. **Avoid routine coordination mid-wave.** Contributors should have the item and frozen contracts they need. Report blockers, unsafe assumptions, ownership conflicts, or invalid contracts immediately; pause affected work rather than waiting for the gate. Record decomposition improvements for the next planning pass.
3. **Self-verification before handback.** Each contributor verifies their own work against the item's acceptance criteria before submitting it to the gate. The gate reviews verified work; it does not run first-pass debugging.

## Review Gates

Every wave ends at a review gate where humans review all produced work. Gates are governance designed into the process, not compliance bolted on after incidents.

- **Every finding reaches a terminal disposition:** fixed, accepted, or deferred. No finding is left ambient. Deferred findings become backlog items with the defect category; accepted findings are recorded with the reason.
- **Gates produce coordination artefacts:** frozen interface contracts and recorded decisions that the next wave depends on. Freezing contracts at the gate is what lets dependent items run in parallel; see decomposing-work.
- **Gates verify against the spec,** not against the reviewer's private taste. If the spec was wrong, that is a spec finding, and it feeds the retrospective.

Speed comes from parallelism, not from skipping quality gates. Budget for the full cycle: review, rework, and integration, not just first-pass implementation.

## Retrospectives

Retrospectives improve the system, not just the output. The team includes agents now; reflect on every part of the collaboration.

Ask, in order:

1. **Where did specs fail?** Which items needed reinterpretation, scope change, or rework caused by ambiguity rather than execution error?
2. **Where did agents produce unexpected results?** Distinguish spec-caused (process problem) from agent-caused (tool problem).
3. **Where did humans fall short?** Poor prompting, inconsistent review, concepts introduced without definition.
4. **What should become automated?** Recurring manual workarounds are a signal.

Review the originating prompts and specs as auditable artefacts. For a sample of items, check: was the context complete, were constraints explicit, were success criteria testable, were relevant artefacts linked? Correlate prompt quality with outcome quality; the correlation tells you which authoring habit to fix first.

Every retrospective finding gets the same terminal disposition rule as review findings: fixed, accepted, or deferred, with deferred items landing in the backlog. Track trends across retrospectives, not absolutes within one; the first measurement is a baseline, not a judgement.

## Measurement

Start with three signals. They come from data you already have and carry the highest signal per unit of effort.

| Signal | Metric | Target direction |
|--------|--------|------------------|
| Spec quality | First-pass acceptance rate; rework attributed to spec vs execution | Acceptance rising; spec-caused rework falling |
| Decomposition effectiveness | Ownership conflicts per wave (merge conflicts, artefact overlap) | Zero |
| Governance health | Escaped defects; gate catch rate (defects found at gate vs after) | Escapes toward zero; catch rate above 90% |

Measure outcomes, not activity. Agent parallelism mechanically inflates activity numbers, so they mislead:

| Measure | Not |
|---------|-----|
| Items accepted | PRs opened |
| Defects escaped | Tests written |
| Rework rate | Commit count or lines changed |

Cadence: count conflicts and first-pass acceptance per wave; assess trends per milestone. Add further dimensions (delivery performance, cost, agent reliability) only once the first three are habitual, and use the evidence to adjust agent autonomy in both directions.

## Related Skills

Load companions only when their task is in scope:

- `decomposing-work`: producing or revising the product backlog dependency graph, waves, and ownership boundaries.
- `writing-work-items`: authoring or reviewing the backlog specs that gates verify against and retrospectives audit.
- `working-with-atlassian`: required foundation only when using Atlassian tools. Add `managing-work-in-jira` for Jira operations or `connecting-atlassian-tools` for cross-product, JPD, or Teamwork Graph work. This cadence does not require an Atlassian tracker.
