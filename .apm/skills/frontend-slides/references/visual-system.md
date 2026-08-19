# Default visual system

Navy, orange, cream, green. Sharp bands, thick chevrons, numbered spines. Barlow. No brand marks unless the operator supplies them.

Paste [briefing.css](briefing.css) after [viewport-base.css](../viewport-base.css). Invent slide layouts from these primitives. Do not import a template pack.

## Own-world

| Role | Token | Hex |
| --- | --- | --- |
| Stage letterbox | `--stage-bg` | `#000010` |
| Slide | `--bg` | `#05001c` |
| Accent / process | `--orange` | `#fd6701` |
| Deep accent | `--orange-deep` | `#eb6700` |
| Paper / evidence | `--cream` | `#f4e4d4` |
| Proof / release | `--green` | `#34a448` |
| Proof panel | `--green-deep` | `#173421` |
| Quiet panel | `--soft` | `#17112f` |
| Body on navy | `--white` | `#ffffff` |
| Body on cream | `--ink` | `#221d33` |
| Secondary | `--muted` | `#d5d3e0` |
| Rule | `--line` | `#484258` |

Meaning, keep it stable across a deck:

- Cream = source, paper, evidence, local/default state
- Orange = process, emphasis, in-flight work
- Green = proof, review, release, production/payoff
- Navy = ground. Do not tile a CSS grid over it.

Type: Google Fonts Barlow 400/600/700/800. Authored sizes are px at 1920×1080. Body on a content slide starts near 24px. Do not author slide type below 17px. Display tracking floor `-0.04em`.

Motion: one system. `.reveal` plus `.d1`–`.d4`. 350ms expo. No particles, glitch, custom cursors, or atmospheric gradient meshes unless the operator names a different world.

## Chrome

Every content slide: `.head` with `.section-tag` + `h1`, optional logo slot on the right, `.content` at 820px, `.slide-index` `01 / N`.

Title/close slides: `.hero-slide` + `.slash`. If a `.slash` is present, `.hero-top` already has `padding-right: 400px` so content does not sit under the clip. Logos are optional. If the operator supplies logos, use `.brand` with explicit width/height and `object-fit: contain`. Do not invent org marks.

Corner chevron on content slides comes from `.slide::before`. Leave it.

## Process language

Use these instead of identical icon-title-body card grids.

**Chevron / flow-arrow.** Sequence. Stretch height to the adjacent panel. Alternate orange/cream; use green for review, commit, release, production.

**Top band.** `border-top: 7px–10px solid` orange, cream, or green on a `.soft` or cream panel. Not a 2px+ left border.

**Numbered spine.** `.spine-bar` plus rotated square `.spine-node` for milestone or stage counts. Put the readable number inside the node, counter-rotated. Do not park a five-node spine above a 3+2 card wrap; if the count does not fit one row, number the cards instead.

**Status chips.** Source / synthesis / delivery, or any three-state key. Cream, orange, green.

**Substitution row.** Two states with a chevron between them (local vs production, before vs after, request vs result).

## Layout recipes

Copy and adapt. Measure in px. If a recipe overflows, split the slide.

**Evidence chain (title or process path)**

```css
.hero-chain {
    position: absolute; left: 0; right: 130px; bottom: 56px;
    display: grid; grid-template-columns: repeat(6, 1fr 44px) 1fr;
    align-items: stretch;
}
.chain-node {
    min-height: 126px; padding: 19px 18px 16px;
    color: var(--ink); background: var(--cream); border-top: 9px solid var(--orange);
}
.chain-node:last-child { background: var(--green); border-top-color: var(--green); }
```

Columns = `2n-1` nodes + `n-1` chevrons. Last node is the payoff.

**Numbered finding / requirement row**

```css
.finding-row {
    min-height: 118px;
    display: grid; grid-template-columns: 72px 0.88fr 1.12fr;
    border-bottom: 2px solid var(--line);
}
.finding-num { display: grid; place-items: center; color: var(--bg); background: var(--orange); font-weight: 800; }
.finding-evidence { color: var(--ink); background: var(--cream); padding: 18px 22px; }
.finding-effect { background: var(--soft); padding: 18px 22px; }
```

**Workflow path.** Same chevron grid as the chain, taller cream steps, green steps for review/release. Actor label uppercase 17px, step number 42px, title, one short paragraph.

**Plane band.** Numbered `.plane-order` square + title + paragraph. Evidence plane cream; payoff plane `--green-deep`. Connect with `.flow-arrow`. Prefer two rows (3 + 2) over five squeezed columns.

**Pack / document sheet.** Cream panel, clipped corner (`polygon(0 0, 94% 0, 100% 9%, 100% 100%, 0 100%)`), field grid with `#aa9988` rules.

## Diagrams

Draw process and architecture as HTML/CSS using this grammar. Do not drop generated raster diagrams onto slides; labels garble. Mermaid is a source, not a slide embed.

If a raster is required, leave the HTML diagram in place and add an HTML comment on that slide:

```html
<!-- UI-AGENT DIAGRAM SPEC
palette: navy/orange/cream/green
layout: ...
labels: ...
do not draw: scenery, mascots, vendor architecture posters
-->
```

Icons are optional node anchors, not the structure. Phosphor (MIT) only, inline `<symbol>` sprite, `.icon > use href="#ph-...">`. Comment: `Icons: Phosphor Icons (MIT)`. Empty `alt` and `aria-hidden="true"` when the nearby text already names the thing. Include only symbols the deck uses.

Images: relative paths next to the HTML (`assets/...`). Never `file://`, never absolute home-directory paths. Do not base64. Do not repeat a photo across slides except an optional logo on title and close.

## Override worlds

If the operator names another visual world (palette, type, era, reference surface, existing tokens), commit to that world and keep the 1920×1080 stage, visibility switching, runtime, copy rules, and overflow rules. Translate the new world into stage px. Do not keep live `vw`/`vh`/`clamp()` inside slides. Do not mix the default orange/green grammar into the new world. Do not generate three style options.

A named brief, existing CSS tokens, or a supplied reference surface wins over this default.
