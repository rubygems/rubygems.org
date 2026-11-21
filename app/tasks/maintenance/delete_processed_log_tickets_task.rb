# frozen_string_literal: true

# Nothing has ever pruned log_tickets. A ticket only matters shortly after its
# log file arrives: the unique (directory, key) index drops duplicate SQS
# deliveries and LogTicket.pop only takes pending tickets. Delete processed
# tickets created before CUTOFF and keep pending, processing and failed ones.
#
# log_tickets has no index on created_at or status, so the task never filters
# the whole table by them. It finds the last id created before CUTOFF with one
# backward walk of the primary key, then deletes in primary key ranges up to
# that id. Each batch reads at most batch_size rows.
#
# Unthrottled, the deletes generate WAL and dead tuples as fast as the primary
# can write them. batch_pause_ms spaces batches out; raise it, or pause the
# run, if replication lag, WAL volume or autovacuum fall behind.
class Maintenance::DeleteProcessedLogTicketsTask < MaintenanceTasks::Task
  CUTOFF = Time.utc(2026, 9, 1)

  attribute :batch_size, :integer, default: 1000
  attribute :batch_pause_ms, :integer, default: 100
  validates :batch_size, numericality: { only_integer: true, greater_than: 0 }
  validates :batch_pause_ms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def collection
    return LogTicket.none.in_batches(of: batch_size) unless last_id_before_cutoff

    LogTicket.where(id: ..last_id_before_cutoff).in_batches(of: batch_size)
  end

  # The default count runs COUNT(*) over the collection, a full scan of
  # log_tickets. Estimate the number of batches from the id span instead.
  def count
    return 0 unless last_id_before_cutoff

    ((last_id_before_cutoff - LogTicket.minimum(:id)) / batch_size) + 1
  end

  def process(batch)
    batch.processed.where(created_at: ...CUTOFF).delete_all
    sleep(batch_pause_ms / 1000.0)
  end

  private

  # ids follow created_at order, so this walks the primary key backwards from
  # the newest ticket and stops at the first one created before CUTOFF.
  def last_id_before_cutoff
    return @last_id_before_cutoff if defined?(@last_id_before_cutoff)

    @last_id_before_cutoff = LogTicket.where(created_at: ...CUTOFF).order(id: :desc).pick(:id)
  end
end
