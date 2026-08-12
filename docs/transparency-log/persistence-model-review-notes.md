# Transparency log persistence model review notes

Status: non-normative design exploration for review.

These notes preserve ideas raised while implementing the transparency log baseline maintenance tasks. They are not an ADR, do not amend or supersede the accepted transparency-log ADRs, and do not authorize schema or implementation changes. Until the ideas are reviewed and accepted through the ADR process, implementation must continue to follow the accepted specifications.

## Why this was raised

ADR-0004, **Define the ownership event payload, table, and Rekor shapes**, currently places immutable canonical event content and mutable signing, submission, retry, and error state in one append-only `transparency_log_events` table. ADR-0007, **Define the baseline snapshot event model**, requires baseline entries to share a `baseline_id` and `observed_at`, while deferring the exact canonical fields and consistent-cutoff mechanism until before implementation.

The baseline work made the distinction between evidence and processing state more visible because it adds snapshot identity and cutoff data to the same record.

The question for review is whether the persistence model should separate immutable evidence from mutable processing state more explicitly.

## Proposed separation

The following is a proposal, not accepted terminology or architecture.

### `transparency_log_baselines`

An immutable description of one baseline snapshot, potentially containing:

- the baseline identifier;
- the observation time and cutoff definition;
- the applicable specification version; and
- any completeness or sealing metadata required by the accepted cutover model.

### `transparency_log_events`

The immutable canonical event, potentially containing:

- the event UUID and event type;
- the canonical payload and its digest;
- the resource identity and occurrence time;
- the specification version;
- an optional baseline reference; and
- an optional reference to an event being corrected.

### `transparency_log_signatures`

An immutable record of a signature over an event, potentially containing:

- the event reference;
- the signature and signing-key identity;
- the signing algorithm; and
- the signing time.

### `transparency_log_inclusions`

An immutable record of a transparency-log submission and its accepted evidence, potentially containing:

- the event or signature reference;
- the log identity;
- the request and response material needed for verification;
- the log index and integrated time; and
- checkpoint or inclusion-proof material when available.

### `transparency_log_deliveries`

Mutable operational state for work that has not yet produced immutable inclusion evidence, potentially containing:

- queue or submission status;
- attempt count and retry timing;
- the latest error; and
- leasing or worker-coordination state.

One possible relationship between these records is:

```text
Baseline Snapshot -> Event -> Signature -> Log Inclusion
                         \
                          -> Delivery State
```

## Behaviors this proposal is intended to make explicit

- Retrying a Rekor submission changes delivery state without rewriting the event.
- Signing-key rotation appends a signature rather than replacing event content.
- Submission to an additional or replacement log appends inclusion evidence.
- Re-running a baseline uses the same immutable snapshot definition and deterministic event identities.
- Correcting published data creates a linked correction event rather than editing historical evidence.

These behaviors still need to be checked against the accepted event, signing, Rekor, and baseline specifications before they can become requirements.

## Possible database enforcement to evaluate

If the separation is accepted, the review should consider whether the database should enforce the boundary through measures such as:

- insert-only immutable tables without `updated_at`;
- database-level rejection of updates and deletes;
- restrictive foreign keys;
- uniqueness constraints for event identities, signatures, and inclusions; and
- a separate mutable projection for delivery health.

These are implementation options for evaluation, not decisions.

## ADR and glossary impact if accepted

Acceptance would require an ADR that explicitly changes or supersedes the persistence portion of the current ownership-event payload/table specification. The baseline ADR would also need to say whether a baseline snapshot is a first-class persisted record.

Terms such as **Event Signature**, **Log Inclusion**, and **Delivery State** should only be added to the domain glossary if the team adopts them as distinct domain concepts.

## Questions that must be settled before implementation

- Does an event have one signature or may it accumulate multiple signatures?
- Can the same event be included in multiple logs or more than once in one log?
- Is a mutable delivery projection sufficient, or must every delivery attempt also be retained immutably?
- What exact data proves that a baseline is complete and sealed?
- Which fields are canonical evidence, and which are derived projections or operational metadata?
- Which database mechanism should enforce immutability?
- How would existing `transparency_log_events` rows migrate without changing their meaning?
- Should the existing persistence ADR be amended or superseded?

## Explicit exclusions

This note does not:

- define a production schema;
- change any accepted ADR;
- authorize migrations or model changes;
- resolve the outstanding baseline cutoff and completeness details; or
- introduce accepted domain terminology.
