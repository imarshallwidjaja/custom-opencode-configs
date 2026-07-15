---
name: humanizer
description: Use when prose is promotional, vague, over-hedged, or chatbot-like and needs cleanup without inventing personality or facts.
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
- Overuses AI-default words (additionally, crucial, delve, showcase, underscore, landscape...)
- Contains chatbot artifacts ("Of course!", "I hope this helps", "Let me know if you'd like...")
- Uses mechanical formatting (inline-header lists, title-cased headings, emojis, curly quotes)

If the text is mainly suffering from filler, throat-clearing openers, or mechanical cadence, start with `stop-slop` first.

## Workflow

1. Scan for patterns (use `references/patterns.md` as the checklist).
2. Rewrite the flagged parts with plain, direct constructions (prefer "is/are/has").
3. Remove chatbot meta, fix typography (straight quotes), avoid em-dash reliance.

## Output

Provide the rewritten text, preserving the original meaning and factual claims exactly.

## Reference

- Wikipedia: "Signs of AI writing": `https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing`
