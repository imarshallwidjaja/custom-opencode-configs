# Transition storyboards

A storyboard shows one interaction as four numbered frames from the real screen, with exact captions and a timing bar for each element that changes.

## Decide the motion first

Load `animate` and decide each motion before drawing anything: whether it should animate at all, given how often it happens and whether a keyboard starts it; its purpose; its property, curve and duration; and its reduced-motion behaviour. Elements that change instantly still appear in the storyboard, as instant changes. Write the decisions as a motion inventory table for the README:

| Interaction | How often | Purpose | Motion | Reduced motion |
|---|---|---|---|---|

If the product will have a stylesheet, record the same values as a reference CSS file in `assets/`.

## Generate the frames

Generate the start and end states as normal approved screens first. Then make one call for one grid image, passing those screens as references:

- A 2 x 2 grid of four frames on the product's background colour, with even gutters and margins.
- Each frame is the whole screen, scaled down uniformly. Do not enlarge the UI inside a frame; its text will be small, and the captions added later carry the exact wording.
- A small numbered tag at each frame's top-left.
- A thin outline in the accent colour around whatever changes in that frame.
- No title, captions, arrows, motion trails, ghost outlines or other annotation text.
- Describe each frame's state precisely: what is selected, what has moved, what text reads, and what stays the same.

Read the returned size, then check that elements meant to stay fixed hold their position across frames. If one correction attempt does not fix a drifting element, patch the frame from another generation along a gutter, or record the drift as a known limit.

## Add the text

Write a spec JSON with a title, subtitle, a caption and timing tracks for each frame, a footer covering keyboard and reduced-motion behaviour, and `colors` set to the product's palette. Then run:

```bash
uv run --with pillow --with numpy python <skill-dir>/scripts/compose_storyboard.py \
  --grid frames.png --spec storyboard.json --out transition-<interaction>.png \
  --font-regular <product-font-Regular.ttf> --font-semibold <product-font-SemiBold.ttf>
```

The script's docstring documents the spec format. Captions run in one numbered row under the grid, and the numbers tie each caption to its frame. Tracks share one millisecond scale, 0 to 500 ms by default; an instant change draws as a dot at zero.

Name each storyboard file after its interaction, for example `transition-open-detail-drawer.png`.
