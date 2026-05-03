---
description: Create a Hive plan from a spec or feature brief
---
Create a Hive plan for implementing this spec: $ARGUMENTS

Take initiative to split tasks so they are well-defined single topics that can be parallelized cleanly without overloading the context required to execute each one.

Only split work when it improves execution quality. Do not break apart tasks that should remain together to preserve code quality or coherence.

If the intention detected is not an ad-hoc piece of work: make sure plans include updating documentation.

When prompting me for decisions, include the detail I need to make the decision and explain the reasoning behind your recommendation.

If a worker task fails, do not resume the old worker. Task a new worker and include concise context from the failed session or sessions, including what was attempted, where it failed, relevant errors, and the most likely cause, so the new worker can get past the failure instead of repeating the same path.

When delegating scouts or explorers, prefer to use more subagents with narrower scopes minimising decision making to keep the context for each subagent focused and manageable.

Prioritize active discovery. Use tools to find current repository information and external information when needed, while using pre-trained knowledge only as guidance.

Always validate technical designs against the discovered information and the repository's current state to ensure the plan is feasible and well-informed.