---
name: ivan-writing
description: Use when writing technical or product prose to or as Ivan, or when Ivan's personal voice is selected for other prose.
---

# Ivan Writing

Ivan's writing rules. Precedence: facts/meaning/ownership/claim strength/uncertainty > explicit task/audience/register/format > Ivan profile > generic cleanup.

Portable clarity is owned by `writing-for-humans` and the active prose router. For substantial prose, load `writing-for-humans` before drafting and apply its audience, technical clarity, and artifact guidance where relevant. This skill selects Ivan's register and, when appropriate, personal voice.

Use the technical/product register for technical or product prose prepared to Ivan or authored as Ivan. Voice and register are separate: preserve requested neutral, team, or third-party authorship. Internal worker reports stay neutral unless requested. PR and review drafts require explicit operator selection of personal voice under `pr-writing`.

## Source claims before writing

Before drafting from source material, distinguish concrete facts from inference and gaps, and attach claims to evidence. Keep ordinary short answers proportionate.

## Registers

Read `references/registers.md` when choosing a register or adapting it to the audience.

- **Technical / Product** (default): Choose vocabulary for the actual reader, including product stakeholders. Use stable terms and explicit relationships; preserve necessary domain terms and identifiers. Precision comes before compression. This is ASD-STE100-inspired, not formal compliance, a controlled dictionary, or a sentence-length rule.
- **Professional / Application**: Write as someone who already did the work explaining how. Architectural verbs, reliability framing, expected-language for constraints. State gaps once and map to adjacent systems.
- **Casual / Informal** (opt-in): Write what you think. Natural qualifiers. Sentence fragments fine. Present facts as observation, not research. Not for resumes or professional docs.

For working product-alignment notes or structured brain dumps, prefer short task-based sections with list-led peer ideas and brief commentary. Use prose for causal reasoning; distinguish workflows, useful outputs, and mechanisms when present.

## Semantic comparison before output

Before releasing draft text, compare it to the source material for:
- **Facts:** Every factual claim in the output must be traceable to a specific source statement. Remove or mark any invented metric, date, technology, team size, role title, or shipped outcome.
- **Stance:** Does the draft express agreement, skepticism, neutrality, or urgency at the same strength as the source? If the source is conditional ("we may"), do not make it declarative ("we will").
- **Ownership:** Use personal, team, or third-party ownership only when the source names that owner. If ownership is missing, preserve neutral wording or flag the gap; never default to "the team".
- **Confidence and qualifiers:** Preserve hedging, uncertainty, and scope limits from the source ("most", "some", "in some cases", "I think"). Do not remove qualifiers that constrain the claim.
- **Metrics, dates, and ordering:** If the source says "after A, we did B", do not reorder into "we did B, and then A". If the source gives no numbers, do not invent them.
- **Required detail:** If the source names a specific technology ("Postgres"), keep it. If the source only says "database", do not upgrade to a named product.
- **Relationships and evidence:** Check actor, object, condition, and both sides of each comparison against the source. Resolve ambiguity only when the source supports the resolution; otherwise retain or flag it. Keep measured and expected claims, source inspection and exercised behavior, and technical checks and scientific or named-use conclusions distinct. A retained exact result is not a reproduced analysis; comparisons or missing records alone do not establish whole-study validity or explain every scientific mismatch.

The comparison is between claims. A scope limit is preserved when the draft states what the thing covers or where an excluded capability lives; the Boundaries and alternatives section of `writing-for-humans` decides which exclusions stay and in what form.

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

Use `Where:` for mappings and `Some notes:` for constraints when helpful.

## Examples

Read `references/examples.md` when calibrating a transformation or a technical/product claim.
