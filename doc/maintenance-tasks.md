# Maintenance tasks

## Shape

Keep `collection` narrow, make each `process` call handle one record, and align `count` with the selected collection.

## Safety

The application may update a record before the task processes it. If that could affect the intended change, use an atomic conditional update that checks whether the change still applies, or reload the record under a database lock in a transaction and check before writing. Preserve newer writes, skip legitimately deleted records (including soft deletions), and make reruns harmless.

## Behavior and rollout

When new application behavior requires backfilled data, verify that the required data is present before enabling that behavior. Keep the running application working throughout the backfill, including while it is only partly complete.

## Testing

Test which records the task selects and what it changes, including failures, reruns, intervening application writes, and records deleted after collection. Check what was saved to the database and any other effects the task is responsible for.
