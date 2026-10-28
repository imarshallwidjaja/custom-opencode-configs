# Studying a named reference site

Use this when the operator names a site or product as the look to follow. The study produces two things: screenshots that go into image prompts as style references, and measured values that go into your notes and the README. It does not change the operator's spec.

## Capture

Use the interactive browser tool, not a page fetch, because rendered state is the evidence.

- Every page the operator named, at the target desktop width and at one narrower width (about 1180 px), so you see how columns change.
- Both themes when the site has them. Capture the theme closest to the product's own as the main style reference.
- States, not just resting screens: a panel hidden or shown, a hover, a card or tab mid-transition if the site animates. Click the real controls and screenshot each state.
- Public pages only. If the product itself sits behind a login, study its public pages and the product screenshots it publishes; do not sign in, connect a wallet or create an account.
- A 2x device-pixel-ratio capture of one dense region, cropped, when you need to read fine detail such as shadows or icon strokes.

Save captures to a temporary directory with descriptive names (`<page>-<theme>-<width>.png`).

## Read the code

Evaluate scripts in the page to pull facts the screenshot cannot show:

- CSS custom properties on `:root` and theme classes: the palette, by role.
- Rules containing `box-shadow`, `backdrop-filter`, `gradient`, `mask-image`, `transition` and `animation`: depth, translucency, fades and timing.
- Computed styles up the ancestor chain of a characteristic element: radius, shadow, background and font for each plane.
- Grid template columns before and after a layout change: how the columns morph.
- For motion, sample `getComputedStyle(el).transform` every animation frame through one interaction to get duration and easing.

Write the findings to a short notes file: tokens, depth planes, layout rules, motion, and anything you will deliberately not carry over.

## Translate

Carry over the visual system: the depth model, spacing rhythm, type hierarchy, layout behaviour and control styling. Keep the product's own palette, typeface, brand and content. Leave the site's showcase motion behind unless the operator asks for it; motion is decided separately with `animate`.

Record in the README which pages you studied, when, at which widths and themes, and which values were measured rather than estimated.
