---
name: humanizer
description: Use when rewriting existing prose that is promotional, vague, over-hedged, or chatbot-like, or that shows AI vocabulary clusters, weasel attributions, actorless passive, placeholder residue, citation markup, or markdown section chrome. Depth skill for writing-for-humans.
---

# Humanizer

Remove common AI-writing patterns while keeping the meaning, facts, and intended tone intact. Based on Wikipedia's "Signs of AI writing" guide (WikiProject AI Cleanup).

**Hard rules:**
- Do not invent personality, emotion, anecdotes, uncertainty, or factual errors.
- Do not add voice that was not present. Remove patterns; do not replace them with fabricated tone.
- Preserve factual claims, dates, names, and qualifications exactly.

## When to use

Use when the text:

- Reads like a press release or Wikipedia stub (grand claims, generic positivity)
- Leans on vague attributions ("experts say", "industry reports") instead of specifics
- Overuses AI-default words (additionally, crucial, delve, showcase, underscore, landscape, highlighting, causal, empirical...)
- Contains chatbot artifacts ("Of course!", "I hope this helps", "Let me know if you'd like...")
- Uses mechanical formatting (inline-header lists, title-cased headings, emojis, curly quotes, `---` between sections)
- Pads relationships with "associated with" / "in connection with"
- Leaves placeholder text, Mad Libs brackets, or model citation markup (`contentReference`, `grok_card`, `[cite: 1]`)

Load with `writing-for-humans`. That skill is the core: it owns the finish pass, the non-invention rule, and the em dash policy. `stop-slop` owns cadence and structure. This skill owns vocabulary, register, attribution, formatting tells, and chatbot artifacts.

## Workflow

1. Scan for patterns (use `references/patterns.md` as the checklist).
2. Rewrite the flagged parts with plain, direct constructions (prefer "is/are/has").
3. Remove chatbot meta, fix typography (straight quotes), apply the em dash policy from `writing-for-humans`.

## What not to flag

A clean human writer can hit several of these patterns with no model involved. None of the following is a reliable tell on its own:

- Perfect grammar and consistent style. Many writers are professionals or have been edited.
- Mixed casual and formal registers. This usually signals a person, not a chatbot.
- Dry or bland prose without a specific tell. Dryness is just dryness.
- Formal vocabulary in general. The pattern list names specific overused words, not every precise one.
- A single transition word. One "however" or "additionally" counts only when piled up.
- Curly quotes alone. Most editors and CMSes auto-curl by default.
- Em dashes alone. Editors and journalists use them; they count only inside a cluster.
- One short emphatic sentence. Flag fragment runs, not one clipped line.
- Unsourced claims alone. Most writing is unsourced, and a missing citation proves nothing.
- Phrases inside quotations, titles, proper names, or examples where the phrase is being discussed rather than used.

## Voice calibration

If the user supplies a sample of their own writing, read it first and note its sentence lengths, vocabulary, paragraph openings, punctuation, and recurring phrases. Match those habits rather than only deleting patterns; do not upgrade casual words or regularise deliberate quirks. The sample outranks these rules. Without a sample, use the defaults in this skill.

## Output

Provide the rewritten text, preserving the original meaning and factual claims exactly.

## Reference

- Wikipedia: "Signs of AI writing": `https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing`
