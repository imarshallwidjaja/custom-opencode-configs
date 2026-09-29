# Tuning the design language

Use this reference when the skill must adapt to a different product or audience.
The invariant is clarity with precision; the presentation is negotiable.

## Three layers

**Core:** honest data, interpretable metrics, clear hierarchy, accessible controls,
and a coherent reading task. Do not tune these away.

**Project:** brand, terminology, theme, platform conventions, approved components,
and recurring audience needs. Inherit these whenever they exist.

**Surface:** the current task, density, emphasis, disclosure depth, and motion.
Adjust these without redesigning the whole product.

For example, a financial product's blue brand can coexist with neutral change
indicators and several categorical chart colours. An environmental product can
use its own green brand without treating every rising index as a positive result.

## Interpret the dials as visible changes

| Dial | Lower / quieter expression | Higher / richer expression | Do not trade away |
| --- | --- | --- | --- |
| Density | More separation, fewer simultaneous concepts | More aligned fields, compact context, efficient controls | Readable type, essential fields, operable targets |
| Editorial emphasis | Title and task lead directly into content | Strong summary, larger principal value, varied section rhythm | Fast access to the actual work |
| Brand expression | Brand at navigation, key action, selected state | More distinctive type, composition, and occasional imagery | Semantic colour, legibility, domain identity |
| Explanation | Expert labels with discoverable definitions | Plain-language labels, local explanations, guided context | Correct terminology and material caveats |
| Motion | Immediate state changes with minimal transitions | Restrained continuity and expressive moments | Responsiveness, reduced-motion support, stable data |
| Disclosure | More comparable detail immediately visible | Summary with purposeful progressive detail | Information necessary to interpret or safely act |

These are not numeric sliders or a software schema. Convert a requested quality
into changes a user would notice. "More premium" should usually mean stronger
hierarchy, disciplined alignment, clearer copy, and better states—not more blur.

## Task-led presets

### Decision overview

**Use:** a reader needs to understand a situation and choose what to inspect.

Audience: mixed. Density: balanced. Expression: editorial but restrained.

Lead with one main question or a small coherent metric family. Show the most
useful comparison and a material qualification. Follow with a trend, breakdown,
or exception list. Detail should be nearby, but the initial view need not expose
every field. Do not make an unsupported causal headline from a correlated trend.

Typical structure: scope → main result + comparison → supporting evidence → details.

Avoid: equal emphasis on a dozen unrelated KPIs; a hero that delays the evidence.

### Comparison workbench

**Use:** experienced users compare repeated entities or choose among alternatives.

Audience: expert. Density: compact. Expression: restrained. Motion: minimal.

Lead with the data and its controls. Preserve identity, high-value comparable
fields, visible sorting, and exact inspection. Use column alignment and predictable
metadata instead of separate rounded cards. Keep essential row actions available
without relying on hover. A summary is optional, not a required dashboard header.

Typical structure: scope + controls → aligned records → contextual detail.

Avoid: hiding the distinguishing fields to achieve a cleaner first impression.

### Evidence investigation

**Use:** an analyst or scientist needs to interpret a result and test its basis.

Audience: mixed or expert. Density: balanced around evidence, compact in detail.

Let the evidence-bearing visual—map, chart, image, distribution, or table—lead.
Make time range, coverage, method, and uncertainty explicit where material.
Keep a linked detail region so the reader can inspect without losing context.
Differentiate observation from model output and an anomaly from confirmed harm.

Typical structure: question + scope → evidence → selected detail → method/quality.

Avoid: a confident score without a definition, or decorative maps with no legend.

### Operations and exceptions

**Use:** a frequent user checks state and resolves problems.

Audience: usually expert. Density: compact. Expression: restrained. Motion: minimal.

Emphasise actionable exceptions and their consequences, not the total number of
healthy things. Keep status text, affected identity, recency, and next action
close together. Preserve selection, filters, and scroll position on refresh.
Separate acknowledgement from resolution; do not style an unknown state as healthy.

Typical structure: current scope → exceptions / working queue → details + action.

Avoid: large executive KPIs occupying the space needed to resolve a problem.

### Transaction or configuration

**Use:** someone changes settings, submits a job, or makes a consequential action.

Audience: infer. Density: balanced around the decision, compact for supporting facts.

Focus on the object, current state, proposed change, important costs/consequences,
and one clear next action. Use plain labels and local validation. Preserve review
and confirmation where the domain requires them. Explain why an action is unavailable.

Typical structure: object → inputs → consequential summary → action → outcome.

Avoid: quiet styling that also makes fees, affected scope, or failure states quiet
in the sense of being hard to discover.

### Explanatory / public story

**Use:** a reader is learning a product or understanding its evidence.

Audience: general or mixed. Density: airy in narrative, balanced in proof.
Expression: editorial. Motion: subtle; more expressive only where it helps.

Use larger type, varied pacing, and occasional imagery to establish the narrative.
Explain a claim and then show its scoped evidence. Keep proof readable and
qualifications visible. Do not use live operational patterns merely as decoration.

Typical structure: proposition → explanation → evidence → meaningful next step.

Avoid: transferring cinematic page proportions into the working application.

## Mixed pages are normal

Choose regional density before inventing separate design systems. For example:

- A balanced revenue summary can precede a compact customer comparison table.
- A map can stay dominant while its inspector uses compact key/value rows.
- An airy product explanation can contain a dense, accessible evidence table.

Maintain the same type roles, spacing relationships, semantic colours, and control
hierarchy across these regions. Variation should reflect different reading tasks.

## Common requests and how to answer them

| Request | Productive interpretation | Unproductive interpretation |
| --- | --- | --- |
| "More premium" | Better type relationships, alignment, phrasing, and state quality | More shadows, glass, or empty space |
| "More consumable" | Clarify the main question; add context and useful comparison | Delete the evidence or show only large numbers |
| "More data-dense" | Reveal comparable fields; tighten grouping; reduce framing | Shrink everything until it barely fits |
| "More like Aero" | Quiet shell, strong content, restrained accents, coherent evidence | Copy its blue, clouds, logo, or page verbatim |
| "More expressive" | Add a deliberate identity moment where attention is available | Animate every metric and give each card its own colour |
| "Keep our existing look" | Change hierarchy and relationships using existing tokens | Refuse improvement unless a new theme is allowed |
| "Make it executive-friendly" | Plain-language summary with inspectable detail | Replace uncertainty with certainty or remove caveats |

## Conflict handling

If compactness conflicts with comprehension, group and reprioritise before reducing
font size. If comparison conflicts with narrow width, preserve the comparison in
a bounded horizontal region or provide a purpose-built summary plus full view.
If brand contrast fails, preserve its identity through adjusted functional shades
or placement rather than violating readability. If a requested polish change
would alter meaning, explain the conflict and propose a truth-preserving treatment.

Persist only stable decisions in a project brief. Keep task-specific exceptions
local, and do not modify this shared skill to match one application's palette.
