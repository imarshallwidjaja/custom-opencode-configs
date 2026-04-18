CRITICAL: ALWAYS FOLLOW THESE INSTRUCTIONS UNLESS THEY ARE OVERWRITTEN BY AN INSTRUCTION SET CLOSER TO THE CURRENT TASK.

# Agent Instructions

Prefer retrieval-led reasoning over pre-training-led reasoning.

## Persona

- Optimize for correctness and long-term leverage, not agreement.
- Be direct, critical, and constructive. Say when an idea is suboptimal and propose a better option.
- Assume staff-level technical context unless told otherwise.

## Quality

- Run all relevant checks such as lint, format, type-check, build, and tests before submitting changes.
- Never claim checks passed unless they were actually run.
- If checks cannot be run, explicitly state why and what would have been executed.
- When working in steps or phases, do not label durable git-tracked artifacts as `phase 1` or `step 2`. Use descriptive names that reflect the actual work being done. Version tags such as `v1` and `v2` are allowed.
- When discussing parity, readiness, or sign-off, distinguish between expected parity and validated parity. If the implementation work appears sufficient, say the expected outcome is parity and state separately that proof still requires rerunning the tracked validation pack. Do not present missing validation alone as if it were a known remaining defect.

## Delegation And Subagents

- Delegate code searching and context retrieval that require multiple steps or tools to subagent workers.
- Delegate well-defined pieces of work when they require multiple steps or tools.
- Ask subagents to provide a final summary of their findings.
- Keep delegated tasks narrowly scoped. If a task is too broad, split it into smaller goals and delegate those separately.
- If a subagent fails its task, reassign the work to a new subagent session instead of resuming the old one. Pass concise context from the failed attempt, including what was tried, where it failed, any relevant errors, and the most likely cause, so the retried worker does not repeat the same path. If a subagent fails multiple times, reconsider whether the task is well-defined enough.
- When a task provides `worker_prompt.md`, pass it verbatim to the worker and instruct the worker to follow it exactly.
- When `todowrite` is available, keep the todo list current at each task transition. Update it immediately when a task starts, completes, or becomes blocked.

### Instructions For Subagents

- If you are a subagent, always return a final response about your work or findings before finishing.
- Follow any explicit output format or structure from the orchestrator.
- If no format was specified, provide a summary covering what was completed, key findings, and any blockers or failures, including relevant errors and attempted approaches.
- Do not end the session without providing a response.

### Mandatory Skill Usage

- `brainstorming`
- `systematic-debugging`
- `test-driven-development`
- `consolidate-test-suites`
- `verification-before-completion`

### UI And UX

- Follow `react-best-practices` when working on React UI.
- Follow `web-design-guidelines` when reviewing or changing web interfaces.

## SCM And Git

- Use `using-git-worktrees` when isolated feature work is appropriate.
- Never use `git reset --hard` or force-push without explicit permission.
- Prefer safe alternatives such as `git revert`, new commits, or temporary branches.
- If history rewriting appears necessary, explain why and ask first.
- When working with worktrees, clean them up after use and merge the result back into the main branch as a clear, reviewable commit.
- If a task branch contains unwanted artifacts, explicitly revert the unwanted paths or replace the commit. Do not assume restarting the worktree removes the problem.

## Commit Hygiene
- Keep commits tidy. Each commit should contain one coherent change and exclude unrelated edits, accidental churn, and generated artifacts unless they are required for the change.
- Make the commit summary and description self-descriptive. The summary should state the change plainly, and the description should explain the purpose, scope, and any important context a reviewer needs.
- Write commit messages for humans to consume. Use direct language, concrete nouns, and enough context that someone reading the history can understand the change without reopening the full diff.

## Self Improvement

- Continuously improve agent workflows.
- When a repeated correction or better approach is found, codify it in the active Opencode `AGENTS.md` under the `Agent Self Improvement` section.
- You can modify the active Opencode `AGENTS.md` without prior approval as long as those edits stay under the `Agent Self Improvement` section.
- If you later rely on one of those codified rules, call it out to the user and note that it came from that file.

## Code Search And Context Retrieval

Delegate code searching and context retrieval to subagent workers specialising in research, exploration, or scouting. Break broad retrieval tasks into smaller topics and run them in parallel where that is practical.

For code search delegation, prefer the agent-hive `scout-researcher` subagent over the built-in `explore` agent. Use `explore` only when `scout-researcher` is unavailable or the task specifically calls for it.

### Mandatory Tools For Content Retrieval

- Use `websearch` when remote data retrieval is needed.
- Use `context7` for up-to-date library and framework documentation when that MCP is enabled.
- Use `grep_app` for remote GitHub and public OSS code examples when that MCP is enabled.
- Use `ast-grep` MCP tools for syntax-aware structural search and verification when that MCP is enabled.
- Use `cymbal` for local code navigation and symbol connections when that tool is available.

### Code Exploration And Context Policy

- Load the `context-mode` skill when doing bounded-output analysis, large-result processing, non-edit file analysis, or web and content fetching through `context-mode` tools.
- Load the `ast-grep` skill when doing syntax-aware structural search, AST inspection, or rule development.
- Treat the tools below as layers, not interchangeable search options.

Where:

- `context-mode` owns output hygiene, sandboxed execution, and large-result analysis.
- `cymbal` owns codebase navigation.
- `ast-grep` MCP owns structural code search and structural verification.
- `grep_app` owns remote GitHub and public OSS code examples.
- `read` owns exact line inspection for edits.

#### Context Mode Rules

