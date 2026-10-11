# JQL Essentials

Reference for `searchJiraIssuesUsingJql`. Keep queries bounded with
`maxResults` and request only the fields the task needs.

## Operators

| Operator | Example | Meaning |
| --- | --- | --- |
| `=` / `!=` | `status = Done` | Equals / not equals |
| `IN` / `NOT IN` | `status IN (Done, Closed)` | Membership |
| `~` | `summary ~ "timeout"` | Text contains (fuzzy) |
| `IS EMPTY` / `IS NOT EMPTY` | `assignee IS EMPTY` | Null check |
| `>=` / `<=` | `created >= -7d` | Comparison (dates, numbers) |
| `AND` / `OR` / `NOT` | `project = X AND type = Bug` | Boolean combination |
| `ORDER BY` | `ORDER BY priority DESC, updated ASC` | Sorting |

Quote values containing spaces: `status = "In Progress"`.

## Dates

| Form | Example | Meaning |
| --- | --- | --- |
| Relative | `-7d`, `-2w`, `-1m` | Days, weeks, months ago |
| Absolute | `2026-09-01` | Specific date |
| Function | `startOfDay()`, `startOfWeek()`, `startOfMonth()` | Period boundaries |
| Sprint | `sprint in openSprints()` | Issues in any open sprint |

## statusCategory vs status

`status` names are workflow-specific ("Progressing", "Out Review", anything a
team invents). `statusCategory` is always one of three values on every site:

| statusCategory | Meaning |
| --- | --- |
| `To Do` | Not started |
| `In Progress` | Active |
| `Done` | Complete |

Use `statusCategory != Done` for "unfinished work" in any project. Use `status`
only when the user names a specific state in a known workflow.

## Hierarchy

- `parent = EPIC-123` returns an epic's children (and a task's subtasks).
- `issuetype = Epic` scopes to epics themselves.

## Query Habits

- Key terms, not sentences: `text ~ "NullPointerException refund"`, not the
  full report text.
- Include resolved issues when hunting duplicates or regressions; the fix
  history is often the answer. Do not filter to open-only by default.
- Bound results: set `maxResults` (10 for lookups, up to 100 for scope
  queries), paginate when completeness matters.
- Order by what the question asks: `created DESC` for recency, `priority DESC`
  for urgency, `updated ASC` for staleness.

## Pattern Table

| Need | JQL |
| --- | --- |
| My open work | `assignee = currentUser() AND statusCategory != Done ORDER BY priority DESC` |
| Current sprint scope | `project = KEY AND sprint in openSprints() ORDER BY Rank ASC` |
| Snapshot when no sprint | `project = KEY AND statusCategory != Done ORDER BY priority DESC, updated ASC` |
| Recently resolved in component | `project = KEY AND component = "Payments" AND statusCategory = Done AND resolutiondate >= -30d ORDER BY resolutiondate DESC` |
| Stale in-progress items | `project = KEY AND statusCategory = "In Progress" AND updated <= -7d ORDER BY updated ASC` |
| Unassigned unfinished | `project = KEY AND statusCategory != Done AND assignee IS EMPTY ORDER BY priority DESC` |
| Epic's children | `parent = EPIC-123 ORDER BY Rank ASC` |
| Duplicate hunt (include resolved) | `project = KEY AND text ~ "error signature" AND type = Bug ORDER BY created DESC` |
| Recent movement window | `project = KEY AND updated >= -60d ORDER BY updated DESC` |
| High-priority unfinished | `project = KEY AND statusCategory != Done AND priority IN (Highest, High) ORDER BY priority DESC` |
| Created this week | `project = KEY AND created >= startOfWeek()` |
