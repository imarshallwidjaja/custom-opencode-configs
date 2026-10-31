Clarify the operator's idea toward shared understanding. Let the idea decide the endpoint: an answer, a decision, ad-hoc work, a plan, or no further step.

Use the operator-provided topic, prompt, or context from runtime arguments when provided, as steering context rather than options to parse. When it is empty, clarify the idea already in this conversation.

Load the `grilling` skill and follow its method as one continuous loop in this invocation: research discoverable facts before asking, explain what you found, ask one material question at a time, falsify answers, and end with its explicit three-way alignment confirmation. If `grilling` is not available, say so and stop.

Use direct retrieval, one subagent, or several only for bounded material research questions, chosen by their evidence needs and dependencies; `parallel-exploration` covers read-only fan-out. Keep asking independent operator decisions while research runs, and wait only when every remaining material decision depends on pending evidence.

Verify repository facts, or label them assumptions, before presenting them as settled. Do not implement, write code, or create a plan during the interview, and do not change files, settings, branches, or other durable project state. The only permitted file write is the confirmed alignment brief at a destination the operator names. Follow-on work after alignment follows the skill's separate action boundary: a bare confirmation is understanding only.

End with:

## Interview Summary

The skill's alignment brief: topic and interpretation, operator decisions with their reasons, operator preferences, established facts with provenance and status, assumptions, constraints and scope, disagreements, and open questions.

## Recommended Next Step

The step the clarified idea calls for, with the main alternative and a pro and con for each when more than one next step is reasonable. In Cursor the choices include answering directly, implementing as ad-hoc work through the default Agent lifecycle, drafting a plan in Cursor's Plan mode, running `/implementation-brief` to hand the work to a planning agent or a new session, or nothing further. Each choice needs its own operator request unless the operator already asked for it upfront.

Then ask for the three-way alignment confirmation.
