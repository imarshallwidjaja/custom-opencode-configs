---
name: stop-design-slop
description: Use when designing, generating, reviewing, refactoring, or polishing product interfaces, dashboards, landing pages, data applications, design systems, or frontend code where visual hierarchy, product specificity, density, composition, component usage, or brand character matter. Prevents generic, template-like, AI-convergent UI. Detects card soup, indiscriminate rounding/pills, generic SaaS heroes, three-card feature rows, gratuitous gradients/glass, decorative icons, weak hierarchy, fake product imagery, meaningless KPIs, component-library sameness, generic copy, and other signs of design-by-default.
metadata:
  version: "1.0.0"
  evidence_basis: "HCI research, accessibility standards, major design systems, and 2024-2026 GenAI design-fixation/homogenization research"
---

# Stop Design Slop

Design from the product's **task, information, domain objects, and identity**, not from the statistical average of modern SaaS interfaces.

The objective is not novelty for novelty's sake. The objective is **specificity with usability**: a design should feel as though its structure could only have emerged from this product, while remaining legible, accessible, and operationally effective.

## When this skill activates

Apply this skill when creating or reviewing:

- application screens, dashboards, consoles, workspaces, editors, maps, data products, and admin tools;
- marketing sites, landing pages, product pages, documentation portals, and onboarding;
- design systems, component compositions, Tailwind/shadcn/Radix/Material implementations;
- mockups or frontend code produced by AI;
- redesigns described as "premium", "modern", "clean", "minimal", or "SaaS" without stronger product-specific direction.

Do **not** interpret this skill as a ban on cards, gradients, pills, rounded corners, glass, whitespace, or component libraries. These are legitimate tools. The rule is: **use them only when their semantic, interaction, hierarchy, or brand function can be explained.**

## Core operating principle

For every prominent visual decision, be able to answer:

> Why is it like this?

Acceptable answers usually refer to one or more of:

1. hierarchy or salience;
2. semantic grouping or boundary;
3. interaction/state communication;
4. readability, scanning, comparison, or information retrieval;
5. product/domain identity;
6. accessibility;
7. a deliberate compositional idea.

"It looks modern", "it feels premium", "this is standard SaaS", and "the component library does this" are insufficient.

---

# Workflow

## 1. Establish product-specific constraints before styling

Before proposing a layout, identify:

- **Dominant user task:** what is the user here to accomplish?
- **Primary domain object:** what object, dataset, document, map, queue, timeline, graph, record, asset, or artifact should dominate the screen?
- **Decision hierarchy:** what must be seen first, second, and third?
- **Information density requirement:** is this a reading, comparison, monitoring, investigation, operation, or marketing context?
- **Real product artifacts:** what authentic screenshots, maps, charts, records, outputs, media, or data can serve as visual material?
- **Brand character:** what structural traits — not merely colors — should recur? Consider typography, geometry, density, imagery, iconography, motion, chart language, interaction patterns, and tone.

If these are unknown, default to a restrained wireframe rather than inventing decorative specificity.

## 2. Choose one governing composition idea

A major screen should have a discernible design idea. Examples:

- the map is the workspace;
- chronology structures the investigation;
- evidence behaves like a case file;
- the graph is also navigation;
- the primary record occupies the canvas and controls live in a rail;
- datasets behave like physical layers;
- the document itself is the interface;
- one authentic product artifact carries the page.

Do not replace a governing idea with a pile of attractive effects.

## 3. Build hierarchy before containers

Start with:

1. reading order and alignment;
2. scale and type hierarchy;
3. proximity and whitespace;
4. columns/grid and relative width;
5. contrast and emphasis;
6. dividers or background-plane changes;
7. semantic containers only where needed.

This sequence operationalizes **Gestalt proximity** and **common region**: a border/container is a strong grouping cue and should not be used when weaker cues already express the relationship.

## 4. Assign visual weight deliberately

Classify major elements as:

- **dominant** — the primary object/action;
- **supporting** — context needed to work with it;
- **quiet** — metadata, secondary controls, infrastructure;
- **background** — persistent chrome or low-priority context.

Avoid equal-salience layouts where every region has a border, heading, icon, shadow, and similar padding.

## 5. Apply components as primitives, not aesthetics

A design system or library supplies implementation primitives and behavior. It does not supply the product's composition.

When using shadcn, Radix, Material, Carbon, Bootstrap, Tailwind UI, etc.:

