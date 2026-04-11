---
description: Turn current exploration into a strong implementation-planning prompt
---
Turn the current exploration in this session into a strong implementation-planning prompt for another agent.

Use the live codebase as source of truth, not just our prior notes. Revalidate the current code paths, references, and assumptions first.

Use this extra context if provided: $ARGUMENTS

I want a single copy-paste-ready prompt that tells another agent how to prepare the real implementation plan for this work.

Do not produce the implementation plan itself.
Do not write code.
Do not give me a short recap.
Do not soften uncertainties by being vague. Anchor everything in the current repo state.

The prompt must clearly define:

- the problem being solved
- the exact high-value scope to target
- the live code references and call paths involved
- what we already know from this exploration
- the strongest solution leads already identified
- the expected solution outcomes
- the repo and parity constraints that must be preserved
- what the next agent must validate, research, and resolve in order to produce an execution-ready implementation plan

The prompt should be detailed, concrete, and strong enough that the next agent can begin immediately without follow-up steering.

Output only the final prompt in one code block.
