# aero-design

A reusable agent skill for polished, consumable data interfaces.

**Learn from Aero's way of presenting complexity—not its frontend stack or brand.**
The skill centres on editorial hierarchy, quiet framing, purposeful density,
clear comparisons, and evidence that remains visible without overwhelming the
reader. It is usable for fintech, scientific analytics, business software,
operational tools, and other data-rich products.

This is an independent, Aero-inspired skill. It is not published or endorsed by
Aero. No proprietary images, logos, fonts, or implementation code are bundled.

## What is in the package

```text
aero-design/
├── SKILL.md
├── README.md
├── references/
│   ├── visual-language.md
│   ├── data-presentation.md
│   ├── tuning.md
│   ├── review.md
│   └── sources.md
└── assets/
    └── AERO-DESIGN.template.md
```

`SKILL.md` is the entry point. The agent reads the supporting references only
when needed. The optional project brief stores your preferences without forking
the shared skill. There are no packages to install, scripts to execute, or UI
framework dependencies.

## Install for your agent

Extract the complete `aero-design` folder, including its references.

For OpenCode, place it in one of these documented locations:

```text
# A single repository
.opencode/skills/aero-design/SKILL.md

# Global / all projects
~/.config/opencode/skills/aero-design/SKILL.md
```

Keep the files beside `SKILL.md` in the same relative structure. Avoid duplicate
copies with the same skill name across discovery locations. Ask the agent to
load `aero-design` and confirm that it is discoverable.

[OpenCode's skill documentation](https://opencode.ai/docs/skills/) also lists
agent-compatible and Claude-compatible discovery paths. For other agents, use
that agent's supported skill directory; directory support and automatic loading
are host-specific. An agent without skill discovery can be instructed to read
`SKILL.md` directly from your repository.

The package follows the [Agent Skills format](https://agentskills.io/specification).
This is a portable instruction package, not a guarantee of automatic installation
in every agent. It has not been installed into your account or repository by
creating this archive.

## Use it

A short request is enough:

> Use the aero-design skill to polish this analytics page. Make the main result
> understandable at a glance while keeping the detailed comparisons available.
> Preserve our brand and existing UI framework.

A more directed request:

> Use aero-design on the dataset browser. Audience: expert. Density: compact.
> Expression: restrained. Preserve the current brand and framework. Recompose
> the comparison surface, but do not change the data model or calculations.
> Make entity identity, metric comparisons, data freshness, and row actions easy
> to scan. Check dense, empty, partial-data, and narrow-screen states.

These are natural-language prompts, not promises of a `/aero-design` slash command.
Activation syntax depends on the agent host.

## Tune it for a project

Copy [the optional brief](assets/AERO-DESIGN.template.md) into an existing design
folder, for example `docs/design/AERO-DESIGN.md`, and tell the agent to read it.
Specify only what matters. The same skill might use:

| Product surface | Tuning direction |
| --- | --- |
| Leadership overview | Mixed audience; balanced density; a clear main result, comparison, and evidence |
| Expert comparison tool | Compact density; aligned columns; exact values; stable interaction |
| Environmental results | Mixed audience; map or trend as the evidence; explicit coverage and uncertainty |
| Daily operations | Exception-first; compact controls; restrained motion; durable status feedback |
| Public product story | Editorial expression; spacious pacing; carefully scoped proof points |

Presets are starting positions, not templates. A compact table can share a page
with an editorial summary. A dark-mode product can retain the same information
hierarchy without using the light-mode palette from the reference.

## Framework and companion skills

Use this skill with the framework already in the project. It does not require
React, Vue, Svelte, Angular, Tailwind, shadcn, or any other particular toolkit.
For native UIs, translate its visual relationships through the platform's own
components and accessibility conventions rather than emulating web controls.

Other skills can handle implementation, accessibility testing, or motion craft.
`aero-design` supplies the composition and data-presentation direction; it does
not replace those skills or demand that they be installed.

## Scope of verification

The package is text-only guidance. Its frontmatter, local links, file structure,
and archive contents are checked during packaging. The review reference includes
behavioural test prompts for future agent evaluation. Those prompts are not a
claim that the skill has been benchmarked across models or UI frameworks.

Source links and limits of the Aero observations are documented in
[Sources](references/sources.md). Exact suggested values are original starting
points, not extracted Aero design tokens.
