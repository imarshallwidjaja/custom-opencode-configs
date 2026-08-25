# Humanizer pattern checklist (with examples)

Scan for these patterns, then rewrite the flagged text to be specific, direct, and human.

## 1) Undue emphasis on significance, legacy, and broader trends

**Words to watch:** stands/serves as, is a testament/reminder, a vital/significant/crucial/pivotal/key role/moment, underscores/highlights its importance/significance, reflects broader, symbolizing its ongoing/enduring/lasting, contributing to the, setting the stage for, marking/shaping the, represents/marks a shift, key turning point, evolving landscape, focal point, indelible mark, deeply rooted

**Problem:** Puffing up arbitrary facts into sweeping "this matters" claims.

**Before:**
> The Statistical Institute of Catalonia was officially established in 1989, marking a pivotal moment in the evolution of regional statistics in Spain.

**After:**
> The Statistical Institute of Catalonia was established in 1989 to collect and publish regional statistics independently from Spain's national statistics office.

## 2) Undue emphasis on notability and media coverage

**Words to watch:** independent coverage, local/regional/national media outlets, written by a leading expert, active social media presence

**Problem:** Listing sources as a stand-in for substance.

**Before:**
> Her views have been cited in The New York Times, BBC, Financial Times, and The Hindu. She maintains an active social media presence with over 500,000 followers.

**After:**
> In a 2024 New York Times interview, she argued that AI regulation should focus on outcomes rather than methods.

## 3) Superficial analyses with -ing endings

**Words to watch:** highlighting/underscoring/emphasizing..., ensuring..., reflecting/symbolizing..., contributing to..., cultivating/fostering..., encompassing..., showcasing...

**Problem:** Add-on "-ing" clauses that pretend to add depth.

**Before:**
> The temple's color palette ... symbolizing ... reflecting the community's deep connection to the land.

**After:**
> The temple uses blue, green, and gold colors. The architect said these were chosen to reference local bluebonnets and the Gulf coast.

## 4) Promotional / advertisement-like language

**Words to watch:** boasts a, vibrant, rich (figurative), profound, enhancing its, showcasing, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking (figurative), renowned, breathtaking, must-visit, stunning

**Problem:** "Tourism brochure" tone.

**Before:**
> Nestled within the breathtaking region of Gonder ... vibrant town with a rich cultural heritage and stunning natural beauty.

**After:**
> Alamata Raya Kobo is a town in the Gonder region of Ethiopia, known for its weekly market and 18th-century church.

## 5) Vague attributions and weasel words

**Words to watch:** Industry reports, Observers have cited, Experts argue, Some critics argue, several sources/publications

**Problem:** Opinions attributed to nobody in particular.

**Before:**
> Experts believe it plays a crucial role in the regional ecosystem.

**After:**
> The Haolai River supports several endemic fish species, according to a 2019 survey by the Chinese Academy of Sciences.

## 6) Outline-like "challenges and future prospects" sections

**Words to watch:** Despite its... faces several challenges..., Despite these challenges, Challenges and Legacy, Future Outlook

**Problem:** Template-y paragraphs that say nothing concrete.

**Before:**
> Despite these challenges... continues to thrive as an integral part of ...

**After:**
> Traffic congestion increased after 2015 when three new IT parks opened. The municipal corporation began a stormwater drainage project in 2022 to address recurring floods.

## 7) Overused "AI vocabulary" words

**High-frequency AI words:** Additionally, align with, crucial, delve, emphasizing, enduring, enhance, fostering, garner, highlight (verb), highlighting, interplay, intricate/intricacies, key (adjective), landscape (abstract noun), meticulous, pivotal, robust (figurative), showcase, showcasing, tapestry (abstract noun), testament, underscore (verb), valuable, vibrant

**Later-model extras:** GPT-5-era text still clusters emphasizing / enhance / highlighting / showcasing. Grok-heavy text overuses superficially scientific words (causal, empirical, correlate) and still leans on underscore. Keep those words when they are the accurate technical term.

**Problem:** These words cluster together and instantly date the writing as post-2023 LLM-ish.

**Before:**
> Additionally, ... an enduring testament ... culinary landscape, showcasing ...

**After:**
> Somali cuisine also includes camel meat, which is considered a delicacy. Pasta dishes, introduced during Italian colonization, remain common, especially in the south.

## 8) Avoidance of "is"/"are" (copula avoidance)

**Words to watch:** serves as/stands as/marks/represents/functions as/operates as [a], boasts/features/offers [a], refers to (when the sentence is about the thing, not the term)

**Problem:** Swapping simple statements for performative ones.

**Before:**
> Gallery 825 serves as ... The gallery features ... and boasts ...

**After:**
> Gallery 825 is LAAA's exhibition space for contemporary art. The gallery has four rooms totaling 3,000 square feet.

## 9) Negative parallelisms

**Problem:** Contrast used as the default explanation. Two-part and three-part forms are the same tell. Cadence cleanup lives in `stop-slop`; flag these here when they appear in encyclopedic or promotional prose.

**Forms:**
- "Not only X, but Y" / "It's not just about X, it's Y"
- "It's not X, it's Y"
- "It's not X, and it's not Y, but it is Z"
- "No X, no Y, just Z"
- "X rather than Y" as a rhetorical punch (common in Grok output)

