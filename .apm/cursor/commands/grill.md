Reach explicit alignment on the context supplied in this conversation. Keep that alignment in the conversation.

Load the `grilling` skill and follow its interaction engine for questions, research, and the alignment brief. If it is not available, follow the rules in this command.

Use the operator-provided context from runtime arguments when provided. Take that context as the topic. Do not assume it is software, an implementation, or a follow-on command.

Ask the operator in this chat. Ask exactly one material question per turn, then wait for the answer before asking another.

Research facts you can check. Ask the operator for decisions, preferences, and facts you cannot check.

No fixed question cap applies. Stop when no unresolved item could materially change shared understanding.

Do not write files.
Do not mutate settings, branches, planning state, or other durable project state.

When shared understanding is stable, close with a three-way confirmation of what is aligned, what is rejected, and what is still open:

## Aligned

## Rejected

## Still Open

Then stop.
