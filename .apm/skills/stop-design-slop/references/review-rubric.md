# Anti-slop review rubric

Score each dimension 0–2.

- **0 = fails**: generic, misleading, or structurally weak.
- **1 = acceptable**: functional but not strongly resolved.
- **2 = strong**: deliberate, product-specific, and task-supportive.

A score is diagnostic, not a substitute for user testing.

| Dimension | 0 | 1 | 2 |
|---|---|---|---|
| Dominant task | unclear | inferable | immediately obvious and supported |
| Primary object | absent/buried | visible | clearly governs composition |
| Hierarchy | equal salience | partial priority | first/second/third attention path clear |
| Grouping | container-heavy/arbitrary | mostly logical | boundaries map to semantics |
| Typography | many weak styles | coherent | hierarchy works without extra boxes |
| Density | sparse/cluttered for task | usable | task-appropriate and scan-efficient |
| Product specificity | logo-swap compatible | some domain cues | structure/artifacts clearly product-specific |
| Authenticity | fictive decorative data | sample content disclosed | real artifacts/data drive visuals |
| Component differentiation | starter-kit obvious | customized | library is invisible as aesthetic source |
| Decoration | stacked/default effects | restrained | motif has clear role/identity |
| Brand structure | mostly color | some recurring form | recognizable through type/geometry/density/etc. |
| Accessibility | visible issues | baseline | contrast/focus/targets/scaling/order deliberately handled |

## Mandatory tests

### Logo-swap test
Could the logo/company name be replaced by an unrelated SaaS brand with no structural changes? If yes, identify at least two product-specific compositional decisions to add.

### Card-removal test
Temporarily remove card background/border/shadow. If hierarchy remains intact, consider deleting the card permanently.

### Decoration-removal test
Disable gradients, glows, shadows, blur, and exaggerated radius. If the design loses its identity or hierarchy, strengthen composition first.

### Squint test
Blur/squint at the screen. Can you identify first, second, and third attention targets? If not, reduce equal salience.

### Product-proof test
For every prominent screenshot/chart/map/statistic/logo strip, ask whether it is authentic, representative, and useful. Delete decorative fiction.

### Interaction-signifier test
Anything that looks clickable should behave clickable; anything decorative should not mimic controls/chips/buttons.

### Component-library test
Can a reviewer name the starter kit from the page? If yes, identify whether the giveaway is macro layout, default typography, radius, component proportions, surface treatment, or icon treatment and customize there.

### Screenshot-vs-task test
Would a power user accept this layout after eight hours of real work, or is it optimized primarily for a portfolio thumbnail?

## Suggested release gate

- No dimension at 0 for production-critical screens.
- At least 18/24 overall for a "strong" anti-slop pass.
- Accessibility cannot be traded away for distinctiveness.
- For experimental/brand pages, product specificity and governing concept should usually score 2.
- For enterprise/regulated software, task, hierarchy, density, authenticity, and accessibility matter more than stylistic novelty.
