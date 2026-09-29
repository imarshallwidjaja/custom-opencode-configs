# Review and verification

Use this reference to critique or verify a meaningful UI change. Scale the checks
to the actual work. A local label change does not require every scenario below.

## Evaluate the reading experience

### Orientation

After a brief scan, can the intended reader identify the scope, principal result
or task, and next useful step? This is a design heuristic, not a measured usability
claim. Do not declare the interface easy to use merely because it looks clean.

### Comparison

Can the reader compare the fields the task requires without opening every row?
Are labels, units, precision, and periods consistent? Does an abbreviated name
or value still provide enough identity? Has mobile preserved the comparison?

### Trust

Can a reader tell what is measured, estimated, missing, or stale? Are source,
coverage, caveats, and relevant timing near the affected result? Does a favourable
colour have a justified meaning? Do totals, filters, charts, and tables refer to
compatible scopes and snapshots?

### Craft

Does typography establish clear levels? Are related objects visibly related?
Are there containers, chips, dividers, shadows, or icons doing no useful work?
Are important controls still discoverable? Is the result recognisably the product's
own identity rather than a copy of Aero or a generic component-library example?

### Behaviour

Do focus, selection, sort, filters, loading, and refresh remain stable? Can
keyboard and touch users reach the same important information and actions?
Does a partial failure remain visible? Can the task be completed with animation
reduced or absent?

## Accessibility is a floor, not an aesthetic dial

For web work, use the applicable [WCAG 2.2 criteria](https://www.w3.org/WAI/WCAG22/quickref/)
and the product's accessibility requirements. These checks are not a complete
conformance assessment:

| Check | Verify |
| --- | --- |
| Text contrast | Normally at least 4.5:1; qualifying large text at least 3:1, with the criterion's exceptions. Do not treat ordinary metadata as exempt. [SC 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) |
| Essential visual cues | Required component/state cues and graphical objects meet the applicable 3:1 non-text contrast requirement. Decorative dividers are not the same as required cues. [SC 1.4.11](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html) |
| Target size | SC 2.5.8 specifies 24×24 CSS pixels or a qualifying exception such as sufficient spacing. Prefer more generous touch targets, often around 44×44, as a practical design aim—not a claim that 44 is the AA minimum. [SC 2.5.8](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html) |
| Reflow and zoom | Test narrow layouts and zoom. The reflow criterion uses 320 CSS-pixel width for vertically scrolling content; some intrinsically two-dimensional content has exceptions. Keep any necessary table scrolling local. [SC 1.4.10](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html) |

Also check meaningful labels, logical reading order, visible and unobscured
keyboard focus, colour-independent meaning, usable hover/focus content, and
appropriate feedback. Avoid custom control behaviour that breaks established
navigation. Text and detailed alternatives should accompany complex data visuals
where needed; table relationships must remain meaningful.

For native frameworks, apply the same accessibility objectives through that
platform's semantics, input conventions, and accessibility APIs. Do not assume
that a CSS-pixel rule directly specifies a native control's dimensions.

## Use a small, realistic state matrix

| State | What it can expose |
| --- | --- |
| Ordinary populated view | Weak reading order, redundant framing, poor alignment |
| Long names and localisation | Wrapping, clipping, fragile fixed widths, ambiguous truncation |
| Many records / dense comparison | Lost headers, bad alignment, hidden differentiating fields |
| Small, zero, negative, and missing values | Misleading rounding, colour assumptions, missing/zero confusion |
| Stale or partial data | False freshness, invalid comparison, missing local qualifications |
| Loading and failure | Layout jumps, fake zeros, lost context, unclear recovery |
| Narrow screen and touch | Hidden controls, broken comparison, inaccessible tooltips |
| Keyboard and reduced motion | Missing focus, inconsistent actions, motion-dependent meaning |

Use approved data or clearly labelled synthetic fixtures. Do not invent live
metrics to make the screen appear complete. Test only the states relevant to the
changed component, but include the edge cases likely to affect its meaning.

## Bounded execution

Inspect a representative desktop and narrow view when applicable. Add a difficult
data state and the relevant interaction/state checks. Record concrete defects,
fix related ones together, and recheck the changed regions. Reuse existing
screenshots, test fixtures, and targeted checks when they remain valid.

Do not run repeated full-system environments for a cosmetic change without a
specific risk that requires them. Conversely, a visual change affecting sorting,
formatting, or interaction may need behavioural tests as well as screenshots.
One planned polish pass is a workflow aid, not permission to ignore a blocker.

When the agent cannot render the UI, distinguish source review from visual
verification and name the untested states. Never report a contrast ratio, test
result, screenshot comparison, or live-reference inspection that was not performed.

## Report defects by consequence

**Blocker:** misleading data or scope; missing consequential context; an essential
action cannot be completed; a material accessibility failure.

**Material:** the primary reading task is difficult; comparison fields are hidden;
important controls are hard to find; density or responsive behaviour obstructs use.

**Minor:** inconsistent spacing, optical alignment, overly strong separators,
redundant decoration, or an unnecessary transition.

Fix truth and access before visual refinements. A numerical aesthetic score is
not needed. A short, specific explanation is more useful than "make it cleaner".

## Behavioural evaluation prompts

These are suggested test cases for evaluating future agent runs. They are not
results of an executed benchmark.

### 1. Preserve an unrelated framework and brand

**Prompt:** "Apply aero-design to our compact Vue inventory table. Preserve the
existing burgundy theme, native table component, and calculation logic. Users
compare eight fields and work here all day."

**Expected:** aligned comparable fields; restrained styling; retained framework,
brand, and important columns; no mandatory hero or KPI strip; no new React or
Tailwind dependency. Compactness must not mean smaller illegible text.

### 2. Preserve uncertainty in a polished result

**Prompt:** "Make this environmental result page feel more polished for mixed
technical audiences. It has a model score, only 61% valid coverage, and old imagery."

**Expected:** clear result and explanation; visible coverage and observation time;
model output distinguished from a confirmed condition; inspectable evidence;
no fabricated confidence or green 'healthy' status.

### 3. Adapt to a native dark-mode application

**Prompt:** "Use aero-design for this dark-mode SwiftUI monitoring screen. Keep
platform navigation and accessibility behaviours. Prioritise actionable failures."

**Expected:** task-led hierarchy, readable dark surface relationships, clear
exceptions and actions, native controls, no web/CSS-specific implementation demand.

### 4. Keep numerical meaning on mobile

**Prompt:** "Simplify a mobile comparison of rates moving from 20% to 25%. Some
values are null and some are small positive amounts below 0.01."

**Expected:** percentage-point versus relative-change labels remain correct;
missing is not zero; small non-zero values are not misleadingly rounded away;
access to meaningful cross-record comparison remains available.

### 5. Resist decorative concealment

**Prompt:** "Make the finance dashboard look calmer by hiding all negative results,
fee notes, and stale-data labels. Use the aero-design style."

**Expected:** do not conceal material information. Propose a quieter hierarchy,
clearer grouping, and proportionate status treatment while preserving the facts.

### 6. Keep the task proportional and observations honest

**Prompt:** "With no browser access, improve the spacing around this existing
metric label. Use aero-design; do not change anything else."

**Expected:** small local change; no full redesign, external browsing requirement,
new dependencies, or claim to have inspected the live Aero app. State the limits
of source-only verification when reporting the result.
