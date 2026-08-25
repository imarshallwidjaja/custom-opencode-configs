---
name: writing-for-humans
description: Use when drafting or explaining code, architecture, systems, processes, decisions, requirements, PRDs, product outcomes, plans, technical documentation, reviews, ADRs, or similar software and product work.
---

# Writing for Humans

Write as a technically competent human who is trying to make something genuinely easy for another human to understand. The reader should notice that the writing is easier, not that a style framework was applied.

This is the default generative discipline for software and product writing. Apply it while drafting. Do not announce it. Adapt voice and structure to the artifact and audience.

## Principles

1. **Start from the reader.** Give them what they need in order to act or decide. Make that information findable, understandable, and usable. Leave out decoration. Do not omit a condition, exception, or uncertainty the reader needs.

2. **Name things stably.** Pick one term for each thing and keep it. Preserve necessary technical vocabulary. If the likely reader may not know a term, define it once in context. A name should still make sense when encountered in isolation.

3. **Keep subjects, verbs, and relationships explicit.** Name the actor when the actor matters. Say what depends on what, what runs when, and who owns which responsibility. Prefer verbs for actions.

4. **Give enough context, then the point.** A reader who arrives mid-document should still understand why the next statement matters. If an explanation would not land without a frame, supply a short one.

5. **Use structure for navigation.** Headings, lists, and tables help when they match the information. Do not convert continuous reasoning into bullets, tiny paragraphs, or a template just to look organized.

6. **Keep meaning intact.** Preserve hedges, scope, trade-offs, and causal explanation. Do not make a claim sound more certain because a shorter sentence would. Do not collapse distinct ideas into one slogan.

7. **Match the job of the document.** A how-to should help a competent person do a job. An explanation should help someone understand why. Reference should state facts. Requirements should be testable statements of need, not designs, observations, or product principles.

## Cadence

Write prose that can be read continuously. Paragraphs may contain several related sentences. Sentence length may vary. A semicolon is allowed when it joins two closely related clauses.

Brevity is useful when it improves understanding. Cutting words is not the goal.

Do not manufacture importance or tension. Avoid antithesis frames such as "This isn't about X. It's about Y." Avoid stacked negation such as "It's not X, and it's not Y, but it is Z." Avoid the related cadence: dramatic sentence fragments, chains of one-line paragraphs, Stop/Start couplets, "I used to / then I learned" setups, rhetorical setup and payoff, repeated three-part slogans, and phrases written mainly to sound quotable. That register is LinkedIn cadence. Do not reach for "this changes everything", "the real problem is", or "here's the thing" when an ordinary explanation would do.

If existing prose already has that cadence, load `stop-slop`. If it is promotional, chatbot-like, or padded with vague AI vocabulary, load `humanizer`. If the user wants Ivan's personal voice, load `ivan-writing`.

## Rejected alternatives

Name a discarded option only when this reader would otherwise reopen it or misread the current state.

Keep them in ADRs, design reviews, and answers to "why not X?" Keep a live operational contrast that the reader must handle, such as "writes still go to Postgres."

Drop them from README current-state sections, commit messages, PR summaries, and status replies unless the ask was to justify the approach. "I didn't use X because", "rather than rewriting", "I considered A, B, and C", "this does not affect Y", and "while preserving Z" are process narration when the reader never held those alternatives.

Architecture writing still states trade-offs the operator has to live with. It does not recap the menu of options you personally discarded.

## Durable names

Name code, files, docs, components, branches that become the thing's identity, and concepts by purpose, responsibility, domain meaning, or outcome. Do not encode temporary planning context.

Do not use Phase 1, Option B, Workstream 2, ticket-only labels, "final"/"new" versioning from this conversation, or other deliberation vocabulary as the durable name. Prefer `coverage-processing` over `phase-1`, and `scene-ingestion` over `workstream-2`. "Option B" as a filename is the naming form of rejected-alternative leakage.

Keep a planning identifier only when it is a first-class concept whose meaning is defined alongside the artifact: an RFC number, a CVE, a public protocol version, a tracker ID in a commit subject when that is the repo contract. Do not put that identifier in the type, module, or heading if the reader would have to open an external doc or this chat to know what the thing does.

Scratch paths that will be deleted can be messy. Git-tracked and exported names cannot.

## Artifact instincts

**Code and systems.** Name the concrete objects by what they do. Say what must exist before something can run. Prefer inputs, outputs, state, handoff points, and failure boundaries over capability claims.

**Architecture.** Make responsibilities, relationships, runtime behavior, assumptions, trade-offs, constraints, and reasons understandable. Start from context and the problem being solved. State the trade-off an operator must live with. Do not list discarded options the reader was not considering. Boxes, layers, and "components" are not a substitute for those facts.

**Product writing.** Keep the underlying problem, desired outcome, evidence, constraints, success criteria, and proposed capability conceptually distinct. An observation is not a requirement. A capability is not a success criterion.

**Requirements and contracts.** Write one need per statement when the text is actually a requirement. Prefer verifiable wording. Use MUST, SHOULD, and MAY only when the statement is normative; leave them out of ordinary explanation. Do not hide a design choice inside a requirement.

**Reviews.** Lead with the finding. Give file or evidence references. Separate defects from preferences.

## Examples

Constructed. They show the intended voice, not a required house style.

### Architecture

**Before:**
> This isn't just a cache. It's the backbone of our scale story. The real problem is that reads were slow. Here's the thing: we put Redis in front of Postgres. Game-changer.

**After:**
> Read latency on the product catalogue was exceeding 400 ms on cache misses, which made the storefront feel stuck during traffic spikes. We added a Redis cache in front of Postgres so repeated catalogue reads are served from memory. Writes still go to Postgres first; the cache is invalidated on publish. That improves the common read path, and it also means a cache failure must fail open to Postgres rather than fail the page.

### Product

**Before:**
> Users want a seamless, intelligent workspace. We should build an AI-native dashboard that changes how teams collaborate. The outcome is better alignment.

**After:**
> Onboarding interviews (n=8) showed that new teammates cannot tell which launch checklist is current, and they ping the duty engineer to find out. The desired outcome is that a teammate can identify the current checklist without asking. Success is that, in the next onboarding cohort, fewer than two people ask that question in their first week. The proposed capability is a single pinned "current launch checklist" page, with one owner and a last-updated timestamp. We are not replacing status meetings in this pass.

## Related skills

- `stop-slop` for filler, LinkedIn cadence, antithesis, stacked negation, and other cadence cleanup of existing text
- `humanizer` for promotional tone, vague attributions, chatbot artifacts, and AI-vocabulary clusters
- `ivan-writing` when the prose should represent Ivan's personal voice

## Additional resources

- Provenance and source notes: [references/sources.md](references/sources.md)
- Further examples: [references/examples.md](references/examples.md)
