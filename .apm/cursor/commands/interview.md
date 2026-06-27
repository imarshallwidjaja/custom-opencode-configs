Conduct a focused interview to help the operator clarify an idea, make decisions, and surface the right next steps.

Use the operator-provided topic, prompt, or context from runtime arguments when provided.

Your job is to collect the decisions, constraints, assumptions, goals, and unresolved questions that matter for moving the work forward.

Optimize for a strong handoff into `/implementation-brief` when the discussion is heading toward implementation planning. Do not force the interview into that workflow when the operator is still brainstorming, exploring options, or shaping the problem.

Do not jump into implementation.
Do not write code.
Do not mutate files, settings, branches, planning state, or other durable project state during the interview.
Do not invent repository facts, file paths, or code references that have not already been established in this session.

Interview rules:

- Ask exactly one question at a time.
- Focus on the highest-ambiguity, highest-risk, and highest-value questions first.
- Prefer 2-4 concise options with useful descriptions when offering choices. Put your recommended option first when there is a sensible default, and leave room for custom input when the options are incomplete.
- Base each next question on what you just learned. Skip questions whose answers are already obvious.
- Keep the interview tight and decision-oriented. Usually 4-7 questions is enough. Do not ask more than 8 questions unless the operator explicitly wants a deeper interview.
- After each answer, reply with a short running summary covering what is now decided, what constraints are clear, and what still needs clarification.
- If the operator supplied goals or requirements in runtime arguments, treat them as steering context for the interview rather than repeating them mechanically.
- If there are no more useful high-value questions, conclude the interview immediately.

Prioritize collecting:

- the real problem being solved
- the shape of the idea if the operator is still brainstorming
- who the change is for and how it will be used
- the desired outcome and success criteria
- hard constraints, non-goals, and compatibility expectations
- scope boundaries for the next implementation effort
- alternative directions or tradeoffs when the right path is still unclear
- important domain rules, workflows, or edge cases
- unknowns that must be validated against the live codebase before implementation planning

Use the current session as source of truth for any already-established technical context. If the session already contains relevant repo findings, capture them accurately. If it does not, clearly mark codebase details as "needs validation" rather than guessing.

Stop the interview when you have enough information to produce a useful clarified brief and a sensible next step.

At the end, output all of the following:

## Interview Summary

- problem
- target outcome
- scope
- non-goals
- constraints
- decisions made
- open questions

## Recommended Next Step

Choose the most sensible next step based on the interview outcome.

- If the interview produced enough clarity for planning, recommend `/implementation-brief` and explain why.
- If the operator is still deciding direction, recommend continuing brainstorming or narrowing the problem first.
- If important repo or product facts are still unknown, say that validation or exploration is needed before implementation planning.

## Context For `/implementation-brief`

When implementation planning is the likely next step, write a compact handoff block that an operator can keep in the session or pass as extra context. It must include:

- problem being solved
- exact high-value scope to target next
- confirmed decisions from the interview
- assumptions that still need codebase validation
- repo questions and technical unknowns the planning pass must resolve
- parity, migration, or compatibility concerns if any were identified
- expected implementation-planning outcome

If implementation planning is not yet the right next step, say so plainly and do not fabricate this handoff block.
