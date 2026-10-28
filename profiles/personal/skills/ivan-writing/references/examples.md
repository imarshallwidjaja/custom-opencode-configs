# Writing Examples

These are constructed transformations, not corpus samples. Each after-text preserves the source claims needed for the stated audience; any omitted alternatives are noted.

## Technical / Product

**Before:**
> "The service receives webhook events and validates each payload against the order schema. It stores valid events and returns HTTP 400 for invalid payloads. The operations team owns the service."

**After (technical register):**
> "The service receives webhook events, validates each payload against the order schema, stores valid events, and returns HTTP 400 for invalid payloads. The operations team owns it."

**Preserved:** Webhook receipt, order-schema validation, storage of valid events, HTTP 400 for invalid payloads, and operations-team ownership.

## Professional / Application

**Before:**
> "I led a four-person team that built and operated an event-ingestion pipeline. At 50,000 requests per second, p99 latency rose to 2 seconds. I changed the partition strategy, and p99 latency fell to 200 ms."

**After (professional register):**
> "I led a four-person team that built and operated an event-ingestion pipeline. At 50,000 requests per second, p99 latency rose to 2 seconds. I changed the partition strategy, and p99 latency fell to 200 ms."

**Preserved:** Leadership of a four-person team, team ownership of building and operating the pipeline, the 50,000 requests-per-second load, the p99 change from 2 seconds to 200 ms, and personal ownership of the partition-strategy change.

## Casual / Informal

**Before:**
> "I think event sourcing improves auditability, but I am not convinced it is worth the extra operational complexity for this service."

**After (casual):**
> "I think event sourcing improves auditability. I'm not convinced it's worth the extra operational complexity for this service."

**Preserved:** The view that event sourcing improves auditability and the uncertainty about whether it is worth the extra operational complexity for this service.

## Reader-management and rejected alternatives

**Before:**
> "As you'll see, this is a comprehensive ingestion pipeline. I considered Kafka, Kinesis, and a homegrown HTTP fan-in. I didn't use Kinesis because we had no account for it. Rest assured the team owns operations."

**After (technical register):**
> "The team owns operations for the ingestion pipeline."

**Preserved:** The team owns operations for the ingestion pipeline. The praise, the discarded-menu narration, and the reassurance are dropped for a reader who is not choosing among those alternatives. If this were an ADR, keep the comparison and the reason Kinesis was rejected.

## Product comparison and claim strength

**Before:**
> "The system uses sensor data to calculate a screening result. The saved screening result and the result reported by the study are the two results to compare. The saved result passed the technical checks; these checks do not establish that the study's analysis has been reproduced."

**After (mixed audience):**
> "The system uses sensor data to calculate a screening result. Compare the saved screening result with the result reported by the study. The saved result passed the technical checks. Those checks do not establish that the study's analysis was reproduced."

**Preserved:** The system calculates the result from sensor data, the comparison names both results, and passing technical checks does not establish reproduction of the analysis.

## Saved object and downstream eligibility

**Source facts:** The validation service checked the saved report version `R7`; its schema and completeness checks passed. Publication eligibility requires both owner approval and an enabled catalog, but those conditions have not been checked. They are necessary conditions, not a guarantee of publication eligibility.

**Dense draft:**
> "R7 validates and is publication-ready with approval and catalog enabled."

**After:**
> "The validation service checked saved report version `R7`. Its schema and completeness checks passed. Publication eligibility requires owner approval and an enabled catalog; neither condition has been checked."

**Preserved:** The added words identify the service as the actor, the saved report version as the object, and the checks that passed. They separate those results from the unverified conditions required for publication eligibility, without treating those conditions as sufficient.

## Recorded outcome on rerun

**Before:**
> "On rerun, the service can retrieve the recorded acceptance outcome for the same saved result. The source does not say whether scientific calculations run again."

**After (technical register):**
> "On rerun, the service can retrieve the recorded acceptance outcome for the same saved result. Whether scientific calculations run again is not stated."

**Preserved:** Retrieval is possible for the same saved result; re-execution of the scientific calculations remains unknown.

## Architecture trade-off

**Before:**
> "The API accepts requests and the worker processes them. A queue holds requests until a worker is available. Operators must monitor the queue and maintain the worker. We expect the queue to absorb short bursts, but have not measured its capacity."

**After (architecture note):**
> "The API accepts requests, and a queue holds them until a worker is available to process them. Operators must monitor the queue and maintain the worker. We expect the queue to absorb short bursts, but we have not measured its capacity."

**Preserved:** Responsibilities, operating work, our expectation of burst handling, and that we have not measured the queue's capacity.