- retain accessibility and interaction behavior;
- modify composition, typography, density, proportions, shape, borders, surfaces, and states as needed;
- avoid repeating demo-page arrangements from the library;
- avoid exposing the library's default visual fingerprint when it is not part of the product identity.

## 6. Run the anti-slop review

Use the tests in `references/review-rubric.md`. Revise until the design passes the task, hierarchy, specificity, grouping, authenticity, and component-library tests.

For source rationale and terminology, read:

- `references/terminology.md` for industry-standard names;
- `references/research-basis.md` for evidence and caveats;
- `references/pattern-catalog.md` for anti-patterns and exceptions;
- `references/source-index.md` for citations.

For implementation demonstrations, inspect `examples/`.

---

# Anti-pattern rules

## A. Excessive common-region grouping ("card soup")

Do not put each content cluster in a rounded container merely to make it feel designed.

A container should usually correspond to one of:

- an independently actionable/selectable/draggable object;
- a bounded interaction region;
- a materially different context or state;
- a repeated collection item whose boundary aids scanning;
- content that must remain grouped when layout changes.

Before adding a card, try proximity, alignment, type, divider, indentation, column structure, or a background-plane shift.

Avoid nested cards unless the nested region has a distinct semantic/interaction role.

## B. Indiscriminate shape-token application ("round everything")

Corner radius is a **shape token**, not an identity by itself.

Use radius according to object semantics and scale. Dense tables and analytical surfaces may be square or subtly rounded; controls may use modest rounding; a prominent standalone object may use stronger shape treatment; a pill/capsule is reserved for capsule semantics.

Do not make every table, panel, dialog, screenshot, input, button, badge, navigation item, and chart share the same exaggerated radius.

## C. Chip/pill misuse

Use pills/chips for compact categorical or stateful objects such as status, tags, filters, selections, toggles, or short metadata.

Do not use capsule shapes as generic wrappers for eyebrows, subtitles, section labels, statistics, or arbitrary decorative words.

## D. Decorative effect stacking

Avoid default combinations of gradient + blur + glow + translucent border + shadow + glass on the same component.

Use a strong effect only when it carries identity, hierarchy, state, or spatial meaning. Prefer one coherent motif over multiple simultaneous embellishments.

The specific "dark navy + purple/cyan glow + glass cards" look is a high-risk AI-default aesthetic unless explicitly brand-led.

## E. Gratuitous translucency / glassmorphism

Translucency is justified when layered spatial context matters and seeing the layer below helps orientation. It is weak when used merely as a premium-looking surface treatment.

Preserve legibility and non-text contrast; do not let blur substitute for hierarchy.

## F. Template-convergent marketing hero

Do not automatically generate:

- pill eyebrow;
- giant centered heading;
- muted two-line subtitle;
- two CTAs;
- floating rounded screenshot;
- gradient glow.

Choose an opening that reflects the product. It may be a live map, a real artifact, a search/action field, a dense operational view, an image, a result, a comparison, or one strong sentence.

## G. Equal three-card feature row

Do not imply equal importance simply because a three-column grid is convenient.

Choose a composition that matches information structure: annotated product view, editorial sequence, workflow, comparison, dense list, asymmetric feature hierarchy, or interactive example.

## H. Decorative iconification

Icons should improve recognition, navigation, state communication, or action comprehension.

Remove icons that add no information. Avoid the repeated "generic line icon inside tinted rounded square" treatment beside every heading. Prefer product/domain-specific symbols where useful.

## I. Over-centering

Centered alignment is strongest for focused, bounded statements. For information-heavy or operational screens, derive hierarchy from reading order, columns, proximity, and alignment.

Default toward leading/left alignment for scan-heavy content unless there is a reason not to.

## J. Weak typographic hierarchy

Typography should carry hierarchy before boxes do.

Use a small coherent type system with clear jumps in importance. Control size, weight, line-height, line length, contrast, and alignment. Avoid many barely distinguishable text styles.

## K. Equal salience / uniform visual weight

Not every region deserves a border, icon, tile, badge, or button. Ensure dominant, supporting, quiet, and background layers are visibly different.

A useful quick test is the **squint test**: blurred or viewed at a distance, the first three attention targets should remain obvious.

## L. Mechanical spacing

A spacing scale is infrastructure; **composition** decides which token to use.

Use tighter spacing inside conceptual groups and larger transitions between groups. Dense work surfaces may intentionally stay dense. Do not mechanically apply one gap value everywhere.

