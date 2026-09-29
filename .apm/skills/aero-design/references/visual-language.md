# Visual language: quiet framing, confident information

Use this reference to establish the composition and visual relationships.
These are transferable design directions, not a measurement sheet for Aero.
Read the observation limits and original reference links in [Sources](sources.md).

## The characteristic combination

The intended result is not simply "minimal". Preserve all three qualities:

**Editorial confidence:** deliberate scale, a clear beginning, concise framing,
and variation in pacing. Something important is allowed to be visually strong.

**Operational precision:** stable alignment, efficient controls, comparable
records, legible small detail, and dependable states. Important work is not
sacrificed to whitespace.

**Quiet material treatment:** few competing surfaces, selective colour, restrained
borders, and enough separation to reveal structure without boxing everything.

An interface with only the first quality becomes a marketing page. One with only
the second becomes a dense utility. One with only the third becomes an empty,
low-contrast template. The craft is in their combination.

## Compose around the information, not the UI kit

Before styling, name the main task and the relationship between the visible
regions. Decide which region establishes context, which carries the signal, and
which allows comparison or action. These do not have to be separate panels.

A coherent data page often feels like one composed surface: a short framing
statement, a main metric or evidence region, then structured supporting detail.
Avoid a collection of equally loud widgets with unrelated titles, borders,
colours, and internal spacing.

A small number of aligned anchors should connect page title, controls, data,
and notes. Give the principal object room to be understood. Secondary controls
should live close to what they change, not in a distant global toolbar.

**Before:** header, six KPI cards, three chart cards, one table card, all at the
same visual weight.

**After:** a scoped question, one coherent signal group, the comparison that
explains it, and a detailed view. Keep additional metrics when they answer an
actual question; do not remove them merely to reach an arbitrary count.

## Typography is the primary visual material

Use a limited set of text roles, each with a job:

| Role | Job | Treatment |
| --- | --- | --- |
| Page title | Establish destination or task | Confident scale, concise wording, clear alignment |
| Main value or object | Carry the immediate signal | Strongest local emphasis; proportionate to task |
| Section heading | Make a change of topic legible | Clear but subordinate to the page purpose |
| Body / explanation | Make the content understandable | Comfortable size and line length; ordinary language |
| Control / row label | Support action and repeated scanning | Consistent weight; durable legibility |
| Metadata / qualifier | Add necessary context | Quieter position and scale, never inadequate contrast |

Distinguish roles with a few coordinated changes, not all possible styling at
once. A title need not be simultaneously huge, bold, uppercase, accented, and
underlined. Avoid excessive letter spacing on ordinary labels.

Use the existing typeface when it supports the task. Evaluate it with actual
numerals, currency signs, minus signs, decimal separators, long entity names,
and localisation. Do not choose a display font based only on a hero headline.
Numbers used for comparison should have stable widths or alignment; compact
identifiers may benefit from a secondary treatment without making the whole
application monospaced.

For a new system, begin with a comfortable body size and a clear relative scale.
A product title might be roughly twice the body size, with a main metric somewhat
larger when it is the page's purpose. These are optional proportions, not rules
for every platform. Preserve readable body type before increasing display size.

## Spacing communicates relationships

Separate three kinds of space:

- **Within a fact:** the label, value, and immediate qualifier remain close.
- **Within a group:** related facts share alignment and a consistent rhythm.
- **Between topics:** noticeably more separation signals a new reading task.

Use a small spacing family rather than choosing a new gap for every component.
An optional starting rhythm is one base unit for tight relationships, two to
three for component internals, four to six for related groups, and larger jumps
for sections. Choose the base through the existing product, not this reference.

Airiness belongs between ideas; it does not require excessive padding inside
every row. Compactness belongs in repeated working information; it does not
justify reducing the entire type scale.

On a large screen, constrain explanatory prose while allowing genuinely useful
tables, charts, or maps to use more width. A fixed editorial max-width must not
force an expert comparison tool into a narrow strip.

## Fewer surfaces, clearer boundaries

Before adding a container, ask what boundary it communicates.

