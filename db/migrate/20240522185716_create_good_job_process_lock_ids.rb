# frozen_string_literal: true

class CreateGoodJobProcessLockIds < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.column_exists?(:good_jobs, :locked_by_id)
      end
    end

    change_table :good_jobs, bulk: true do |_t|
      t.add_column :locked_by_id, :uuid
      t.add_column :locked_at, :datetime
    end
    add_column :good_job_executions, :process_id, :uuid
    add_column :good_job_processes, :lock_type, :integer, limit: 2
  end
end