## M. Default symmetry

Do not force identical two-column masses or perfectly equal grid regions when content importance is unequal.

Controlled asymmetry can produce clearer hierarchy: a dominant canvas plus narrow rail, oversized artifact plus compact explanation, dense region beside negative space, or unequal columns.

## N. Invented product imagery

Do not fabricate dashboards, charts, maps, metrics, customer logos, activity feeds, or analytics merely to occupy space.

Prefer authentic product artifacts and representative data. If illustrative data must be mocked, label it as sample/demo content and ensure it demonstrates a real product behavior.

## O. Meaningless KPI tiles

A KPI deserves top-level salience only when a user makes a decision from it, its change matters, it establishes system state, or it answers a recurring question.

Do not create four statistic cards merely because the page is called a dashboard.

## P. Decorative minimalism over task fit

Do not equate quality with huge whitespace, tiny information quantities, oversized headings, low-contrast gray copy, thin borders, and floating cards.

For comparison, monitoring, investigation, and operations, information density is often a feature. Optimize density for task performance and scanning rather than portfolio screenshots.

## Q. Generic generative copy

Avoid placeholder marketing language such as:

- Unlock the power of...
- Seamlessly...
- Supercharge...
- Transform your workflow...
- Everything you need...
- Built for the future...
- Smarter insights, faster.
- Powerful. Simple. Intuitive.

Use concrete product nouns, actions, constraints, and outcomes. Specific copy creates specific layout opportunities.

## R. Component-library fingerprinting

If a knowledgeable reviewer can immediately identify the starter kit from the composition and styling, treat that as a prompt to differentiate the product further — unless adopting that system's native look is an explicit requirement.

## S. Effect accumulation without concept

One strong idea beats many pleasant effects. If removing gradient, shadow, glow, rounding, and animation causes the composition to collapse, the design needs a stronger structural concept.

## T. Brand as color-only theming

Brand should influence more than accent color. Establish a recognizable subset of typography, geometry, density, imagery, iconography, motion, data visualization, layout, language, and interaction patterns.

A useful test: does the interface retain some identity in grayscale?

---

# Required review tests

Before approving a screen, answer all of these:

1. **Task test** — Is the dominant user task obvious and well-supported?
2. **Hierarchy test** — Is first/second/third visual priority obvious?
3. **Logo-swap test** — Could another unrelated SaaS logo replace this one without the page feeling wrong?
4. **Product-specificity test** — Can the product category or actual activity be inferred without reading the logo?
5. **Card-removal test** — If container borders disappear, does the intended grouping collapse? If not, some cards are probably redundant.
6. **Decoration-removal test** — Without gradients, shadows, glows, and exaggerated rounding, does a strong composition remain?
7. **Screenshot-vs-task test** — Is this optimized to perform work or to look attractive in a static showcase?
8. **Component-library test** — Is the starter kit more visually recognizable than the product?
9. **Repetition test** — Are repeated cards/pills/icons/layouts required by repeated semantics, or merely easy to generate?
10. **Authenticity test** — Are prominent visuals real product artifacts or honest demonstrations rather than invented filler?
11. **Intent test** — Can every prominent visual choice be explained without saying "modern", "clean", or "premium"?
12. **Accessibility test** — Does the design preserve readable contrast, focus visibility, target usability, text scaling, and logical reading/focus order?

If a screen fails several tests, redesign the composition before polishing details.

---

# Output behavior for design agents

When asked to create a design:

- briefly state the dominant task and governing composition idea;
- prefer one opinionated direction over several generic variations unless exploration is requested;
- use real content/product artifacts when available;
- preserve useful density;
- minimize decorative containers;
- introduce deliberate variation in scale and visual weight;
- implement accessible states, not only the default screenshot state;
- when unsure, produce a restrained structural solution rather than hallucinating decoration.

When asked to review an existing design:

- identify anti-patterns using the terminology in `references/terminology.md`;
- distinguish usability problems from brand/distinctiveness problems;
- explain what to remove, merge, promote, quiet, or restructure;
- do not recommend novelty that harms learnability, accessibility, or task efficiency;
- prefer specific structural changes over subjective comments like "make it pop".

Optional static heuristic: run `python scripts/audit_ui.py <path>` on HTML/CSS/JS/TS/JSX/TSX to flag likely slop signals. Treat its output as prompts for review, never as a design verdict.
