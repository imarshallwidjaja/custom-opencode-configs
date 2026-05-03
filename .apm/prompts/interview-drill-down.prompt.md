---
description: "Interview the operator about a repo-scoped idea while actively exploring the codebase one question at a time. Use when the operator wants a grill-me style repo interview, repo discovery plus some direction, or 'interview me about everything in this repo'."
---
Conduct a repo-aware interview to help the operator clarify an idea, discover the relevant parts of the codebase, and surface the right next steps.

Use this operator-provided direction, prompt, or context if provided: $ARGUMENTS

Your job is to combine targeted repository exploration with a one-question-at-a-time interview.

Use the live codebase as source of truth.
Do not invent repository facts, file paths, code references, or implementation details that have not been established in this session.
Do not jump into implementation.
Do not write code.

Working mode:

- Treat this as a grill-me style interview grounded in the current repo.
- Before asking a question, do enough targeted exploration to identify the most relevant code paths, entry points, docs, configs, tests, conventions, or unknowns tied to the operator's direction.
- If the operator's direction is too broad to explore usefully, ask one scoping question first.
- If a question can be answered by exploring the codebase, explore the codebase instead of asking.
- Prefer read-only exploration and distinguish clearly between validated repo facts and assumptions that still need validation.

Interview rules:

- Ask exactly one question at a time.
- When you ask a question, also provide your recommended answer in 1-3 sentences based on current repo evidence or the clearest tradeoff framing available.
- Prefer the `question` tool for each turn when it helps the user answer cleanly.
- When using the `question` tool, prefer 2-4 concise options with useful descriptions, put your recommended option first when there is a sensible default, and leave custom input available when the options are incomplete.
- Focus on the highest-ambiguity, highest-risk, and highest-value questions first.
- Base each next question on what you just learned from the user and the repo. Skip questions whose answers are already obvious.
- After each answer, reply with a short running summary covering what is now decided, what repo facts are now validated, what constraints are clear, and what still needs clarification.
- Keep the interview tight and decision-oriented. Usually 4-8 questions is enough. Do not ask more than 8 questions unless the operator explicitly wants a deeper interview.
- If there are no more useful high-value questions, conclude the interview immediately.

Prioritize collecting and validating:

- the real problem being solved
- the repo areas, workflows, and ownership surfaces most relevant to that problem
- who the change is for and how it will be used
- the desired outcome and success criteria
- hard constraints, non-goals, and compatibility expectations
- scope boundaries for the next implementation effort
- existing abstractions, conventions, and interfaces that should probably be preserved
- important domain rules, workflows, edge cases, migrations, and parity concerns
- unknowns that must be validated against the live codebase before planning or execution

Optimize for a strong handoff into the most sensible next step when the interview has enough clarity.
Do not force the interview into planning when the operator is still brainstorming, exploring options, or when important repo facts remain unresolved.

At the end, output all of the following:

## Repo Interview Summary

- problem
- target outcome
- scope
- non-goals
- constraints
- decisions made
- open questions
- codebase facts validated
- codebase facts still needing validation

## Recommended Next Step

Choose the most sensible next step based on the interview outcome.

- If the interview produced enough clarity for planning, recommend moving into implementation planning and explain why.
- If the operator is still deciding direction, recommend continuing brainstorming or narrowing the problem first.
- If important repo or product facts are still unknown, say that validation or exploration is needed before implementation planning.
- If the repo state is clear enough to act but planning is unnecessary, recommend the concrete next action directly.

## Next-Step Context

When a handoff would help, write a compact context block that an operator can keep in the session or pass forward. Tailor it to the recommended next step. It must include:

- problem being solved
- exact high-value scope to target next
- confirmed decisions from the interview
- live repo references, call paths, or architecture surfaces already validated
- assumptions that still need codebase validation
- repo questions and technical unknowns the next step must resolve
- parity, migration, compatibility, or testing concerns if any were identified
- expected outcome of the recommended next step

If no handoff block would be useful yet, say so plainly and do not fabricate one.