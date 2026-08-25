# Further examples

Constructed. Use these when the SKILL.md examples are not enough to judge the voice.

## Too-short STE is also the wrong fix

Do not compress the architecture example in SKILL.md into:

> Add Redis. Redis stores catalogue data. Postgres stores catalogue data. Redis is in front of Postgres. Reads are faster.

The intended version keeps the technical terms, the runtime relationship, the trade-off, and a semicolon that earns its keep. It does not rotate synonyms, and it does not flatten the explanation into one-clause sentences.

## Preserve uncertainty

**Before:**
> The outage was caused by a bad deploy. We must rewrite the pipeline.

**After:**
> The outage started within two minutes of deploy `2026-08-19.14`. The deploy is the strongest current lead; we have not yet ruled out a coincident cache stampede. Until that is checked, treat a pipeline rewrite as a candidate, not as the fix.

Do not promote a hypothesis into a cause in order to make the paragraph cleaner.

## Observation is not a requirement

**Before:**
> The app MUST feel fast and intuitive. Users hate waiting. Therefore we SHALL add a new homepage.

**After:**
> Checkout p95 is 2.8 s on mid-range Android, and session recordings show people abandoning after the spinner. The desired outcome is that checkout completes without a spinner long enough to look stuck. A requirement, if we write one, is that p95 checkout on the target Android set stays under 1.5 s. A new homepage is one possible response; it is not the requirement.

## Review finding

**Before:**
> Great work overall! One small nit: the error handling could be more robust. Food for thought.

**After:**
> `billing/capture.ts:88` swallows `CardDeclined` and returns HTTP 200. A declined card then looks paid to the client, and the webhook path never retries. Return the processor decline to the caller, and add a test for that branch.

## Rejected alternatives belong in the ADR, not the status note

The reader asked what changed in production. They did not ask which stores were considered.

**Before:**
> I considered Redis, Memcached, and an in-process hashmap. I didn't use Memcached because we have no ops experience with it, and I avoided a full rewrite of the catalogue service. We added Redis in front of Postgres. This does not affect writes.

**After:**
> Catalogue reads now go through Redis. Writes still go to Postgres first; Redis is invalidated on publish.

The live constraint (writes, invalidation) stays. The discarded menu, the "I didn't use", and the "this does not affect" narration go.

If the artifact is an ADR, keep the discarded options and the reason they lost.

## Durable names, not planning slots

The work was sequenced as Phase 1 in a planning chat. The durable artifact is a coverage processor.

**Before:**
> Add `phase-1-processor.ts` and `docs/workstream-2-ingest.md`. Option B lives in `option-b-cache/`. Ticket ABC-1847 is the module name.

**After:**
> Add `coverage-processing.ts` and `docs/scene-ingestion.md`. The write-through cache lives in `write-through-cache/`. Mention ABC-1847 in the commit subject if that is the tracker contract; do not name the module after the ticket.

A later reader can open the file without the planning thread. The ticket remains a pointer, not the identity of the code.

## Re-pitch with context

**Before:**
> We moved auth to the edge.

**After:**
> Browser calls used to hit `api.example.com`, which verified the session cookie in the origin app. Those calls now go to the CDN worker first. The worker checks the session JWT and only forwards requests that pass, so unauthenticated traffic no longer reaches the origin. Login itself still happens in the origin app; the worker does not issue sessions.
