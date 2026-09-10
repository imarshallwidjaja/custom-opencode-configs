---
name: writing-work-items
description: Use when authoring or reviewing product backlog epics, user stories, and subtasks, including drafts before tracker publication, or when the user explicitly requests this authoring method. Covers scope, acceptance criteria, ownership, and sizing. Generic acceptance criteria, local implementation plans, debugging, code review, and ad-hoc subagent handoffs do not trigger this skill.
---

# Writing Work Items

## Applicability

Use this method to draft or review product backlog epics, stories, and subtasks, including drafts before tracker publication, or when the user explicitly requests the method. Writing acceptance criteria for local implementation, debugging, code review, or an ad-hoc subagent handoff does not qualify by itself. Do not impose a backlog hierarchy, sizing, or waves on those tasks.

The spec is the program. When an agent or a teammate executes a work item, output quality is bounded by specification quality: vague items produce vague output, and a precise item lets the executor run to completion and self-verify without asking questions. Treat every work item as a contract, not a reminder.

Decomposition (which items to create and how they sequence into waves) is covered in decomposing-work. This skill covers what goes inside each item.

## Hierarchy

| Level | Definition | Earns its existence when |
|-------|------------|--------------------------|
| Epic | An outcome too large for one item | The work spans multiple stories with a shared business outcome and needs a wave plan |
| Story | The atomic execution unit; one contributor, one wave, one deliverable | Always; this is the default level |
| Subtask | Optional mechanical breakdown of a story | The story's steps benefit from separate tracking, e.g. a checklist the executor works through |

Bias toward flat and simple. Most work is a story. Create an epic only when there genuinely are multiple stories to coordinate; create subtasks only when the mechanical steps need visibility. A hierarchy level that exists for tidiness adds reading cost without adding control.

## Story Anatomy

Every story carries these sections. Order matters: an executor reads top to bottom.

| Section | Contents |
|---------|----------|
| Summary | One sentence stating the outcome this story delivers |
| Context | Why the work is needed; the problem it solves or capability it enables |
| Scope | Artefacts to create or modify, interfaces to implement, invariants to preserve |
| Acceptance criteria | Specific, testable conditions that must be true at completion |
| Negative constraints | What this story explicitly does NOT do |
| Dependencies | Items that must complete before this one starts |
| Ownership | The artefacts this story owns exclusively during its wave |
| Sizing | T-shirt size |

### Scope

Three parts, all explicit:

- **Artefacts:** every file, document, or asset the story will create or modify, listed by path or name. This is what makes ownership checkable.
- **Interfaces:** contracts the story must satisfy: signatures, response shapes, formats agreed at a review gate.
- **Invariants:** existing behaviour or contracts the story must not break.

### Negative constraints

A first-class section, not an afterthought. State what the story does not do: "Does NOT modify the schema", "Does NOT implement endpoints", "Does NOT change existing behaviour of X". Negative constraints prevent scope creep between parallel items and rein in executor overreach; agents in particular will happily improve adjacent code unless told the boundary. If a story has no plausible overreach, it is probably too small to be a story.

### Dependencies and ownership

Dependencies name the upstream items, so a planner can verify wave assignment. Ownership restates the artefact list as an exclusive claim: no other item in the same wave may touch these artefacts. Both come directly from the decomposition; see decomposing-work.

## Acceptance Criteria

Criteria are the self-verification contract. Each criterion must be specific and testable: an executor should be able to check it without judgement calls, and ideally by running something. Executable criteria ("all unit tests in X pass", "the migration applies and reverses cleanly") let an agent verify its own work before handing it back.

For behavioural criteria, use Given/When/Then:

```
Scenario: Invalid status transition rejected
GIVEN a task in status "done"
WHEN a request moves it to "in_review"
THEN the request is rejected with a descriptive error
```

Write a scenario for the happy path and one for each meaningful edge or error case. A criterion like "works correctly" or "is well tested" is not a criterion; rewrite it until a machine or a stranger could evaluate it.

### Definition of Done

A short checklist of completion conditions that apply across stories, distinct from the story-specific criteria: implemented and reviewed, tests written and passing, documentation updated. Keep one shared Definition of Done for the team and reference it rather than restating it, adding story-specific items only when needed.

## Quality Check: INVEST

Before an item enters a wave, check it against INVEST:

| Letter | Test |
|--------|------|
| Independent | Can execute without waiting on same-wave items |
| Negotiable | Details can still be discussed; the item is not a rigid design |
| Valuable | Delivers a standalone, integrable increment |
| Estimable | Enough is known to size it |
| Small | Fits one contributor in one wave |
| Testable | Acceptance criteria are checkable |

Failing Independent or Small usually means the decomposition needs another pass. Failing Testable means the criteria need rewriting.

## Sizing

T-shirt sizes, no story points:

| Size | Meaning |
|------|---------|
| XS | Trivial; minutes of focused work, one artefact |
| S | Small; a well-understood change, few artefacts |
| M | A typical story; the default |
| L | Large but still one wave; consider whether it splits |
| XL | Too large for one item; decompose before executing |

Sizing exists to flag decomposition problems (anything L or above) and to sanity-check wave load, not to feed velocity arithmetic.

## Epic Anatomy

| Section | Contents |
|---------|----------|
| Business outcome | The measurable value the epic delivers |
| Success metrics | Specific numbers that define success |
| Scope | Explicitly in scope and explicitly out of scope |
| Child items | Table of stories with size, dependencies, and wave |
| Epic acceptance criteria | Conditions for the epic as a whole, beyond any single story |
| Wave plan | Which stories run in which wave, with gates between |

## Subtasks

Subtasks are mechanical steps under a story, named with an action verb: "Create migration", "Implement error handling", "Write unit tests", "Update documentation". They inherit the story's scope and constraints and never carry their own acceptance criteria beyond the step being done. If a subtask needs its own criteria and ownership, it is a story.

## Templates

Skeleton templates for epic, story, and subtask, plus filled examples: [references/work-item-templates.md](references/work-item-templates.md).

## Related Skills

Load companions only when their task is in scope:

- `decomposing-work`: deciding which product backlog items to create and how they depend on one another; unnecessary for an already bounded item.
- `running-agile-delivery`: explaining or assessing its method, or applying its governance after explicit user or project adoption. Authoring an item does not adopt that governance.
- `working-with-atlassian`: required foundation only when using Atlassian tools. Add `managing-work-in-jira` for Jira operations or `connecting-atlassian-tools` for cross-product, JPD, or Teamwork Graph work. Drafting an item does not require a tracker.
