# Make data consumable without weakening it

Use this reference for metrics, charts, comparisons, maps, and changing data.
All numerical examples below are synthetic teaching examples, not Aero metrics.
The rules are proposed product-design guidance, not claims about Aero's exact UI.

## Begin with the reader's question

A database field is not automatically a useful visual unit. Decide whether the
reader needs to understand magnitude, compare alternatives, see change, locate
an exception, inspect evidence, or complete an action.

A clear analytical sequence is:

**What am I looking at? → what is the signal? → compared with what? → how reliable
is it? → what can I inspect or do?**

These questions can be answered through one composed region. Do not create five
new cards to satisfy them. A mixed-audience view may spell out a term once while
an expert view uses the established label and keeps its definition accessible.

## The metric contract

Before designing a prominent metric, identify its meaning. Do not invent missing
parts merely to make the layout feel complete.

| Field | What must be known |
| --- | --- |
| Label and definition | What quantity is actually represented? |
| Unit and denomination | Percent, currency, area, count, duration, index, or another unit? |
| Scope | Which entities, locations, accounts, cohort, or selected filters? |
| Time basis | Point-in-time, reporting period, rolling window, cumulative total, or annualised rate? |
| Comparison | Which baseline and equivalent period or population? |
| Interpretation | Does a change have a known favourable direction, or is it neutral? |
| Provenance and freshness | Where did it come from, and which timestamp describes its currency? |
| Quality | Complete, partial, provisional, estimated, stale, or unavailable? |
| Inspection | Where can the reader see exact values, definitions, or evidence? |

State shared currency, reporting window, or scope once when it clearly applies
to all the affected metrics. Repeat it when a local exception would otherwise
be misleading. The contract is a reasoning aid, not a demand to print nine labels.

### Example: an interpretable financial metric

Weak presentation:

```text
Revenue
$2.4M     ↑ 12%
```

Better, with actual fields supplied by the product:

```text
Exchange fees · USD · last 30 days
$2.4M
+12% versus the preceding 30 days
8 of 9 sources reporting · one source delayed
View breakdown
```

The improvement is definition and comparison, not extra decoration. When coverage
is partial, do not imply the value or change is fully comparable unless it is.
If the baseline uses a different reporting cohort, disclose or withhold the
comparison until it is valid. Display the approved value rather than calculating
an unsupported replacement during a styling task.

### Example: an environmental result

```text
Vegetation index · selected study area
0.43 median
0.06 below the same-month baseline
78% valid observation coverage · cloud-affected areas excluded
Inspect trend and coverage
```

The coverage note is part of the result, not secondary decoration. Do not label
this "unhealthy" unless the product has a justified interpretation rule. A model
likelihood, a measured index, and a confirmed condition need different wording.

## Numeric discipline

Use consistent decimal precision within a comparable field, with exceptions
where material small values need it. Align numeric columns on a shared edge or
decimal position. Put units in headers or beside values consistently.

| Situation | Treatment |
| --- | --- |
| Large overview value | Compact notation can aid scanning; retain exact inspection |
| Decision depends on small differences | Show enough precision in the comparison view |
| Small non-zero value rounds to zero | Show more digits or a truthful threshold such as `<0.01` |
| Negative value | Preserve the sign; never use colour alone |
| Zero | Display zero only when it is a known result |
| Missing, unobserved, or not applicable | Distinct wording or symbols with clear meanings |
| Currency ambiguity | Specify USD, AUD, or the relevant denomination, not an unexplained `$` |
| Rates and yields | Preserve period, method, and whether the value is annualised or estimated |
| Localisation | Follow the product's locale for separators, dates, units, and reading direction |

A rate increasing from 20% to 25% rises **5 percentage points** or **25% relative
to its previous value**. Pick the intended comparison and label it. If the prior
value is zero, do not display an ordinary percentage-growth result. A financial
rate should not silently change from APR to APY, or from gross to net, to fit a
shorter label.

Use relative time for scanning only when exact time remains available with a
clear timezone. Separate observation date, processing date, last successful
refresh, and the user's latest refresh attempt when they differ materially.

## Tables and repeated entities

Use aligned records when users compare the same fields across entities. Keep
identity on a stable anchor, comparable metrics in predictable columns, and
secondary metadata in a concise subordinate line.

A useful row anatomy is:

```text
Identity                         Comparison fields                 Action
Name or label                    Metric A    Metric B    Status    Inspect
Type · location · other context
```

Preserve sort meaning and state. Sort by underlying values, not formatted strings.
Show the active filters, relevant scope, and result count. Place controls beside
the dataset they affect. Group units in headers where unambiguous. Keep hover,
selection, keyboard focus, and disabled states distinguishable.

