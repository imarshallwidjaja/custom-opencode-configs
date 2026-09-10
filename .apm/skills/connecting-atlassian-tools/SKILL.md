---
name: connecting-atlassian-tools
description: Connect Confluence, Jira, and Jira Product Discovery through Atlassian MCP workflows, cross-product search, spec-to-backlog flows, reporting, traceability, idea intake, and Teamwork Graph queries. Use when work spans Atlassian products, searches knowledge known to be in Atlassian with the source product unresolved, or targets Jira Product Discovery or Teamwork Graph. Generic company-knowledge searches, product ideas, and local coding tasks do not trigger this skill without Atlassian context.
---

# Connecting Atlassian Tools

## Applicability

Use for workflows across Atlassian products, knowledge searches within a known
Atlassian context whose source product is unresolved, Jira Product Discovery
(JPD), or Teamwork Graph questions. Generic company-knowledge searches, product
ideas, local implementation plans, debugging, code review, and ad-hoc subagent
handoffs do not qualify without an Atlassian target.

`working-with-atlassian` is the prerequisite for tool use and safety. Load
`managing-work-in-jira` only for Jira operations, `decomposing-work` when designing
a product backlog breakdown, and `writing-work-items` when drafting or reviewing
its items. Cross-product search and reporting do not require those authoring
methods. `running-agile-delivery` requires its own explicit adoption before its
governance applies; a cross-product workflow does not activate it.

## Search Routing

| Situation | Route |
| --- | --- |
| Source system unknown, or the question spans products | Rovo `search` first |
| User names the system, or refining a broad hit | Targeted `searchJiraIssuesUsingJql` or `searchConfluence` |
| A top hit needs full context | Fetch it: `getConfluenceContent` (markdown) or `getJiraIssue` |

Rules:

- Start with `search` for anything cross-product; refine with JQL or CQL only
  when results need narrowing.
- Fetch full content only for the top hits that will actually inform the
  answer, not for every result.
- Cite sources: page titles with URLs, issue keys with links.
- Flag conflicts and staleness explicitly. When documentation and tickets
  disagree, present both with dates rather than silently picking one.

## Confluence As Spec And Reporting Layer

Confluence holds specs going in and status going out; Jira holds the work.

Spec to backlog:

1. Fetch the spec page with `getConfluenceContent` in markdown format.
2. Decompose it into an epic and children (theory: `decomposing-work`,
   `writing-work-items`).
3. Create the backlog per `managing-work-in-jira`: metadata first, proposal
   for approval, epic before children.

Status back to Confluence:

- Create vs update: update the existing report page when one exists for the
  reporting cadence (`updateConfluenceContent`); create a new page
  (`createConfluenceContent`) for a new report series or a point-in-time
  snapshot the user wants preserved. Ask when the user's intent is unclear.
- Read the page before updating and supply a short version message describing
  what changed, so page history stays useful.

Traceability, both directions:

- Pages reference issue keys (Jira keys in Confluence render as live links).
- Issues reference page URLs in the description or a comment ("Source spec:
  <url>").
- When a backlog is created from a spec, put the spec URL in the epic and the
  epic key on the spec page (with approval for the page edit).

## Jira Product Discovery

JPD has no primary tools. Everything routes through `discover` plus the
execute-family, and operation names must come from `discover` at runtime,
never from memory or this skill. The flows below name goals to describe to
`discover`, not operation names.

Reading ideas: JPD projects are custom-field-heavy (impact, effort, insights,
roadmap fields). Use `view: evidence` or `view: full` when reading ideas, or
the compact default will hide most of what matters.

Canonical flows:

| Flow | Shape |
| --- | --- |
| Idea intake | Discover idea-creation operations ("create a product discovery idea"); propose the idea summary and description for approval; `executeWrite` |
| Enriching ideas | Discover insight operations ("add an insight to an idea"); attach evidence such as customer feedback, support ticket links, or research notes to the idea |
| Promoting to delivery | Create the epic in the delivery project per `managing-work-in-jira`, then link epic and idea both ways: the epic key on the idea, the idea link on the epic |

JPD writes follow the same propose-approve-execute loop as any work-creating
write.

## Teamwork Graph

For relationship questions, not CRUD:

- `getTeamworkGraphContext` when the question is who or what is connected to
  this work: related pages, people, goals, linked pull requests, builds.
- `getTeamworkGraphObject` on the key linked entities the context response
  surfaces, to get richer detail on each.
- Do not use graph tools to read or write issues and pages; the product tools
  do that.

## End-To-End Example

Discovery idea to shipped status report:

1. Capture the idea: `discover`, propose, `executeWrite`.
2. Enrich it with insights: `discover`, `executeWrite`.
3. Publish the validated one-pager with `createConfluenceContent`.
4. Fetch it with `getConfluenceContent` and decompose.
5. Create the epic and stories per `managing-work-in-jira`.
6. Link both ways: epic key on the idea and one-pager; one-pager URL and idea link on the epic.
7. Report delivery status with `searchJiraIssuesUsingJql`.
8. Publish the report with `updateConfluenceContent`.
