# Rebuilding Rubygem search from Avo

In **Admin → Rubygems → Actions → Rebuild Rubygem Search**, a `rubygems-org`
administrator can queue a full Searchkick rebuild. No gem selection is needed;
filters and selected rows do not restrict it. A detailed audit comment and an
explicit maintenance-window acknowledgement are required.

## Arrange a controlled maintenance window first

This is **not a safe live rebuild**. The acknowledgement records an operator's
confirmation; the action does not pause traffic, jobs, or database writes.

Searchkick 6.1.2's [full reindex implementation](https://github.com/ankane/searchkick/blob/v6.1.2/lib/searchkick/index.rb)
creates a timestamped index with the current mappings/settings, imports database
records in batches, promotes the alias, removes old unaliased indexes, and
refreshes. With an existing alias, searches continue against the old index until
promotion. Without an existing alias, the initial index can be visible while it
is being populated. This is a rebuild, not an OpenSearch refresh or a series of
publication callbacks.

Alias promotion does not replay concurrent mutations. For example, after a gem
has been imported, a yank or deletion can update the old index and leave the new
one stale. `RubygemSearchable` disables automatic callbacks; writes include
`ReindexRubygemJob`, publication jobs, and direct download updates in
`GemDownload`. A rebuild lock does not coordinate any of those writers.

1. Confirm the target environment and available OpenSearch disk/cluster capacity
   for both old and new indexes. Expect a full database scan and bulk indexing.
2. Quiesce search-data mutations (including pushes, yanks, deletions, metadata
   changes, and download-counter processing). Drain in-flight writes and relevant
   jobs before stopping their workers. Keep their inputs durable for later
   processing. Merely stopping `ReindexRubygemJob` is insufficient: database
   mutations during the scan also produce inconsistent results.
3. Ensure the `maintenance` worker is running the desired application revision
   and mappings. Keep Avo and that worker available while other writers are
   paused. Do not overlap this with a console/rake rebuild or a rolling deploy.
4. Open the action, confirm writers are paused, explain the maintenance window in
   the comment, and select **Queue full rebuild**. Keep writers paused while the
   job is queued, executing, and being verified. A queue acknowledgement is not
   completion.
5. Follow the job ID from the success message in `/admin/good_job`. The action
   records the administrator, comment, confirmation, and enqueue changes in the
   Avo audit log. GoodJob retains execution/error records; application logs mark
   rebuild start and completion with the job ID. There is no batch progress UI.
6. Before resuming, verify the alias has exactly one target, required mappings
   exist, document count matches the quiesced Rubygem population (including
   yanked and unversioned gems), and representative searches and documents are
   correct. Deploy compatible readers/writers before resuming. For a new search
   field, old writers must not resume with a `search_data` implementation that
   omits it.

If a controlled window cannot be arranged, do not use this action. An online
rebuild needs a separate, verified mutation capture/replay or dual-write design.

## Overlap and failure handling

The job uses the existing `maintenance` queue and GoodJob `total_limit: 1`, which
rejects enqueueing while another rebuild is queued or running and prevents
overlapping execution. Avo also serializes its enqueue check and insert with a
PostgreSQL transaction advisory lock. This does not lock unrelated rake/console
rebuilds or ordinary search writers. Do not bypass the action's coordination.

The job calls synchronous `Rubygem.reindex` inside the background worker, not
Searchkick's asynchronous import mode. Import errors propagate to GoodJob and
are not automatically retried. GoodJob may recover interrupted executions, so
keep the window in place until no rebuild is outstanding; if abandoning the
window, stop execution and discard pending work before resuming writers.

Failure does not guarantee the old alias is intact: cleanup or refresh can fail
after promotion. Inspect the alias, mappings, documents, error, and cluster health
before retrying manually in a controlled window. Searchkick normally deletes old
indexes, so retaining the old index for rollback is not part of this action.
The job does not run `VersionAfterWrite`, upload gem indexes, or send publication
notifications. It does not modify the Rubygem search schema itself.
