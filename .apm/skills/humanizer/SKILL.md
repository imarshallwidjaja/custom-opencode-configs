---
name: humanizer
description: Use when prose is promotional, vague, over-hedged, or chatbot-like, or when it shows association weasel words, placeholder residue, citation markup, or markdown section chrome, and needs cleanup without inventing personality or facts.
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

If the text is mainly suffering from filler, throat-clearing openers, LinkedIn cadence, or mechanical antithesis, start with `stop-slop` first. For ordinary drafting, use `writing-for-humans` rather than treating this skill as the default voice.

## Workflow

1. Scan for patterns (use `references/patterns.md` as the checklist).
2. Rewrite the flagged parts with plain, direct constructions (prefer "is/are/has").
3. Remove chatbot meta, fix typography (straight quotes), avoid em-dash reliance.

## Output

Provide the rewritten text, preserving the original meaning and factual claims exactly.

## Reference

- Wikipedia: "Signs of AI writing": `https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing`