| Boundary | Appropriate treatment |
| --- | --- |
| Related facts on one page | Spacing, heading, alignment, perhaps a divider |
| Independent object or separate data scope | A panel or card can be useful |
| Editable region | Clear grouping and control affordances |
| Selected record | Selection treatment distinguishable from hover |
| Floating or transient context | Surface contrast and elevation |
| Warning affecting interpretation | Local, explicit treatment proportionate to consequence |

Do not remove useful boundaries merely to satisfy a "no cards" rule. Conversely,
repeated nested panels often indicate that spacing and hierarchy are doing too
little work. Most embedded regions need less elevation than an actual popover.

Choose a modest radius family matching the brand. A pill implies a specific
control or tag treatment; it need not be the default shape of every rectangle.
Keep shadows purposeful. A flat comparison table can feel more polished than
individually elevated rows because its relationships are easier to read.

## Colour has separate jobs

Use neutral relationships to create the reading hierarchy. Apply brand emphasis
where it earns attention: a principal action, active navigation, selected range,
or important series. A light tint may separate a region without making it a
new visual object.

Keep these meanings distinct:

| Role | Question it answers |
| --- | --- |
| Brand | Which product is this? |
| Interaction | What can I do, and what is active or selected? |
| Category | Which entity or series is this? |
| Status | Is there success, warning, failure, or uncertainty? |
| Change | What direction or magnitude has changed? |

Do not assume the roles can all use the same palette. The product's green accent
must not make a neutral increase look approved. Category colours should not
change between screens. Use enough distinctions for the real comparison rather
than imposing one colour on an ambiguous multi-series chart.

A grayscale check is a hierarchy diagnostic, not a requirement that every data
series become indistinguishable. Retain labels, patterns, symbols, or ordering
as additional cues.

## Control hierarchy and entity identity

Give the dominant action a clear local priority. Independent workflows may each
have a primary action; the aim is unambiguous hierarchy within a decision context,
not one coloured button across an entire product.

Secondary actions should remain recognisable as controls. Reduced prominence
must not mean invisible until hover. Use labels when icon meaning is ambiguous.
A user should be able to identify search, filters, sort direction, selection,
and disabled reasons without hunting.

In repeated records, distinguish identity from quantitative comparison. An entity
name with a small icon and predictable secondary line is often enough. Replace
badge clusters with concise text when every badge merely repeats ordinary
metadata. Keep full names or identifiers accessible when the display is abbreviated.

## Dark and light modes

Preserve the same hierarchy, not the same raw values. Reconsider canvas, embedded
surface, floating surface, separators, primary text, and secondary text as
relationships. Shadows may contribute less on a dark canvas; surface contrast
and boundaries may carry more of the structure.

Check categorical colours, warning states, grid lines, focus, and selected rows
in each theme. Do not make all data glow in dark mode or reduce every secondary
label to a faint grey. A colourful brand can still live inside a quiet analytical
surface.

## Motion: responsive, not performative

Start with no animation and add it only where a state transition becomes clearer:
a detail panel has entered, a control has responded, a selection has moved, or a
transaction has progressed. The interaction should remain fast under repeated use.

Illustrative web starting ranges—not Aero timings—are roughly 100–180 ms for
small feedback and 160–260 ms for transient surfaces. Use the host platform's
conventions and reduced-motion settings. Timing is subordinate to the task.
Avoid obligatory number count-ups, staggered working rows, decorative looping
backgrounds, or hover movement that makes a target harder to reach.

See [Emil Kowalski's discussion of unnecessary animation](https://emilkowal.ski/ui/you-dont-need-animations)
for an additional craft reference. It is inspiration, not a required library.

## Narrow screens and different platforms

Translate the reading task rather than reproducing a desktop arrangement. Keep
scope, principal result, material caveat, and next action understandable. A table
may become prioritised records when individual lookup matters; preserve a
comparison layout when cross-row comparison is the job.

Use platform-native navigation, sheets, dialogs, tables, and accessibility
behaviour. The transferable system is the hierarchy and relationships. A native
application does not need CSS, web-like hover states, or custom replacements for
its platform's controls to apply this skill.
