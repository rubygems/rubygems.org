# frozen_string_literal: true

class CreateIndexGoodJobsOnQueueDequeueOrdered < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_queue_dequeue_ordered)
      end
    end

    add_index :good_jobs, %i[queue_name priority created_at],
      order: { priority: "ASC NULLS LAST", created_at: :asc },
      where: "finished_at IS NULL", name: :index_good_jobs_on_queue_dequeue_ordered,
      algorithm: :concurrently
  end
end
