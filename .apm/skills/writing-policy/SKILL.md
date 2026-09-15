---
name: writing-policy
description: Use when producing human-facing prose or delegating prose work, including docs, plans, reports, reviews, explanations, PR or commit text, and child or retry handoffs that will write for a reader.
---

# Writing Policy

This skill owns prose routing and delegated propagation. It does not replace the depth skills.

## Baseline

Apply a small baseline to every human-facing output, including short replies: write for the reader, keep names stable, do not invent facts, and run a silent draft-audit-fix loop before delivery. Do not announce the policy.

## Route

Load depth skills only when the case matches:

- Substantial docs, plans, reports, reviews, or explanations: `writing-for-humans`
- Cadence or structure rewrite problems: `writing-for-humans` plus `stop-slop`
- Vocabulary, register, attribution, formatting, or chat-artifact rewrite problems: `writing-for-humans` plus `humanizer`
- A broadly slop-heavy rewrite may load `writing-for-humans` plus both overlays
- Configured personal voice overlay: load only the personal voice skill named by an active personal AGENTS profile, active Cursor Rules, or an explicit handoff. Do not activate a personal voice skill merely because it is discoverable or installed.
- Domain-specific writing skills stay conditional on their own triggers

## Delegation

Parent-loaded skills do not imply child loading. Any permitted delegated or fresh-retry prose handoff must state artifact, audience, voice, and required writing skills, then require the child to load those skills itself. Where nested delegation is permitted, descendants preserve that contract rather than assuming the parent's loaded set.
