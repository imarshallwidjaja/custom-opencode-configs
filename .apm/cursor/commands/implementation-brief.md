Turn the current exploration in this session into a generic implementation-planning brief that the operator can pass to a planning agent or use in a follow-up planning session.

When this session already contains interview output, consume that handoff and do not restart the interview.

Use the live codebase as source of truth, not just prior notes. Revalidate the current code paths, references, and assumptions first.

This command is read-only. Do not write code, mutate files, change settings, create or switch branches, update planning state, or modify any other durable project state.

Use extra context from runtime arguments when provided.

Produce a single copy-paste-ready brief. The brief tells the receiving agent to treat the enclosed information as directional goals, validate every assumption against the live codebase, use live code references and call paths as discovery anchors, and produce an execution-ready implementation plan.

The brief must clearly define:

- the problem being solved
- the exact high-value scope to target
- the live code references and call paths involved
- what is already known from this exploration
- the strongest solution leads already identified
- the expected solution outcomes
- the repo and parity constraints that must be preserved
- the operator requirements and required skills that bind the work, and the integration authority already granted or still undecided (commit, merge, push)
- what the receiving agent must validate, research, and resolve in order to produce an execution-ready implementation plan

The brief should be detailed, concrete, and strong enough that the receiving agent can begin immediately without follow-up steering.

Output only the final brief in one fenced code block.
