---
name: ui-mockups
description: Use when asked to create or revise image-generated mockups of an application or product interface, such as screen concepts, responsive or device variants, or transition storyboards, including when existing mockups look oversized, cramped, inconsistent with each other, or off-spec.
---

# UI mockups

A mockup is a picture of a real screen at a real size. Fix the scale before generating anything, draw each layout at true size, let the image model add the style, then measure the result against the spec and deliver it with its limits stated.

## What this skill owns

This skill owns the deliverable: which screens and states to show, the scale contract, true-scale layout references, the study of named reference sites, the anchor-first sequence, storyboards, review against the spec, and the delivered folder with its assets.

It hands off:

- How to generate and edit images, to the selected image-generation tool and its companion skill, using the handoff below.
- Visual direction and critique, to the design skills in play, such as `impeccable`, `aero-design` and `stop-design-slop`.
- Which motions exist and their timing, to `animate`.
- Landing-page and marketing section imagery, to `imagegen-frontend-web`. Building code from images, to `image-to-code`.

### Select the image tool and load its guidance

Choose an exposed image generation or editing tool that accepts the layout and style references this skill produces and returns an image you can open and measure. When creation and editing are separate tools, select the operation that takes references, for layout-guided images and for revisions. If no exposed tool qualifies, report the missing capability before attempting generation. Before the first generation or edit, read the selected tool's current description and argument schema, then load the companion skill it names when available and permitted; reuse it if already loaded. If the tool names no skill, check the available skill descriptions for one explicitly covering that tool. Use the selected tool's current arguments and limits, rather than settings remembered from another tool. If its companion skill is unavailable or denied, follow the tool description without bypassing that restriction.

## 1. Scope the set

Choose the fewest screens that prove the design: the main task screen, an authoring or form screen if the product has one, a screen where the column layout changes, and one smaller device. Add a state such as loading, stale or error where the brief cares about it, and a storyboard for each transition the brief asks about. Write one line per image saying what it proves. When the set has more than four images or the brief is open, confirm it with the operator in a single question, together with anything else that changes geometry, such as theme or whether a panel pushes or overlays content.

## 2. Fix the scale contract

- Choose the target viewport in CSS pixels at 1x. Use the sizes the product or brief names; otherwise default to 1920 x 1080 for desktop and 1180 x 820 for a landscape tablet. Put the viewport in every prompt.
- The viewport is the design target, not necessarily a supported generation size. Choose an output size allowed by the selected tool that best matches the target aspect ratio; keep the layout reference at the target size and record any resizing or cropping in the deliverable.
- Take every size from the spec: type scale, row heights, panel widths and gutters. If there is no spec, write starting values down before generating. If the product has no palette or typeface yet, settle them with the design skill in play before drawing anything.
- Sizes given only in prose can produce oversized controls or too few rows. The layout reference in step 3 makes the intended geometry explicit; measure the generated result rather than assuming it matched.

## 3. Draw a layout reference for every screen

Before generating a screen, draw its layout at true size in code with the product's real typeface. Include the panels, rows and controls, text at the spec sizes, and grey placeholders for maps, charts and imagery. This drawing is the geometry the image model copies.

```python
from PIL import Image, ImageDraw, ImageFont
spec = {"viewport": (1920, 1080), "sidebar": 240, "row": 40, "body": 14, "ground": "#F4F4F5"}
font = lambda weight, px: ImageFont.truetype(f"/path/to/ProductFont-{weight}.ttf", px)
rows = [...]                                   # real item names from the spec or sample data
W, H = spec["viewport"]                        # 1 image px = 1 CSS px
img = Image.new("RGB", (W, H), spec["ground"]); d = ImageDraw.Draw(img)
d.rectangle((0, 0, spec["sidebar"], H), fill="white")
for i, name in enumerate(rows):
    y = 64 + i * spec["row"]
    d.text((spec["sidebar"] + 24, y + 12), name, font=font("Regular", spec["body"]), fill="#18181B")
d.rectangle((spec["sidebar"] + 640, 64, W - 16, H - 16), fill="#D4D4D8")   # chart placeholder
img.save("layout-<screen>.png")
```

Draw the real content and real counts: twelve rows if the spec fits twelve.

## 4. Anchor the style, then derive the rest

- Gather style references. When the operator names a site, study it with a browser first; read [references/reference-study.md](references/reference-study.md). Draw a small material board from the product's palette: swatches, surface planes, shadows, a control or two.
- Generate one anchor screen from its layout reference and the style references. Correct it, then show it to the operator for approval when they are available; otherwise check it against the spec yourself. Generate nothing else until the anchor is settled.
- Generate every other screen from its own layout reference with the anchor as the style reference.

## 5. Storyboard transitions

When the brief asks for transitions, read [references/storyboards.md](references/storyboards.md). It covers deciding the motion with `animate`, generating the frames as a single grid, and adding exact captions and timing bars with `scripts/compose_storyboard.py`.

## 6. Review against the spec

- Read each result's pixel size first. The scale factor is the viewport width divided by the image width; multiply measured lengths by it. Check that the image's aspect ratio matches the viewport, and say so in the README if the tool could not produce it.
- Measure the anchor screen and one sibling: row pitch, panel widths, and the cap height of a known line of text. Record the deviation from the spec.
- Check domain truth. Colour must not imply a status the spec does not give it. Sample data is labelled. Legends, units and timestamps are present. No metric is invented.
- Check consistency across screens: the same shell, controls and icons.
- Make one batched correction round, then stop and list what remains wrong.

## 7. Deliver

- Put the final images in one folder, named by purpose, for example `settings-profile.png` and `transition-sidebar-collapse.png`.
- Add a README with:
  - the sources: references, the date studied, and what was taken from each;
  - the scale contract and the measured deviation;
  - one paragraph per image saying what it proves;
  - the motion inventory, if there are storyboards;
  - the known limits.
- Put durable assets the design needs in an `assets/` folder beside the images, as vectors or code. For example:
  - icons from an existing set, with the source, licence and commit recorded;
  - SVG drawn in the same style where the set has a gap;
  - tileable patterns, such as fills for missing data;
  - reference CSS for motion.
- To get a vector logo, trace the existing raster artwork with `uv run --python 3.12 --with vtracer` (VTracer crashed under Python 3.14) instead of generating a new logo.
- Keep drafts, layout references, captures, frame grids and storyboard specs in a temporary directory, and delete them once the deliverable is final.
