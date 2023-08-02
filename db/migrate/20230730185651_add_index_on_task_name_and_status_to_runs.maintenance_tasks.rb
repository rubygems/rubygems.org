# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20220713131925)
class AddIndexOnTaskNameAndStatusToRuns < ActiveRecord::Migration[6.0]
  def change
    remove_index(
      :maintenance_tasks_runs,
      column: [:task_name, :created_at],
      order: { created_at: :desc },
      name: :index_maintenance_tasks_runs_on_task_name_and_created_at,
    )

    add_index(
      :maintenance_tasks_runs,
      [:task_name, :status, :created_at],
      name: :index_maintenance_tasks_runs,
      order: { created_at: :desc },
    )
  end
end
