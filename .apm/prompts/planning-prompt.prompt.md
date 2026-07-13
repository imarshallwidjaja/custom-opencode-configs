---
description: Turn current exploration into a strong planning-agent prompt
---
Turn the current exploration in this session into a strong base prompt for a planning agent.

Use the live codebase as source of truth. Revalidate the important references, assumptions, and scope against the current working tree before writing anything.

Use this extra context if provided: $ARGUMENTS

Your job is to produce a single copy-paste-ready prompt that another agent can use to prepare the real implementation plan.

Do not produce the implementation plan itself.
Do not write code.
Do not give me a lightweight summary.
Do not make the prompt generic or vague.

The prompt you write should clearly capture:

- the problem we are solving
- the concrete scope in play
- the exact code paths, files, and references that matter
- the findings we already established
- the strongest solution directions or replacement/reduction leads we already identified
- the expected implementation outcomes
- the important repo constraints, parity constraints, and semantic constraints
- the boundaries of what is in scope and what is not
- the expectation that the next agent must do the research, validation, and planning work needed to produce an execution-ready implementation plan

The result should be:

- detailed
- technically grounded
- execution-oriented
- consistent with the current repo state
- written so the next agent can start without extra steering

Output only the final prompt, in one code block, ready to hand to another agent.
