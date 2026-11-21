# frozen_string_literal: true

# Deletes processed log tickets created before the start of the previous month
# (UTC), so log_tickets stops growing without bound.
#
# A ticket only matters shortly after its log file arrives: the unique
# (directory, key) index makes SqsWorker skip duplicate SQS deliveries, and
# LogTicket.pop only takes pending tickets. SQS keeps messages for at most 14
# days, so keeping the whole previous month leaves a wide margin, even when the
# job runs on the 1st. Pending, processing and failed tickets are kept.
#
# log_tickets has no index on created_at. The job finds the newest ticket id
# before the cutoff once, then deletes in primary-key batches up to that id.
class DeleteProcessedLogTicketsJob < ApplicationJob
  queue_as "stats"

  include GoodJob::ActiveJobExtensions::Concurrency

  good_job_control_concurrency_with(
    enqueue_limit: 1,
    perform_limit: 1,
    key: name
  )

  BATCH_SIZE = 1_000

  def perform
    cutoff = Time.current.utc.beginning_of_month.prev_month
    expired = LogTicket.where(created_at: ...cutoff)

    # Ids follow created_at, so this walks the primary key index backwards and
    # only reads the tickets created since the cutoff.
    last_id = expired.order(id: :desc).pick(:id)
    return if last_id.nil?

    deleted = expired.processed.in_batches(of: BATCH_SIZE, finish: last_id).delete_all
    logger.info "Deleted #{deleted} processed log tickets created before #{cutoff.iso8601}"
  end
end
