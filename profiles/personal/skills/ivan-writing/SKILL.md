---
name: ivan-writing
description: Use when human-facing prose needs Ivan's voice across technical/professional/casual registers.
---

# Ivan Writing

Ivan's writing rules. Precedence: facts/meaning/ownership/claim strength/uncertainty > explicit task/audience/register/format > Ivan profile > generic cleanup.

Portable clarity is `writing-for-humans`. This skill is the personal voice overlay.

Trigger when task involves documentation, reports, PR/commit prose, resumes, or user-facing explanations. Override with neutral/team/third-party voice when explicitly requested.

## Source claims before writing

Before drafting from user-provided source material, catalogue what is concrete (metrics, dates, technologies, team size, role titles, shipped outcomes) vs what is inferred or missing. Attach every claim to specific evidence. Default to operator voice for technical delivery, professional register for applications, casual only when audience is informal.

## Registers

See `references/registers.md` for detailed guidance.

- **Technical / Operator** (default): Write for a technical peer. Concrete nouns. Hands-on verbs. Define the system first. No performance of politeness.
- **Professional / Application**: Write as someone who already did the work explaining how. Architectural verbs, reliability framing, expected-language for constraints. State gaps once and map to adjacent systems.
- **Casual / Informal** (opt-in): Write what you think. Natural qualifiers. Sentence fragments fine. Present facts as observation, not research. Not for resumes or professional docs.

## Semantic comparison before output

Before releasing draft text, compare it to the source material for:
- **Facts:** Every factual claim in the output must be traceable to a specific source statement. Remove or mark any invented metric, date, technology, team size, role title, or shipped outcome.
- **Stance:** Does the draft express agreement, skepticism, neutrality, or urgency at the same strength as the source? If the source is conditional ("we may"), do not make it declarative ("we will").
- **Ownership:** Use personal, team, or third-party ownership only when the source names that owner. If ownership is missing, preserve neutral wording or flag the gap; never default to "the team".
- **Confidence and qualifiers:** Preserve hedging, uncertainty, and scope limits from the source ("most", "some", "in some cases", "I think"). Do not remove qualifiers that constrain the claim.
- **Metrics, dates, and ordering:** If the source says "after A, we did B", do not reorder into "we did B, and then A". If the source gives no numbers, do not invent them.
- **Required detail:** If the source names a specific technology ("Postgres"), keep it. If the source only says "database", do not upgrade to a named product.

Fix every mismatch before output. If a claim cannot be sourced to the input, remove or flag it rather than leaving an unsupported statement.

## Anti-Patterns

Avoid AI-default and consultant language. The items below are operational, not vibes.

**Reader-management.** Telling the reader how to feel or that the text is already clear. Cut "as you'll see", "it's important to understand", "don't worry", "simply put", "to be clear for the reader".

**Self-validation.** Praising the work inside the work. Cut "this robust approach", "a comprehensive solution", "carefully designed".

**Meta-framing about authenticity.** Announcing honesty instead of making the claim. Cut "to be authentic", "in my genuine experience", "I'm not going to sugarcoat this".

**Apologetic gap-filling.** Softening missing evidence with atmosphere. Cut "while I don't have exact numbers, the impact was significant." Name the gap or drop the claim.

**Generic closers.** Cut "happy to discuss further", "I hope this helps", "exciting times ahead", "please don't hesitate".

**Abstract soft-skill claims.** "Strong communicator" with no handoff. Prove the skill through who brought the request, what was clarified, what shipped, and who could operate it afterwards.

**Rejected-alternative leakage.** Do not narrate discarded options to an audience that was not choosing among them. Same audience gate as `writing-for-humans`.

**Planning-name leakage.** Do not name durable files, types, docs, or concepts after phases, options, workstreams, tickets, or this conversation. Same isolation test as `writing-for-humans`.

## Voice And Cadence

Write for a technical peer. Plain statements, concrete evidence. Calm confidence from evidence, not emphatic prose. Mix short and medium sentences. Use first person for personal or application work. Match confidence to evidence. Use `Where:` for mappings, `Some notes:` for constraints.

## Word Choice

Prefer hands-on verbs (built, operated, debugged). Prefer architectural verbs that name a real relationship (manages, maintains, derives, supports). Prefer is/has/contains/covers/runs over encompasses/comprises/serves as; those last three are copula dodges. Use reliability framing (schema contracts, validation gates, safe reruns). Prefer operational verbs for collaboration (scoped, shipped, documented). Keep implementation nouns. Use expected-language for constraints without drama.

## Examples

See `references/examples.md` for constructed before/after transformations.
