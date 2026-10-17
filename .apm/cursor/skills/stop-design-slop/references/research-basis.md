# Research basis and evidence notes

The skill combines three kinds of evidence. They should not be treated as equally strong.

## Evidence levels

- **A — Established HCI / accessibility:** peer-reviewed perception/HCI work and normative accessibility standards.
- **B — Mature industry guidance:** convergent guidance from major design systems and long-running UX practice.
- **C — Emerging GenAI evidence / anti-slop heuristic:** recent papers on generative design fixation/homogenization plus practical review heuristics. Useful, but not a universal law of good design.

## 1. Hierarchy, scale, contrast, balance, Gestalt — Evidence A/B

Nielsen Norman Group summarizes scale, visual hierarchy, balance, contrast, and Gestalt as core visual-design principles that support usability. Its proximity and common-region guidance is directly relevant to "card soup": boundaries are powerful grouping cues, while whitespace/proximity can often do the job with less visual structure.

Apple's HIG likewise frames layout around visual hierarchy, reading order, alignment, logical grouping, progressive disclosure, and sufficient space around controls. Its typography guidance explicitly treats size, weight, and color as tools for hierarchy and warns that too many typefaces can obscure it.

**Implication for the skill:** use alignment, proximity, typography, scale, and contrast before adding new containers; make dominant/subordinate relationships explicit.

## 2. Visual clutter is distinct from useful density — Evidence A

Rosenholtz, Li, and Nakano's work on visual clutter treats clutter as a perceptual/search problem: excessive or disorganized features make segmentation and visual search harder. The important nuance is that "more information" is not automatically "more clutter". Structure, regularity, contrast, and feature competition matter.

Tuch et al. also found visual complexity affects cognition, emotion, performance, and memory on websites.

**Implication:** do not solve clutter by indiscriminately removing information. For operational interfaces, preserve task-relevant density but reduce competing surfaces, ornament, inconsistent alignment, and irrelevant salience.

## 3. First impressions are fast, but familiarity/prototypicality matters — Evidence A

Lindgaard et al. showed people can form stable visual appeal judgments of web pages after very brief exposure (commonly summarized as 50 ms in that study).

Tuch et al. found both visual complexity and prototypicality influence first-impression aesthetic judgments. This is a critical guardrail for an "anti-slop" philosophy: **distinctive does not mean unfamiliar at every level.** Users benefit from learned conventions.

**Implication:** preserve interaction/category conventions that aid orientation, while rejecting template-level sameness in composition, brand expression, and content.

## 4. Aesthetics has multiple facets, not one "minimal" axis — Evidence A

Lavie & Tractinsky distinguished dimensions of perceived website aesthetics rather than reducing quality to minimalism. Moshagen & Thielsch's VisAWI further operationalized visual aesthetics through facets including simplicity, diversity, colorfulness, and craftsmanship.

**Implication:** "premium minimalism" is not a universal quality target. A design can be dense, colorful, or unconventional and still be aesthetically coherent when its parts are skillfully integrated.

## 5. Spacing systems are a vocabulary, not a composition algorithm — Evidence B

Carbon provides spacing tokens/scales to create consistency while also explaining the role of whitespace in grouping and importance. GOV.UK similarly uses structured spacing and layout systems. Neither implies one repeated gap across all relationships.

**Implication:** use spacing tokens consistently, but select among them according to conceptual grouping and transitions.

## 6. Dense data interfaces deserve width and task-fit — Evidence B

Carbon's data-table guidance recommends giving dense tables substantial width to help users view data. Material's data-table guidance treats tables as flat rectangular data surfaces rather than requiring high elevation or ornamental card treatment.

**Implication:** do not wrap dense analytical content in multiple floating tiles or force dashboard aesthetics onto inherently tabular/relational tasks.

## 7. Translucency/depth should communicate layering — Evidence B

Apple's material guidance describes translucent material as a functional layer separating controls/navigation from underlying content. The value is spatial hierarchy and continuity, not blur as decoration.

**Implication:** glassmorphism is defensible when spatial layering matters; weak when it is simply stacked with gradients/glow to imply luxury.

## 8. Accessibility constrains decorative freedom — Evidence A

WCAG 2.2 provides requirements for text contrast, non-text contrast, focus appearance/order, target size, resizing text, and other behaviors. A visually distinctive design that loses focus visibility, contrast, readable text, or logical navigation is not a successful anti-slop design.

**Implication:** distinctiveness is subordinate to accessibility and task comprehension.

## 9. Generative systems can exhibit design fixation / homogenization — Evidence C (emerging)

Recent research is increasingly aligned with the motivating observation behind this skill:

- Chen et al. (2025) frame and experimentally investigate **GenAI design fixation**, reporting limitations in novelty/diversity across generated outcomes.
- The CHI 2024 paper by Wadinambiarachchi et al. found exposure to AI-generated images increased fixation on initial examples in a visual ideation task.
- *Interrogating Design Homogenization in Web Vibe Coding* (2026 preprint) directly studies homogenization in LLM-generated web design and reports convergence toward dominant style conventions.
- Broader 2026 work on creative-output homogenization reports reduced diversity across AI-assisted outputs even when individual performance can improve.

These findings are recent and some are preprints; they support the workflow recommendation to explicitly identify product/domain constraints and a governing composition idea before generation.

**Implication:** an AI agent should not rely on its first plausible layout. Product grounding, divergent composition exploration, and anti-template review are useful countermeasures.

## 10. Why the skill uses tests rather than absolute bans

A universal ban on cards, radius, gradients, symmetry, or centered text would conflict with both usability and design-system evidence. A card can be the right common-region cue; a pill can be the right status token; translucency can correctly express layering; a prototypical layout can improve orientation.

The skill therefore asks for **semantic justification** and uses falsifiable review tests:

- would the hierarchy survive if the card boundary disappeared?
- does the product remain recognizable in grayscale?
- is a metric prominent because it changes decisions?
- is the icon carrying information?
- does translucency communicate a layer?
- would an unrelated SaaS brand fit the composition unchanged?

This makes the philosophy portable across visual styles rather than turning one anti-trend into another trend.