Do not turn an entire row into a competing interactive target when it contains
separate controls. Make the navigation link or action clear, preserve keyboard
access, and use the host platform's established table/list behaviour. For web
implementations, retain meaningful header-to-cell relationships; see the
[W3C tables tutorial](https://www.w3.org/WAI/tutorials/tables/).

At narrow widths, choose according to the task. Individual lookup may work as a
prioritised record. Cross-entity comparison may need a bounded scrolling table
with the important identity context retained. Do not silently drop the columns
that distinguish one record from another.

## Choose the visual encoding for the question

| Reader's task | Starting pattern | Important constraint |
| --- | --- | --- |
| Read an exact value | Metric or table | Definition, unit, scope, and time remain clear |
| Compare category magnitudes | Aligned bars or table | Common scale and an honest baseline |
| Understand change over time | Time-series line or bars | Time spacing, gaps, and period definitions remain explicit |
| See distribution or outliers | Histogram, box plot, or points | Explain bins, population, and statistical meaning as needed |
| Understand composition | Stacked bars or a simple share view | Visible denominator and coverage; categories must add meaningfully |
| Locate a spatial relationship | Map plus legend and supporting values | Location must be relevant; show coverage and scale/context |
| Find operational problems | Prioritised exception list | Explicit status, recency, consequence, and next action |

Treat this as a starting guide, not an exhaustive chart taxonomy. Use the simplest
encoding that preserves the required relationships. A chart is not compulsory.

### Chart truth before visual polish

Bars encoding magnitude should ordinarily use a zero baseline. A narrower range
on a line chart can reveal meaningful variation, but it must be clearly labelled
and must not be chosen to exaggerate a movement. Do not conceal transformations,
log scales, missing periods, changing denominators, or a revised method.

Keep comparable small multiples on consistent scales unless there is a clear,
visible reason not to. Avoid smoothing that invents structure. Do not connect
across missing observations as though the intervening values were measured.
Use a clearly different treatment for projections, confidence intervals, or
estimates, with an explanation of what they represent.

For time comparisons, match duration, granularity, coverage, and definitions.
Do not compare a partial month with a full month as equivalent performance.
Do not aggregate percentages or rates without the approved weighting and method.
Label a truncated top-N view and make the rest of the population accessible.

### Chart polish after truth

Remove grid lines that do not help reading. Keep enough axis and unit information
to interpret the marks. Use one emphasis colour for one focal series; preserve
several distinct series when they matter. Prefer direct labels when they reduce
lookup effort, but use a well-positioned legend when direct labels would collide.

Put key interpretation next to the chart rather than only in tooltips. Let the
reader inspect relevant values without a mouse-only interaction. Supply a
meaningful text summary and a suitable data or detailed-text alternative for
complex visuals; the [W3C complex-images guidance](https://www.w3.org/WAI/tutorials/images/complex/)
provides web accessibility examples. A data table alone need not communicate an
important visual relationship, so state the key relationship as well.

## Maps and analytical images

Let the evidence remain visible; avoid covering it with a grid of decorative
metric panels. Keep the selected area, period, layer, and legend understandable.
Use a detail panel for local inspection where it preserves spatial context.

Distinguish no data from low values and from areas outside coverage. Keep selected
boundaries and thematic colour meanings distinct. Expose method and uncertainty
near results when they change interpretation. Do not turn a continuous score
into a binary finding just because a red/green map looks simpler.

A map is warranted when location answers the user's question. Use a ranked table
or chart when the comparison does not benefit from geography.

## Freshness, partial results, and asynchronous states

Design these states as first-class content, not leftover error messages.

| State | Visible treatment |
| --- | --- |
| Initial loading | Preserve useful layout; identify what is loading; no fabricated zero values |
| Background refresh | Keep last valid data when appropriate and label it as such |
| Stale data | Show age or last successful update; do not imply the refresh succeeded |
| Partial data | Identify affected scope or coverage; qualify totals and comparisons |
| No results after filtering | Explain the scope and offer a clear reset or adjustment |
| No data exists | Explain what is absent and an appropriate next step |
| Failure | State what failed, whether displayed data is still valid, and a recovery action |
| Pending action | Distinguish submitted, processing, succeeded, and failed outcomes |

A new filter must not silently relabel cached data from the old scope. Keep the
last result's scope explicit while the new one loads, or replace it with a clear
loading state. Update related metrics and comparisons coherently.

Do not reorder a live list while the user is selecting or reading a row without
an intentional policy. Preserve focus, selection, filter state, and useful scroll
position. Show update availability rather than sacrificing a stable task to
constant visual freshness.

## Action and consequence

When data leads to an action, preserve the relationship between selected object,
entered values, expected effect, relevant costs or risks, and actual outcome.
Consequential information belongs before the committing action. Do not use
visual polish to downplay it.

Never make a financial interface more attractive by hiding loss, fees, liquidity
constraints, or uncertainty. Never make an operational interface calmer by
removing unresolved failures. Make those facts proportionate, readable, and
useful rather than decorative or alarmist.
