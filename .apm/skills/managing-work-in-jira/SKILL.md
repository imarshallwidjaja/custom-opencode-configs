---
name: managing-work-in-jira
description: Implement agile delivery in Jira through the Atlassian MCP tools. Covers epic, story, and subtask hierarchy across team-managed and company-managed projects, the metadata-first backlog creation flow (epic before children), editing issues, querying and running workflow transitions, sprint and board reporting with scope-first paginated queries, bug triage with duplicate detection and confidence bands, and honest evidence-based reporting. Use when creating or breaking down Jira issues, epics, stories, tickets, or a backlog, transitioning or updating work items, planning or reviewing sprints, triaging bugs or errors, or reporting on Jira delivery status.
---

# Managing Work In Jira

Implements agile delivery in Jira via the Atlassian MCP tools. Follow the tool
model, safety policy, and JQL guidance in `working-with-atlassian`; this skill
assumes them. For what makes a good breakdown or well-written work item, defer
to the `decomposing-work` and `writing-work-items` theory skills; this skill
covers how to execute those decisions in Jira.

## Hierarchy And Project Style

Standard hierarchy: epic -> story/task/bug -> subtask.

Project style changes how linking and naming work, so detect it before linking
anything. Fetch the project's issue-type metadata (via `discover` for project
and issue-type metadata operations, then `executeRead`) and read what is
actually there:

| Aspect | Team-managed | Company-managed |
| --- | --- | --- |
| Issue type names | Per-project, freely renamed | Shared site-wide scheme |
| Epic linking | `parent` field on the child | `parent` on newer sites; older sites use an epic link custom field |
| Workflow states | Per-project, often custom | Shared workflow schemes |

Choose from the types the metadata returns, and fall back to the first
available non-epic, non-subtask type when nothing matches the work.

## Creating A Backlog

Canonical flow for turning a spec or request into Jira work:

```
1. Resolve the target project (ask if not provided or pinned)
2. Fetch the project's issue-type metadata
3. Decompose internally and present the proposed breakdown for approval:
     Epic: <summary>
     1. [Story] <summary>
     2. [Task]  <summary>
     ...
   "Create these in KEY? Yes, create as-is / Modify / Skip"
4. Create the epic FIRST with createJiraIssue; capture its key
5. Create children with createJiraIssue, setting parent to the epic key
6. Report every created key with links
```

The epic must exist before children because children need its key at creation
time; creating children first produces orphans that need a second pass.

Issue descriptions should carry context, requirements, and testable acceptance
criteria. Summaries use an action verb and a specific object: "Implement
password reset API", not "Backend work".

Required-field failure recovery: when `createJiraIssue` fails on required
fields, fetch the issue type's field metadata (via `discover` +
`executeRead`), ask the user for the missing values, and retry with those
fields set. Do not guess values for required custom fields.

Adding to an existing epic: skip epic creation, confirm the epic key with the
user, and start at step 5.

## Editing, Transitions, Comments

| Action | Rule |
| --- | --- |
| Edit | `getJiraIssue` first, then `editJiraIssue` with only the fields that change |
| Transition | Query the issue's available transitions first (via `discover` + `executeRead`), match the target state by name, then `transitionJiraIssue` |
| Resolution-required states | If a transition requires a resolution or other screen fields, the transitions response shows them; supply values or ask the user |
| Comments | `addOrEditJiraIssueComment` for work logs, implementation details, and triage context. Comments are the audit trail; prefer a comment over silently editing a description |

When a transition to the requested state does not exist from the current
state, list the transitions that do exist and ask, rather than chaining
guessed intermediate hops.

## Sprint And Board Work

Run one paginated scope query, then derive signals locally:

```jql
project = KEY AND sprint in openSprints() ORDER BY Rank ASC
```

Request the fields the analysis needs (`status`, `statusCategory`, `assignee`,
`priority`, `updated`, `resolutiondate`, `parent`, `labels`) and derive done
counts, owner load, stale items, unassigned work, and priority risks from the
returned set. Do not issue one JQL call per question.

Follow-up queries are justified only to support a visible claim the scope data
cannot safely support (for example, fetching linked-issue status to
substantiate a dependency claim).

If the open-sprint query returns nothing, switch to a snapshot
(`statusCategory != Done`) plus a recent-movement window (`updated >= -60d`),
and say so in the output.

## Triage

For bug reports and errors:

1. Extract the error signature, component, and symptom from the report.
2. Run three angled searches, all including resolved issues: error-focused,
   component-focused, symptom-focused. Key terms, not sentences.
3. Band the best match by confidence:

| Confidence | Signal | Action |
| --- | --- | --- |
| Above 90 percent | Same error, same component, recent | Recommend commenting on the existing issue |
| 70-90 percent | Similar error or same root cause | Present both options; user decides |
| Below 70 percent | Different signature or context | Recommend a new issue, referencing related keys |

4. A matching resolved issue suggests a regression: propose a new issue linked
   to the old one rather than reopening silently.
5. The user confirms before any write. Present findings with keys, status,
   and why each candidate matches or differs.

## Reporting

- Read-only by default. Do not create, edit, transition, or comment while
  building a report unless the user asks for a write afterwards.
- End with an evidence appendix: the exact JQL run, fields requested, and any
  assumptions or unchecked signals.
- Separate Jira facts from derived or inferred signals.
