# Terminology: translating memorable rules into design language

This file gives agents vocabulary that is portable across products and design systems. The colloquial names are retained because they are memorable; the formal terms improve reasoning and communication with designers/engineers.

| Colloquial rule | More standard terminology | What it means in practice |
|---|---|---|
| Card soup | Excessive **common-region grouping**; over-containerization; surface proliferation | Containers are strong Gestalt grouping cues. Too many create unnecessary boundaries and competing surfaces. |
| Round everything | Indiscriminate **shape-token** application; excessive corner-radius uniformity | Shape should vary with component semantics, scale, and brand system rather than be globally decorative. |
| Pills everywhere | **Chip/tag/capsule misuse** | Capsule geometry implies a compact token, state, filter, or selection; using it as arbitrary decoration weakens meaning. |
| AI gradient aesthetic | Trend/default-style convergence; decorative effect stacking | A familiar combination of gradient, glow, blur, and translucent surfaces becomes a stylistic prior rather than a product decision. |
| Glass everywhere | Gratuitous translucency / depth cue misuse | Transparency should communicate layering or preserve spatial context, not merely signal "premium". |
| Standard SaaS hero | Template convergence; pattern cargo-culting | A familiar page archetype is copied without evidence that it supports the product's content, audience, or task. |
| Three feature cards | Artificial equality; grid-driven information architecture | Equal columns visually assert equal priority. The information model should determine composition. |
| Icons as decoration | Decorative iconification; low-information iconography | Icons should aid recognition, scanning, state, or action comprehension. |
| Center everything | Alignment monotony; weak reading-order support | Centering can impede scanning in dense interfaces and removes a strong structural axis. |
| Typography isn't doing the work | Weak typographic hierarchy | Size, weight, line-height, contrast, and spacing should establish importance before adding surfaces. |
| Everything is equally polished | Equal salience / weak visual hierarchy | When every element has similar contrast, framing, size, and emphasis, attention has no clear path. |
| 24px gap everywhere | Mechanical token application; weak proximity encoding | Spacing tokens are a vocabulary; varying them communicates relationships and transitions. |
| Perfect symmetry | Default symmetry; weak dominant/subordinate composition | Symmetry is useful, but unequal information often benefits from asymmetric mass and scale. |
| Fake dashboards/charts | Decorative data-ink; fictive product artifact | Invented data visuals imply functionality or evidence the product may not actually possess. |
| Four KPI cards | KPI tile cargo cult; salience without decision value | Metrics should be prominent because they drive action, not because dashboards traditionally have tiles. |
| Premium minimalism | Low-density aesthetic optimization; showroom UI | Excessive whitespace and sparse content can harm comparison, monitoring, and operational work. |
| AI copy | Generic benefit-language; low information scent | Vague claims reveal little about actions, objects, or outcomes and lead to generic visual treatment. |
| Looks like shadcn | Component-library fingerprinting | Behavioral primitives have become the visible identity because product-specific composition/theme work was not done. |
| Lots of nice effects | Ornament without governing concept | Effects increase local polish while failing to create a coherent global composition. |
| Brand = accent color | Surface-level theming; weak distinctive visual language | Brand differentiation should survive beyond color through type, geometry, density, imagery, motion, charts, and interaction. |

## Related concepts

### Visual hierarchy and salience
The arrangement of visual variables — position, scale, contrast, type weight, color, whitespace, shape, and motion — so viewers can infer relative importance and sequence.

### Gestalt proximity
Items close to one another are more likely to be perceived as a group. Use proximity before borders when it communicates the relationship sufficiently.

### Gestalt common region
Items enclosed by the same boundary are strongly perceived as grouped. Cards/panels are therefore semantically expensive; each boundary should mean something.

### Visual clutter
Excess or disorganization of visual features that makes search, segmentation, and recognition more difficult. Clutter is not identical to information density: a dense, well-structured table can be less confusing than a sparse collection of visually competing cards.

### Information density
The amount of task-relevant information available in a given area. High density can be desirable for expert, monitoring, comparison, and analytical workflows if hierarchy and grouping remain strong.

### Progressive disclosure
Keep secondary or advanced information available without giving it equal initial salience. This is preferable to deleting useful information solely to achieve a minimalist screenshot.

### Information scent
Cues that help users predict where an action/link will lead or what information lies behind it. Specific labels usually carry stronger information scent than generic benefit copy.

### Prototypicality
How closely a design matches users' learned expectations for a category. Research shows prototypicality can improve immediate aesthetic judgments; this skill therefore does **not** advocate arbitrary novelty. Preserve category conventions that support orientation while differentiating the product in composition, content, and identity.

### Design fixation
Over-reliance on an initial example or familiar solution, reducing exploration and diversity. Recent GenAI research has observed fixation/homogenization effects, making explicit divergence and product grounding useful when AI generates interfaces.

### Aesthetic-usability effect
People can perceive aesthetically pleasing interfaces as easier to use, especially at first impression. This does not mean ornament improves actual task performance. Visual craft should reinforce usability rather than mask weak structure.

### Affordance and signifier
An affordance is what an object allows; a signifier communicates where/how an action can occur. Decorative controls that resemble interactive chips/buttons without behaving like them can create misleading signifiers.

### Design tokens
Named values for system decisions such as spacing, typography, color, radius, and elevation. Tokens create consistency; they are not instructions to use the same value everywhere.
