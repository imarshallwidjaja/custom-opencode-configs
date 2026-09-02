---
name: working-with-atlassian
description: Operate the Atlassian MCP tools safely and efficiently across Jira, Confluence, and the wider Atlassian platform. Teaches the three-layer tool model (primary tools, discover, execute-family by risk tier), cloudId bootstrap and pinning, response slimming, custom field behaviour, JQL essentials, and the suite-wide safety policy of read-before-write, propose-approve-execute, and destructive gates. Use whenever a task touches Jira issues, tickets, epics, sprints, backlogs, JQL queries, Confluence pages, Atlassian search, or any Atlassian MCP tool call, including setup questions like resolving cloudId or finding the right operation.
---

# Working With Atlassian

Foundation skill for the Atlassian MCP tools. `managing-work-in-jira` and
`connecting-atlassian-tools` build on the rules here; read this first when any
Atlassian work is in scope.

The MCP server handles all transport, authentication, and payload formatting.
Never bypass it with direct HTTP calls or hand-built credentials; if a
capability seems missing, it is a discovery problem, not a transport problem.

## The Three-Layer Tool Model

The Atlassian MCP server exposes a small set of primary tools and lets you
discover the rest on demand.

| Layer | What it is | When to use |
| --- | --- | --- |
| Primary tools | Named tools already in the tool list | Always prefer these; call directly |
| `discover` | Describe the goal in natural language; returns operation names, inputs, and the matching execute-family tool | When no primary tool covers the goal |
| Execute-family | `executeRead`, `executeWrite`, `executeDestructive` | Run a discovered operation at its risk tier |

Primary tools (call directly, never `discover` these):

| Area | Tools |
| --- | --- |
| Bootstrap | `getAccessibleAtlassianResources`, `atlassianUserInfo` |
| Jira | `getJiraIssue`, `searchJiraIssuesUsingJql`, `createJiraIssue`, `editJiraIssue`, `transitionJiraIssue`, `addOrEditJiraIssueComment` |
| Confluence | `getConfluenceContent`, `createConfluenceContent`, `updateConfluenceContent`, `searchConfluence` |
| Cross-product | `search` (Rovo), `getLoomVideo` |
| Teamwork Graph | `getTeamworkGraphContext`, `getTeamworkGraphObject`, `addTeamworkGraphContext` |

Execute-family risk tiers:

| Tool | Tier | Examples |
| --- | --- | --- |
| `executeRead({name, cloudId, inputs})` | Read-only lookups | Board and sprint reads, project metadata, idea reads |
| `executeWrite({name, cloudId, inputs})` | Non-destructive creates and updates | Creating links, updating fields, adding insights |
| `executeDestructive({name, cloudId, inputs})` | Deletes and irreversible changes | Deleting issues, pages, or spaces |

Calling the wrong tier is rejected with an error naming the correct tool.
Follow the error and retry at the named tier.

### Never Guess Operation Names

Operation names passed to the execute-family must come from `discover` results
in the current session or from the live tool list. Never invent, remember, or
pattern-match a name. When unsure, run `discover` first with a plain
description of the goal, for example "get sprints for a board" or "add an
insight to a product discovery idea".

## Bootstrap: cloudId

Call `getAccessibleAtlassianResources` once per session and reuse the returned
cloudId. On execute-family calls, pass `cloudId` as a top-level argument, a
sibling of `name` and `inputs`, never inside `inputs`.

Pinning removes discovery overhead entirely. When a project or workspace has
stable Atlassian context, record it in AGENTS.md or project rules:

```md
## Atlassian MCP
- cloudId = "<site cloudId>" (do not call getAccessibleAtlassianResources)
- Jira project key = YOURPROJ
- Confluence spaceId = "123456"
- maxResults: 10 for all JQL and CQL searches unless the task needs more
```

Fetch the current user's accountId from `atlassianUserInfo` once, and only when
a query or assignment actually needs it.

## Response Discipline

| Mechanism | Behaviour |
| --- | --- |
| `responseFields` | Dot paths selecting exactly the fields you need |
| `view: compact` | Default; smallest payload, omits Jira custom fields |
| `view: evidence` | Adds custom fields and supporting detail |
| `view: full` | Everything; use sparingly |

Custom field rules:

- Story points and other `customfield_*` values are omitted by the compact
  default. Request `view: evidence` or `view: full`, or name the site's
  `customfield_*` IDs explicitly in `fields`.
- Custom field values land under `fields.customFields`, not as top-level
  `customfield_*` keys.
- Custom field IDs differ per Cloud site; never assume an ID from another site.

Exact parameter names matter. Take them from `discover` results or the tool
schema, never from analogy. For example, `getConfluenceContent` takes
`content_id`, not `id` or `contentId`.

## Recovery Contract

1. On a tool error, retry once with corrected input (fix the parameter name,
   tier, or value the error identifies).
2. On a missing operation, re-run `discover` with different keywords.
3. If both fail, report the blocker with the exact error rather than
   improvising an unsupported path.

## Safety Policy

These rules apply to every Atlassian write, in this skill and the skills that
build on it.

| Rule | Meaning |
| --- | --- |
| Read before write | Fetch the current state of an issue, page, or idea before editing it. Never edit blind. |
| Propose, approve, execute | For any write that creates or restructures work (issues, pages, ideas), present the plan and get explicit user approval first. Offer: "Yes, create as-is / Modify / Skip". |
| Metadata before write | Check project issue-type metadata before choosing issue types. Never hard-code Task, Story, or Bug names; projects vary. |
| Query transitions first | Transition IDs and names are workflow-specific. Fetch available transitions for the issue before transitioning; never assume. |
| Destructive gate | `executeDestructive` requires explicit user confirmation naming the exact target. Prefer archive or close over delete. Never bulk-delete without showing a listed preview of every affected item. |
| Honest evidence | Never make negative claims ("no blockers", "no duplicates") beyond what the queried fields support. Cite the JQL or queries used when reporting. If only status and labels were checked, say "no status/label blockers found", not "no blockers". |

The propose-approve-execute loop in practice:

```
1. PLAN     analyse the request and current Atlassian state
2. PROPOSE  present the exact items to be created or changed
3. APPROVE  user confirms, modifies, or skips
4. EXECUTE  perform the writes
5. REPORT   list created/changed keys with links
```

Routine, explicitly requested single writes (add this comment, transition this
issue to Done) do not need a proposal round; the user's instruction is the
approval. The loop is for writes that create or restructure work.

## JQL

`searchJiraIssuesUsingJql` is the workhorse for Jira reads. Keep queries
bounded (`maxResults`) and request only needed fields. Full operator and
pattern reference: [references/jql-essentials.md](references/jql-essentials.md).

Core habits:

- Filter on `statusCategory` (To Do, In Progress, Done) for cross-project
  reliability; `status` names vary per workflow.
- `parent = EPIC-123` finds an epic's children.
- Include resolved issues when checking for duplicates or regressions.
- Search with key terms, not sentences: `text ~ "timeout login"`, not the full
  user complaint.

## Scope Discipline

- Never guess the project, board, sprint, or space. If the user has not
  provided one and it cannot be resolved from pinned context or the request,
  ask.
- Prefer one bounded, paginated scope query, then derive answers locally from
  the returned set, over one query per question.
- Follow-up queries only when they support a visible claim the scope data
  cannot.

Delivery workflows in Jira: see `managing-work-in-jira`. Cross-product flows
across Confluence, Jira, and Jira Product Discovery: see
`connecting-atlassian-tools`.
