---
name: frontend-slides
description: Use when building, converting, or revising HTML slide decks, presentations, briefings, or PPT/PPTX-to-web conversions; when the user asks for slides, a talk, pitch, or a reading-and-speaking briefing as a single HTML file.
---

# Frontend Slides

Zero-dependency HTML briefings. One file. Fixed 1920×1080 stage. Default visual world is navy / orange / cream / green with chevrons and numbered spines, without org branding unless supplied.

Follow the operators writing style and voice unless specified.

## Invariants

- Single HTML file. Inline CSS and JS. No npm, no bundler.
- Viewport wrapper + 1920×1080 `.deck-stage`. Uniform scale. Letterbox or pillarbox. No content reflow. No mobile breakpoints inside slides.
- Slide switching: `.active` / `.visible` with `visibility`, `opacity`, `pointer-events`. Never `display: none` on `.slide`.
- Authored measurements are px at 1920×1080. Do not use `vw` / `vh` / `clamp()` inside slides. Never negate a CSS function with a leading `-`; wrap `calc(-1 * ...)`.
- `prefers-reduced-motion` is already in the base CSS. Keep it.
- Include the full [viewport-base.css](viewport-base.css) in every deck.
- Diagrams are HTML/CSS in the process grammar. Do not default to generated rasters or mermaid embeds.
- A maintained deck is edited in place. Do not regenerate it from this skill.

## Writing

Follow the operators writing style and voice unless specified.

Default is operator voice for a technical peer: concrete nouns, hands-on verbs, define the system first. Catalogue claims from source material before drafting. Do not invent metrics, dates, technologies, owners, or approvals.

Visible copy:

- Stand-alone. The operator may present, but slides have to survive later reading.
- Give actions to the component or person that performs them. Do not make evidence, environments, capability, or state perform actions they cannot perform.
- Define a system, component, state, or abbreviation before its shorthand.
- Prefer names over unexplained IDs.
- No first-person staging ("What I'm taking", "I want to start") unless the operator is the named speaker and asks for it.
- No LinkedIn cadence, no "Not X, Y" punchlines, no mystery, no marketing slogans, no em-dash reveals.
- Split a slide when it overflows. Do not shrink type until it is unreadable. Authored body not below 17px.

## Visual world

Read [references/visual-system.md](references/visual-system.md) before generating or restyling.

Default: navy `#05001c`, orange `#fd6701`, cream `#f4e4d4`, green `#34a448`, Barlow, sharp top bands, thick chevrons, numbered spines. Paste [references/briefing.css](references/briefing.css) after viewport-base. No FrontierSI / product logos, no required brand slots, no tiled grid background, no "surprise and delight" font rotation.

If the operator names another visual world, or the project already has tokens, type, or a reference surface, commit to that world. Keep the stage, runtime, copy rules, and overflow rules. Do not mix it with the default palette. Do not generate style options. Honor contrast (body ≥4.5:1), spacing, type hierarchy, and one motion system. Process language beats identical icon-title-body card grids. A named brief wins over the default.

Logos, marks, and third-party assets are opt-in. Use only what the operator provides. Relative paths. Preserve provenance comments for shipped icons.

## Density

Default: hybrid reading-and-speaking briefing. Dense enough to stand alone. Large enough to present.

| Mode | When | Behavior |
| --- | --- | --- |
| Hybrid (default) | Internal briefing, alignment, architecture, mixed live + later reading | Self-contained slides, structured bands/tables, split on overflow |
| Speaker-led | Explicit keynote / live talk | One idea per slide, larger type, more slides |
| Reading-first | Explicit handout / async review | Tighter grids, captions, still no scroll |

Infer from the request. Ask at most one question, and only if the missing choice would change the deck.

## Modes

**New deck.** Infer purpose, audience, and length from the request and source files. Outline from evidence, then generate. Do not ask a style question. Do not write three preview files. Do not create `.frontend-slides/`.

**PPT conversion.** Extract, confirm the outline, then generate in the committed visual world.

```bash
uv run --with python-pptx python <skill-root>/scripts/extract-pptx.py <input.pptx> <output_dir>
```

Preserve text, slide order, extracted `assets/`, and speaker notes as HTML comments.

**Enhance an existing HTML deck.** Read it. Keep its visual world unless asked to replace it. Count elements before adding. If content will overflow, split first. After any structural or copy-shape change, bump `STORE_KEY`. Screenshot touched slides.

## Generate

Before writing HTML, read:

1. [references/visual-system.md](references/visual-system.md)
2. [references/html-template.md](references/html-template.md)
3. [viewport-base.css](viewport-base.css)
4. [references/briefing.css](references/briefing.css) unless the world was overridden

Then:

1. Write the direction-contract comment (thesis, own-world, story, first viewport, form).
2. Build the outline from source material. Curate supplied images into the outline; do not plan slides then bolt images on.
3. Emit one HTML file plus `assets/` if needed. Paste viewport-base and briefing CSS in full.
4. Use the controller and inline editor in html-template.md. Set `STORE_KEY` and `FILE_NAME`.
5. Number slides `01 / N` in both `.slide-index` and `#ctrlCount`.
6. Open the file (`xdg-open` on Linux, `open` on macOS).

Do not add detailed "how to modify this section" comments. The direction contract and `/* === Section === */` markers are enough.

## QA

After generate or edit:

1. Confirm every `.slide` is 1920×1080, `overflow: hidden`, no `display: none` switching.
2. Confirm no panel overlap, no clipped body children, no type below 17px.
3. Disable `.reveal` (`opacity: 1; transform: none`) and screenshot touched slides at 1280×720. Phone is scale-only.
4. Relative image paths resolve. No `file://`.
5. `STORE_KEY` bumped if editable node count or order changed.

## Share and export

Do these when asked. Do not upsell hosting after every draft.

PDF (static snapshot of the final visual state):

```bash
bash <skill-root>/scripts/export-pdf.sh <path-to-html> [output.pdf]
# smaller: add --compact (1280×720)
```

Needs Node. First run downloads Playwright Chromium. Local images must be relative to the HTML.

Live URL:

```bash
bash <skill-root>/scripts/deploy.sh <path-to-html-or-folder>
```

Vercel. Prefer deploying a folder when assets exist beside the HTML. Confirm the live URL actually loads images.

`<skill-root>` is the directory that contains this `SKILL.md`.

## Common mistakes

- Asking for three styles, or generating `style-a.html` / `style-b.html` / `style-c.html`
- Restyling a maintained deck onto Signal, Source Serif, Inter, purple gradients, or a tiled grid
- Regenerating a live file from the template instead of editing it
- `display: none` slide switching (later `display: flex` on `.slide-content` unhides every slide)
- `vh` image max-height or `clamp()` type inside the stage
- Inventing logos or putting title text under the orange slash
- Raster diagrams as the default picture
- Shrinking type to save a slide
- Leaving `STORE_KEY` unchanged after adding fields, so localStorage restores stale copy
- `pip install` for extract/resize; use `uv run --with ...`

## Supporting files

| File | Read when |
| --- | --- |
| [viewport-base.css](viewport-base.css) | Generating any deck; paste in full |
| [references/briefing.css](references/briefing.css) | Default world; paste in full |
| [references/visual-system.md](references/visual-system.md) | Layout, process grammar, overrides |
| [references/html-template.md](references/html-template.md) | Runtime, editor, STORE_KEY |
| [scripts/extract-pptx.py](scripts/extract-pptx.py) | PPT conversion |
| [scripts/export-pdf.sh](scripts/export-pdf.sh) | PDF export |
| [scripts/deploy.sh](scripts/deploy.sh) | Live URL |
