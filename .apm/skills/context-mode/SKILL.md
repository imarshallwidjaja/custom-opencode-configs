---
name: context-mode
description: |
  Use context-mode tools for large or uncertain output, non-edit file analysis, data processing,
  web fetch and indexing, and browser-output handling. Triggers: logs, tests, command output,
  API responses, snapshots, large files, docs retrieval, and any analysis that would otherwise
  flood context.
---

# Context Mode Operating Policy

This skill provides the detailed execution policy for `context-mode`.

`AGENTS.md` owns the routing contract between `context-mode`, `cymbal`, `ast-grep`, `grep_app`, `context7`, `websearch`, and `read`.
This skill explains how to use `context-mode` well once that routing points here.

## Core rule

Use `context-mode` when output may be large, uncertain, or expensive to carry in chat.

Good fits:
- command output that may exceed a compact summary
- logs, tests, build output, diffs, API responses, and data files
- external docs or web content that should be fetched and searched without dumping raw text into context
- browser snapshots, console output, and network output that can be saved to a file first

Do not use this skill to replace:
- `cymbal` for code navigation
- `ast-grep` for structural search
- `read` for exact edit windows

## Think in code

When you need to analyze, count, filter, compare, parse, transform, or process data, write code through `context-mode` tools and print only the result you need.

Do not pull raw data into chat and process it mentally.

## Tool map

- `ctx_batch_execute`
  - Use when you need to gather multiple command results and search them in one bounded path.

- `ctx_execute`
  - Use for shell, JavaScript, Python, and similar processing when only the final stdout should enter context.

- `ctx_execute_file`
  - Use when reading a file for analysis, summarization, extraction, or counting.
  - Do not use `read` for this unless you need the exact text in context for editing.

- `ctx_fetch_and_index`
  - Use for external docs or web pages that should be fetched and indexed without dumping raw content into context.

- `ctx_search`
  - Use to query indexed content.
  - Batch multiple search questions into one call when possible.

- `ctx_index`
  - Use to index small inline content or file paths.
  - Prefer `path` over `content` for large data so the raw payload does not pass through context.

## Hard boundaries

- Do not use `curl`, `wget`, or inline HTTP in shell when `context-mode` is available.
- Do not use direct URL-fetch tools when `ctx_fetch_and_index` is the correct path.
- Do not use normal shell for commands likely to emit large output when `ctx_execute` or `ctx_batch_execute` can keep the result bounded.
- If a file is being read to edit it, direct `read` is correct.
- If a file is being read only to analyze it, prefer `ctx_execute_file`.
- If another MCP tool has already returned data in context, do not re-index that same raw data with `ctx_index(content: ...)`. Use it directly, or save it to a file first if repeated querying is needed.

## Default workflow

1. Decide whether the task is analysis or editing.
   - Editing needs exact text in context -> use `read`.
   - Analysis needs bounded output -> use `context-mode`.

2. Choose the narrowest tool.
   - multiple commands or follow-up search -> `ctx_batch_execute`
   - one command or script -> `ctx_execute`
   - one file under analysis -> `ctx_execute_file`
   - external docs or page -> `ctx_fetch_and_index` then `ctx_search`

3. Print findings, not dumps.
   - stdout is what enters context
   - summarize the result you need
   - include exact IDs, counts, filenames, or error lines when useful

## Browser and Playwright rule

When a browser tool can save output to a file, always use the `filename` parameter.

Correct pattern:
- browser output -> file
- then `ctx_index(path: ...)` for repeated querying
- or `ctx_execute_file(path: ...)` for one-shot extraction

Do not:
- return large browser snapshots directly into context
- pass large raw browser output to `ctx_index(content: ...)`

This is the critical safety rule for snapshots, console output, and network output.

## Search and indexing guidance

- Use specific technical terms in `ctx_search` queries.
- Use the `source` parameter when multiple documents are indexed.
- Batch related queries into one `ctx_search` call instead of making many small calls.
- Prefer server-side file reads with `path` over inline `content` for large artifacts.

## Short anti-pattern list

- `curl` or `wget` in shell for large fetches
- `cat` or `read` for large-file analysis when you are not editing
- dumping raw JSON, logs, or test output instead of printing findings
- indexing large raw data via `ctx_index(content: ...)`
- returning browser snapshots directly instead of saving to a file first

## References

- `references/patterns-javascript.md`
- `references/patterns-python.md`
- `references/patterns-shell.md`
- `references/anti-patterns.md`
