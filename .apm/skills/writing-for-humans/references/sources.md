# Source notes

This skill borrows useful principles from public writing guidance. It does not claim conformance with any of those standards, and it should not be applied as a collage of checklists.

## What to take

**ASD-STE100, as a discipline rather than a dictionary.** One term for one thing. Clear actor and verb. Keep necessary technical nouns and verbs, and define them when the reader needs that. For procedures, state condition, action, and expected result. Ambiguity is the problem to solve. See [ASD-STE100](https://asd-ste100.org/about_STE.html), [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill), and [tamdogood/orwell-writing](https://github.com/tamdogood/builder-essential-skills/blob/main/skills/orwell-writing/SKILL.md).

**ISO 24495-1 Plain Language.** Relevant, findable, understandable, and usable. Put the reader's need first. Do not omit information the reader needs in order to make the prose shorter. See the [International Plain Language Federation summary](https://www.iplfederation.org/iso-standard/).

**Google Developer Documentation Style Guide and Microsoft Writing Style Guide.** Active voice when the actor matters. Second person for instructions. Consistent terminology. Lead with what the reader needs. Conversational without being frivolous. Break a guideline when doing so makes the content clearer. See [Google style](https://developers.google.com/style) and [Microsoft style](https://learn.microsoft.com/en-us/style-guide/).

**Diátaxis.** Match form to the reader's job: tutorial, how-to, reference, or explanation. Do not force every artifact into one template. See [Diátaxis](https://diataxis.fr/).

**ISO/IEC/IEEE 29148 and INCOSE requirement writing.** Keep problem, constraint, requirement, and design conceptually distinct. A requirement statement should be singular and verifiable. Observations, wishes, and solution ideas are not requirements.

**RFC 2119 / RFC 8174.** Use MUST, SHOULD, and MAY only when the sentence is actually normative.

**arc42, C4, and ADR/MADR.** Explain context, responsibilities, relationships, runtime behavior, constraints, and why a decision was made. Put rejected alternatives in those decision artifacts. Leave them out of current-state operator docs. See [arc42](https://arc42.org/overview), [C4](https://c4model.com/), and [MADR](https://adr.github.io/madr/).

**Wikipedia: Signs of AI writing.** Use it as a field guide to current LLM tells (antithesis, stacked negation, association weasel, placeholder residue, markdown chrome), not as Wikipedia policy. Cadence cleanup still belongs in `stop-slop`. Planning labels in durable names (Phase 1, Option B, workstream) are the same family of process leakage; they belong in this skill's Durable names rule. See [WP:AISIGNS](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing).

**wait-what.** If an explanation would not land, re-pitch it with a little context and the project's own terms. See [mattpocock/wait-what](https://github.com/mattpocock/skills/tree/main/skills/productivity/wait-what).

## What to leave

- ASD-STE100's controlled dictionary, hard sentence-length caps, semicolon ban, and aerospace lockdown
- Microsoft brand-voice friendliness, and the claim that shorter is always better
- Diátaxis as a required document skeleton
- 29148/INCOSE boilerplate as a default for PRDs, plans, and explanations
- RFC 2119 keywords sprinkled through ordinary prose
- Architecture vocabulary used as a substitute for explaining the system

`writing-skills` in this profile is about authoring skills, not about ordinary prose.