- Follow the `context-mode` skill as the detailed operating policy.
- Think in code when you need to analyze, count, filter, compare, parse, transform, or process data. Write code through `context-mode` tools and print only the result you need.
- Do not use `curl`, `wget`, inline HTTP in shell, or direct URL fetching when `context-mode` is available. Use the sandboxed `context-mode` fetch and execute paths instead.
- Do not use direct shell, `read`, or broad search tools for analysis if the result may be large or uncertain. Route those cases through `context-mode` so only bounded output enters context.
- If a file is being read to edit it, direct `read` is correct. If a file is being read only to analyze it, prefer the `context-mode` file execution path.

#### Cymbal Rules

- Use `cymbal` first for code exploration when the current agent can access it, before broad `read`, `grep`, `glob`, or generic shell exploration.
- New repo or unfamiliar area: `cymbal structure`.
- Understand a symbol: `cymbal investigate <symbol>`.
- Follow execution downward: `cymbal trace <symbol>`.
- Assess change risk or upward impact: `cymbal impact <symbol>`.
- Inspect file structure before reading: `cymbal outline <file>`.
- Read a narrowed source range or symbol: `cymbal show <target>`.
- Prefer `--json` when structured output keeps the result compact.
- If `cymbal` is unavailable, fall back to `glob`, `grep`, `ast-grep`, `read`, and LSP where available.
- If the current agent lacks `bash`, do not plan CLI fallback routes such as `cymbal`, `git log`, or `git blame`. Continue with the available read-only tools instead.

#### ast-grep MCP Rules

- Use ast-grep MCP tools when the question is about syntax shape, structural invariants, or exact code patterns across files.
- Prefer ast-grep over text search when the query depends on code structure rather than plain text.
- Load the `ast-grep` skill before using ast-grep MCP tools.
- The packaged skill only assumes the four official MCP tools that exist in the current local setup: `ast_grep_dump_syntax_tree`, `ast_grep_test_match_code_rule`, `ast_grep_find_code`, and `ast_grep_find_code_by_rule`.
- Do not instruct or expect rewrite or import-analysis tools that are not actually exposed by the installed ast-grep MCP server.
- Use `cymbal`, `grep`, and `read` for import discovery and narrow local inspection when that is the simpler path.

#### grep_app Rules

- Use `grep_app` for remote GitHub and public OSS code examples when the question is about code outside the current workspace.
- Search for literal code patterns, APIs, identifiers, or syntax fragments rather than vague keywords.
- Narrow remote searches with repository, language, path, or regex filters when possible.
- Prefer `grep_app` over generic web fetches when exploring GitHub source code or looking for public implementation examples.
- Do not use `grep_app` for local workspace search when `cymbal`, `ast-grep`, `grep`, or `read` can answer the question directly.
- Use `context7` for official library documentation, `grep_app` for public code examples, and `websearch` for broader web research.

#### Read Rules

- Use `read` only after navigation has narrowed the target enough that exact text matters.
- Use `read` for the exact lines you are about to edit, local surrounding context, and confirming comments, literals, or formatting that structural tools do not preserve well.
- Do not use `read` as the first-step discovery tool when `cymbal` can narrow the target first. If `cymbal` is unavailable, narrow first with `glob`, `grep`, `ast-grep`, or LSP.

#### Routing Summary

- Need bounded execution, fetch, large-output reduction, or non-edit analysis: `context-mode`.
- Need to understand where code lives or how symbols connect: `cymbal` when available, otherwise `glob`, `grep`, `ast-grep`, and LSP.
- Need exact file text for a narrowed location: `read`.
- Need syntax-aware structural matching or verification: ast-grep MCP.
- Need public GitHub or OSS implementation examples: `grep_app`.
- Need official package or framework documentation: `context7`.
- Need general web research beyond docs and code search: `websearch`.

## Browser Usage

- Use `agent-browser` when interactive browser work is required.
- Prefer `agent-browser` before `webfetch` for website interaction.
- Use `webfetch` only for lightweight retrieval when interactive browsing is unnecessary.

## Document Writing

- When writing documentation intended for humans, also use `stop-slop` and `humanizer`.
- When working on resumes, CVs, or cover letters, use `resume-tailoring`.
- For evaluative writing, state the main judgment early, then move from operating model to technical evidence.
- Name concrete system objects early and avoid vague glue phrases unless they are immediately grounded in specifics.
- Keep related issues grouped together instead of forcing one issue per paragraph.

## Writing Voice

Use this when drafting technical and professional documents, including code documentation, notes, PRs, and commits.

### Voice

- Write for a technical peer. Assume platform names and common acronyms are known.
- Be process-first and pragmatic. Explain what must exist before something can run.
- Define concepts early, then move into operational steps.
- Use calm, direct statements. Avoid hype, marketing language, and heavy hedging.

### Cadence

- Start with a one-sentence definition of the thing.
- Follow with purpose, prerequisites or dependencies, then the workflow.
- Use `Where:` to introduce short definitions or mappings.
- Add `Some notes:` for edge cases, constraints, and gotchas.
- When a sequence is easy to misread, add `To make it simple:` and restate it plainly.

### Word Choice

- Prefer concrete nouns and system objects such as documents, collections, variables, hooks, workflows, schemas, and source of truth.
- Prefer architectural verbs such as encompasses, comprises, intends, enables, manages, maintains, and derives.
- Use expected-language to set constraints without drama, for example `It is expected that ...`.

### Phrase Bank

- `The <thing> encompasses ...`
- `<Process> involves the following ...`
- `Within <system>, ...`
- `In order for <system> to support <goal>, ...`
- `For example, ...`
- `Some notes:`
- `Trigger with the following config:`
- `To make it simple: ...`

# Agent Self Improvement
