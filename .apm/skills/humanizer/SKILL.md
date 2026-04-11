---
name: humanizer
description: Use when editing or reviewing prose that sounds AI-generated (formulaic, promotional, vague, over-hedged, chatbot-y) and needs a more natural human voice.
---

# Humanizer

Remove common AI-writing patterns while keeping the meaning and intended tone intact. This skill is based on Wikipedia's "Signs of AI writing" guide (WikiProject AI Cleanup).

## When to use

Use this when the text:

- Reads like a press release or Wikipedia stub (grand claims, generic positivity)
- Leans on vague attributions ("experts say", "industry reports") instead of specifics
- Overuses AI-default words (additionally, crucial, delve, showcase, underscore, landscape...)
- Contains chatbot artifacts ("Of course!", "I hope this helps", "Let me know if you'd like...")
- Uses mechanical formatting (inline-header lists, title-cased headings, emojis, curly quotes)

If the text is mainly suffering from the classic "Claude slop" cadence (throat-clearing openers, binary pivots, em-dash reveals), start with `stop-slop` first.

## Workflow (tight loop)

1. Scan for patterns (use `references/patterns.md` as the checklist).
2. Rewrite the flagged parts with plain, direct constructions (prefer "is/are/has").
3. Add a pulse where it fits (see `references/voice.md`).
4. Final polish: remove chatbot meta, fix typography (straight quotes), avoid em-dash reliance.

## Output

Provide:

1. The rewritten text
2. (Optional) A short bullet list of the main patterns you removed

## Reference

- Wikipedia: "Signs of AI writing": `https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing`
