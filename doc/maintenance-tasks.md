# Maintenance tasks

## Shape

Limit `collection` to records the task needs. Make `process` handle one record per call. Do not define `count` when it would only call `collection.count`; the framework already does that.

## Safety

The application may change a record after the task loads it. When that matters, make the database update conditional on the task's change still being needed, or lock and reload the record in a transaction and check before updating. Preserve newer application writes and make reruns safe.

Decide whether to include deleted and soft-deleted records. Use the same rule in `collection` and `process`. If excluding them, also skip records deleted after loading.

## Behavior and rollout

Keep the application working throughout the backfill, even when it is partly complete. Before enabling behavior that needs backfilled data, verify that all required data is present.

## Testing

Write the fewest tests needed to catch distinct, realistic mistakes. Combine overlapping cases when one test catches the same mistakes as separate tests.

Check which records `collection` returns and what `process` saves to the database. Test reruns, application changes, and deletion when relevant to the task.

To test an application write between loading and processing, load a record from `collection`, then update it through a separate model instance or direct database update. Pass the original object to `process` without changing or reloading it. Check that the database still holds the newer value.

Test failure behavior only when the task adds to or changes the framework default.
