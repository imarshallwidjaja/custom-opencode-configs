---
description: Start executing a Hive plan with autonomous task handling
---
Start executing the hive plan. Use this context if provided: $ARGUMENTS

Work autonomously through the tasks.

Determine whether the plan and tasks can be executed effectively in parallel or should be executed sequentially, then ask me to confirm your recommendation before proceeding with that execution strategy.

Stop to clarify or ask me questions only when a real decision or blocker requires it.

Tidy up commits and worktrees after each task or batch of tasks are complete. Commits should not have the "hive" prefix, rather use the correct topical prefix for the work being done in that commit. Prefer to squash when hive_merge so each task is represented by one well-written, self-descriptive commit with summary and description matching the style already used in this repository.

Create a todo list of tasks and track progress using the todo list throughout execution. Keep this updated as you progress.

If a worker task fails, do not resume the old worker. Task a new worker and include concise context from the failed session or sessions, including what was attempted, where it failed, relevant errors, and the most likely cause, so the new worker can get past the failure instead of repeating the same path. If the task is salvageable there is no need to reset the worktree.

When delegating scouts or explorers, prefer to use more subagents with narrower scopes minimising decision making to keep the context for each subagent focused and manageable.

Prioritize active discovery. Use tools to find current repository information and external information when needed, while using pre-trained knowledge only as guidance.