**Before:**
> It's not just about the beat ... it's part of the aggression ... It's not merely a song, it's a statement. It's not a protest, and it's not a joke, but it is a warning.

**After:**
> The heavy beat adds to the aggressive tone.

If the reader was already choosing among those names, keep the denials as facts, not as a reveal.

## 10) Rule-of-three overuse

**Problem:** Forced triplets to sound "complete".

**Before:**
> keynote sessions, panel discussions, and networking opportunities

**After:**
> The event includes talks and panels. There's also time for informal networking between sessions.

## 11) Elegant variation (synonym cycling)

**Problem:** Replacing repetition with awkward synonym churn.

**Before:**
> protagonist / main character / central figure / hero ...

**After:**
> The protagonist faces many challenges but eventually triumphs and returns home.

## 12) False ranges

**Problem:** "from X to Y" where X/Y aren't a meaningful scale.

**Before:**
> from the singularity ... to the grand cosmic web ... from the birth and death of stars ...

**After:**
> The book covers the Big Bang, star formation, and current theories about dark matter.

## 13) Em-dash overuse

**Problem:** Em dashes used as a default "punch" tool.

**Fix:** Prefer periods/commas; keep em dashes for rare, deliberate asides.

## 14) Overuse of boldface

**Problem:** Mechanical emphasis.

**Fix:** Use bold sparingly; don't bold every acronym and noun phrase.

## 15) Inline-header vertical lists

**Problem:** Bullets like `- **Thing:** sentence` read like auto-generated changelogs.

**Fix:** Convert to sentences; vary structure.

## 16) Title case in headings

**Problem:** "Strategic Negotiations And Global Partnerships"

**Fix:** Use sentence case: "Strategic negotiations and global partnerships".

## 17) Emojis

**Problem:** Decorative emoji headings/bullets.

**Fix:** Remove unless the audience explicitly expects them.

## 18) Curly quotation marks

**Problem:** “curly quotes” instead of straight quotes ("...").

**Fix:** Convert to straight quotes for plain-text / code-adjacent writing.

## 19) Collaborative communication artifacts

**Words to watch:** I hope this helps, Of course!, Certainly!, You're absolutely right!, Would you like..., let me know, here is a...

**Problem:** Chatbot correspondence pasted into content.

**Fix:** Remove and jump straight into the actual material.

## 20) Knowledge-cutoff disclaimers and source-gap speculation

**Words to watch:** as of [date], Up to my last training update, based on available information, not widely documented/available, While specific details are limited, the [subject] likely...

**Problem:** Model meta leaking into the text, or inventing absence and then filling it with guesses ("maintains a low profile", "likely supports a diverse ecosystem").

**Fix:** Replace with facts + source, or remove. Do not speculate into a gap you just declared.

## 21) Sycophantic / servile tone

**Problem:** Over-praise and people-pleasing.

**Fix:** Be direct; agree/disagree with substance, not vibes.

## 22) Filler phrases

**Before → After:**
- "In order to achieve this goal" → "To achieve this"
- "Due to the fact that" → "Because"
- "At this point in time" → "Now"
- "In the event that" → "If"

## 23) Excessive hedging

**Problem:** "could potentially possibly..."

**Fix:** Remove stacked modals; keep a single, honest qualifier when needed.

## 24) Generic positive conclusions

**Problem:** "The future looks bright... exciting times..."

**Fix:** End with a concrete next step, metric, or specific claim.

## 25) Vague expression of connection or association

**Words to watch:** associated with, in association with, in connection with/to, connected with/to, particularly/widely associated

**Problem:** Naming a relationship without saying what the relationship is (worked on, caused, cited, used in).

**Before:**
> The system has been associated with residential water management. The inventor is referenced in connection with award recognition.

**After:**
> The method is used for swimming-pool backwash and sump-pump discharge. The New Jersey DEP named the inventor in a 2019 environmental-excellence award list.

## 26) Phrasal templates and placeholder residue

**Words to watch:** [Your Name], [Specific Topic], INSERT_SOURCE_URL, 2025-XX-XX, _(Add your URL here)_, TODO: fill in

**Problem:** Mad Libs slots left in the output, including fake citation dates.

**Fix:** Fill from evidence or delete the slot. Do not ship brackets, underscores-as-blanks, or XX dates.

## 27) LLM citation markup leaks

**Words to watch:** contentReference, oaicite, turn0search0, grok_card, grok_render_citation_card_json, [cite: 1], [span_1], attached_file, ppl-ai-file-upload, :::writing

**Problem:** Chat UI citation chips pasted into the document.

**Fix:** Replace with a real citation or drop the claim. Do not leave the markup.

## 28) Markdown section chrome

**Problem:** `---` / `***` thematic breaks between every section; skipped heading levels; a dump of H1s; a heading whose only children are more headings.

**Fix:** Ordinary heading hierarchy. No horizontal rules as section glue. Put a sentence under a heading or remove the heading.

## 29) Tiny comparison tables used as layout

**Problem:** A two- or three-row "Feature / Value" table that would be clearer as two sentences.

**Fix:** Write the comparison as prose unless the reader must scan many aligned fields.

## 30) Section restatements

**Words to watch:** In this section we will, In summary, In conclusion, Overall, To conclude

**Problem:** The paragraph repeats itself as a closer.

**Fix:** End on the last new fact. Do not recap the heading.
