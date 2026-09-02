# Worked Example: Decomposing One Epic

Synthetic scenario: TaskFlow, a task management REST API. One developer working with coding agents in parallel.

**Epic:** "Users can create, assign, and track tasks with due dates and status transitions."

Too large for one story: it touches the data model, data access, business rules, HTTP handlers, validation, and tests.

## Step 1: Components

| Component | Description |
|-----------|-------------|
| Data model | Schema and type definitions for tasks |
| Repository | Data access functions (CRUD) |
| Business rules | Status transition rules, assignment validation, due date handling |
| API endpoints | HTTP handlers for task operations |
| Input validation | Request validation for task endpoints |
| Integration tests | End-to-end tests against the running API |

## Step 2: Dependency Graph

```
Data model (schema, types)
    |
    +--> Repository (needs schema)
    |        |
    |        +--> Business rules (needs repository)
    |                 |
    |                 +--> API endpoints (needs business rules)
    |                          |
    |                          +--> Integration tests (needs running API)
    |
    +--> Input validation (needs types only)
```

Key insight: the data model must exist before anything else. It is the foundation and goes alone in wave 1.

## Step 3: Stories with Ownership

Each story owns its artefacts exclusively for its wave. Abbreviated here; the full anatomy (context, acceptance criteria, negative constraints) is covered in writing-work-items.

| Story | Owns | Depends on |
|-------|------|------------|
| 1. Data model and types | `src/models/task.*`, migration file | none |
| 2. Repository | `src/repositories/task-repository.*` and its unit tests | 1 |
| 3. Input validation | `src/middleware/validate-task.*` and its unit tests | 1 |
| 4. Business rules | `src/services/task-service.*` and its unit tests | 2 |
| 5. API endpoints | `src/api/routes/tasks.*`, route index | 3, 4 (interface only) |
| 6. Integration tests | `tests/integration/tasks.*`, fixtures | 5 |

Sample negative constraints for story 1: does NOT implement query logic, does NOT create endpoints. These keep the foundation story small and stop an eager executor expanding scope.

## Step 4: Waves

```
Wave 1: [1. Data model]                        <- alone; foundation
         | gate: schema, types, migration reversibility verified
Wave 2: [2. Repository] [3. Validation]        <- parallel
         | gate: queries and rules verified; SERVICE INTERFACE FROZEN
Wave 3: [4. Business rules] [5. API endpoints] <- parallel
         | gate: transition logic and response shapes verified
Wave 4: [6. Integration tests]                 <- alone; needs everything
```

Six stories, four waves, maximum parallelism of two.

### Why waves 2 and 3 work

Stories 2 and 3 both depend on story 1 but not on each other, and their ownership sets are disjoint. Straightforward parallel pair.

Stories 4 and 5 look sequential: the endpoints call the business rules. The resolution is the interface contract. At the wave 2 gate, freeze the service interface: function signatures, parameter types, return types, error types. Story 5 then implements handlers against the contract while story 4 implements the logic behind it. Neither needs the other's implementation, only the frozen contract.

### Why waves 1 and 4 are single-item

Everything depends on the data model, and integration tests depend on everything. No decomposition removes those bottlenecks; the graph is what it is. A plan that forced parallelism into wave 1 by guessing at types would trade one small sequential wave for rework across every later wave.

## Takeaways

1. Dependencies determine wave structure. Map the graph first, then group.
2. Ownership prevents conflicts. Same-wave overlap means merge the items or resequence.
3. Review gates are coordination. The frozen interface at the wave 2 gate is what makes wave 3 parallel.
4. Foundation waves may be small, and that is correct.
5. Plan from the graph, not the story count.
