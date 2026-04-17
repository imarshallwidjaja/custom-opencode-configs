# Anti-Patterns For `context-mode`

Use this file as a quick guardrail when choosing between `context-mode`, shell, and direct reads.

## Common mistakes

### 1. Using `ctx_execute` for tiny output

If the command will return only a few lines, use a normal shell tool instead.

Good examples for normal shell:

- `git status`
- `pwd`
- `which node`
- `wc -l file.txt`

Reserve `context-mode` for output that would otherwise flood context or that needs programmatic reduction.

### 2. Forgetting to print results

`ctx_execute` and `ctx_execute_file` only surface stdout.

Always end the script with `console.log(...)`, `print(...)`, or the equivalent final output call.

### 3. Doing heavy parsing in shell

If the command turns into nested pipes, inline Python, or fragile `jq` and `awk` chains, switch to JavaScript or Python inside `context-mode`.

### 4. Reading large files into chat first

If you only need counts, matches, summaries, or extracted fields, use `ctx_execute_file` instead of loading the whole file through `read`.

### 5. Printing raw objects badly

In JavaScript, use `JSON.stringify(value, null, 2)` for structured output.
In Python, use `json.dumps(value, indent=2)` or format the output explicitly.

### 6. Using timeouts that are too short

Match the timeout to the task.

- file parsing: `5000-10000`
- local computation: `10000`
- API calls: `15000-30000`
- builds and installs: `120000+`
- full test suites: `120000-300000`

### 7. Writing vague search intent

When you use indexed output, ask for the exact thing you need.

Better intents:

- `Report failing test names and error messages`
- `List HTTP 500 endpoints and their counts`
- `Find the sections that define auth token refresh`

## Checklist

Before using `context-mode`, verify:

- output is likely large or uncertain
- you are printing the result you actually need
- the runtime language matches the task
- the timeout matches the operation
- the query or intent is specific enough to be useful
