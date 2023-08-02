# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20211210152329)
class AddLockVersionToMaintenanceTasksRuns < ActiveRecord::Migration[6.0]
  def change
    add_column(
      :maintenance_tasks_runs,
      :lock_version,
      :integer,
      default: 0,
      null: false,
    )
  end
end
