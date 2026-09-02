---
name: decomposing-work
description: Use when breaking an epic, feature, or large request into parallel-safe work items. Covers identifying independent components, mapping the dependency graph before creating items, assigning exclusive ownership boundaries, grouping items into waves separated by review gates, and freezing interface contracts so dependent items can run in parallel. Applies to decomposition, splitting work, breaking down epics, planning parallel execution for humans and agents, sequencing dependencies, and diagnosing coordination breakdown or over-decomposition.
---

# Decomposing Work

Teams of humans and agents rarely fail because a single contributor lacked capability. They fail because parallel contributors collided: two items edited the same artefact, an unstated dependency stalled a batch, or an ambiguous boundary let scope drift between items. The specification is the primary control surface, and decomposition is the primary coordination mechanism. Get the decomposition right and most coordination problems never occur.

A well-decomposed body of work needs no mid-flight coordination messages. Each item can be handed to a separate contributor, human or agent, who executes it to completion without asking what anyone else is doing.

## The Method

Run these four steps in order. The common mistake is jumping straight to step 3.

| Step | Action | Output |
|------|--------|--------|
| 1 | Identify independent components | List of natural functional pieces |
| 2 | Map the dependency graph | Which components need which others, before any items exist |
| 3 | Create work items with exclusive ownership | One item per unit, each declaring the artefacts it alone may touch |
| 4 | Assign items to waves | Batches where same-wave items share no dependencies and no ownership overlap |

### Step 1: Identify components

Ask: what are the independent pieces of functionality? For software this often falls along data model, data access, business rules, interface, validation, and tests. For non-code work it falls along documents, sections, datasets, or decision areas. Components are candidates, not items yet.

### Step 2: Map dependencies first

Before writing a single work item, draw the graph: which component must exist before another can start? The graph, not the item count, determines how much parallelism is actually available. A naive plan says "six items, two contributors, three batches"; the graph usually says otherwise. Plan from the graph.

### Step 3: Exclusive ownership boundaries

Every work item declares the artefacts it owns exclusively for its wave: files for code work, sections or documents for writing work, artefacts generally. No two items in the same wave may own the same artefact. If two items need the same artefact, either merge them or move one to a later wave. Ownership is stated in the item itself so any contributor can verify the boundary before starting. The writing-work-items skill covers how to record this in the item.

### Step 4: Group into waves

A wave is a small parallel batch. Two items may share a wave only when both hold: neither depends on the other, and their ownership sets are disjoint. Everything else is sequenced into later waves. Each wave ends at a review gate before the next begins.

## Waves, Not Waterfalls

Waves are not phases of a waterfall. Each wave produces shippable increments, and the gate between waves is short and specific, not a stage sign-off.

- Foundation waves may contain a single item. That is correct, not a planning failure. Rushing the foundation to maximise parallelism creates rework downstream.
- Sequential dependencies are explicit and minimised, never discovered mid-wave.
- Maximum parallelism usually occurs in the middle waves, after the foundation exists and before integration pulls everything together.

## Review Gates and Interface Contracts

Review gates are coordination, not overhead. A gate does two jobs:

1. **Verify** the wave's outputs against their acceptance criteria before dependents build on them.
2. **Freeze interface contracts** that unlock the next wave's parallelism.

The second job is the one teams miss. When item B depends on item A's interface but not its implementation, define the contract at the gate before both start: signatures, parameter types, return shapes, error types. Both items then execute in parallel in the next wave, each coding against the frozen contract. Without the frozen contract, B must wait for A and the wave collapses into a sequence.

Gates also produce decisions. Record contracts and decisions where the next wave's contributors will find them; a contract that lives only in someone's head is not frozen.

## Independently Executable Units

A work item is ready for parallel execution when it has:

| Property | Test |
|----------|------|
| Explicit ownership | The item lists every artefact it will create or modify |
| Clear interfaces | Inputs, outputs, and contracts it must satisfy are named |
| No overlap | No same-wave item touches any of its owned artefacts |
| Standalone deliverable | The result is independently shippable and integrable |
| Self-verifiable | Acceptance criteria let the executor confirm completion without asking |

Cross-cutting concerns are resolved through architectural agreement at planning time, not through runtime coupling or mid-wave messages.

## Simplicity Bias

Prefer the smallest decomposition that isolates the real dependencies. Over-decomposition is itself a failure mode: more items means more boundaries to define, more gates to run, and more integration surface, all of which cost coordination without buying parallelism. One retrospective of this method recorded a decomposition that was technically valid but over-engineered for the actual constraint; the graph had one real bottleneck and the extra item boundaries added ceremony around it.

Signals of over-decomposition:

- Items so small their specification is longer than their execution.
- Waves of one item each, in sequence, where a single larger item would have done.
- Boundaries drawn along org-chart or template lines rather than along real dependencies.
- Contracts frozen between items that could simply have been one item.

When in doubt, merge. Split again only when the graph shows two genuinely independent pieces that could run in parallel.

## Worked Example

A compact end-to-end decomposition of one epic into six stories across four waves, with the dependency map, ownership tables, and gate contents: [references/decomposition-example.md](references/decomposition-example.md).

The shape to remember: one foundation story alone in wave 1, two parallel pairs in waves 2 and 3 (the second pair unlocked by a contract frozen at the wave 2 gate), and integration alone in wave 4. Six stories, four waves, maximum parallelism of two.

## Related Skills

- writing-work-items: authoring the items this decomposition produces, including ownership, acceptance criteria, and negative constraints.
- running-agile-delivery: executing waves, running review gates, retrospectives, and measurement.
- Vendor implementation (tracker setup, item creation, linking) lives in the working-with-atlassian, managing-work-in-jira, and connecting-atlassian-tools skills.
