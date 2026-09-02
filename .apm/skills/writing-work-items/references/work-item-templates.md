# Work Item Templates

Plain markdown skeletons for epic, story, and subtask, followed by filled examples. Copy the skeleton, delete unused guidance comments, keep every section heading.

## Epic Skeleton

```markdown
# Epic: [Domain] - [Business Outcome]

## Business Outcome
[The measurable value this epic delivers.]

## Success Metrics
- [Metric 1: specific number or threshold]
- [Metric 2: specific number or threshold]

## Scope
**In scope:**
- [Capability or area]

**Out of scope:**
- [Explicitly excluded capability or area]

## Child Items
| Story | Size | Depends on | Wave |
|-------|------|------------|------|
| [Story name] | M | none | 1 |

## Epic Acceptance Criteria
- [ ] [Condition true of the epic as a whole]

## Wave Plan
Wave 1: [stories] -> gate: [what the gate verifies or freezes]
Wave 2: [stories] -> gate: [...]
```

## Story Skeleton

```markdown
# Story: [Outcome in one sentence]

## Context
[Why this work is needed. The problem it solves or capability it enables.]

## Scope
**Artefacts to create or modify:**
- `path/to/artefact` - [what changes]

**Interfaces to implement:**
- [Contract, signature, or format this story must satisfy]

**Invariants to preserve:**
- [Existing behaviour or contract that must not break]

## Acceptance Criteria
- [ ] [Specific, testable condition]
- [ ] [Scenario in Given/When/Then for behavioural criteria]

## Negative Constraints
- Does NOT [adjacent work this story must not do]
- Does NOT modify [artefacts outside ownership]

## Dependencies
- [Upstream item that must complete first, or "none"]

## Ownership
| Artefact | Notes |
|----------|-------|
| `path/to/artefact` | [exclusive during this wave] |

## Sizing
[XS / S / M / L / XL]
```

## Subtask Skeleton

```markdown
- [ ] [Action verb] [object]   e.g. Create migration, Implement error handling, Write unit tests
```

Subtasks inherit the parent story's scope and constraints. No separate criteria.

## Filled Example: Story

```markdown
# Story: Task repository provides safe CRUD access to the tasks table

## Context
The task data model (schema and types) exists. Business rules and endpoints
need a data access layer so they never build raw queries. This story provides
that layer.

## Scope
**Artefacts to create or modify:**
- `src/repositories/task-repository.ts` - repository functions
- `tests/unit/repositories/task-repository.test.ts` - unit tests

**Interfaces to implement:**
- Functions: createTask, getTaskById, listTasks(filters), updateTask, deleteTask
- All functions return typed results using the task types from the data model

**Invariants to preserve:**
- Existing repository modules and their exports are unchanged

## Acceptance Criteria
- [ ] All five functions implemented with parameterised queries (no string-built SQL)
- [ ] listTasks supports filtering by status and assignee
- [ ] Unit tests cover all functions with a mocked database and pass

## Negative Constraints
- Does NOT implement business rules (status transitions, assignment validation)
- Does NOT create or modify API endpoints
- Does NOT alter the schema or migrations

## Dependencies
- Story: Task data model and types

## Ownership
| Artefact | Notes |
|----------|-------|
| `src/repositories/task-repository.ts` | exclusive during wave 2 |
| `tests/unit/repositories/task-repository.test.ts` | exclusive during wave 2 |

## Sizing
M
```

## Filled Example: Epic (abbreviated)

```markdown
# Epic: Task Management - Users create, assign, and track tasks

## Business Outcome
Users manage their work inside the product instead of an external tracker,
increasing daily active use of the workspace.

## Success Metrics
- 60% of active users create at least one task within 30 days of release
- Zero data-integrity defects in task state transitions in the first month

## Scope
**In scope:**
- Task CRUD, assignment, due dates, status transitions
**Out of scope:**
- Notifications, recurring tasks, reporting

## Child Items
| Story | Size | Depends on | Wave |
|-------|------|------------|------|
| Task data model and types | S | none | 1 |
| Task repository | M | data model | 2 |
| Input validation | S | data model | 2 |
| Task business rules | M | repository | 3 |
| Task API endpoints | M | validation, business rules (interface) | 3 |
| Integration tests | M | endpoints | 4 |

## Epic Acceptance Criteria
- [ ] Full lifecycle (create -> assign -> transition -> complete) passes integration tests
- [ ] Invalid status transitions are rejected with descriptive errors

## Wave Plan
Wave 1: data model -> gate: schema and types verified, migration reversible
Wave 2: repository + validation -> gate: queries verified; service interface frozen
Wave 3: business rules + endpoints -> gate: transitions and response shapes verified
Wave 4: integration tests -> gate: lifecycle coverage verified
```
