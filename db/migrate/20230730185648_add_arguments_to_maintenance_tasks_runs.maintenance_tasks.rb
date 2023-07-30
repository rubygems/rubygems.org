# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20210517131953)
class AddArgumentsToMaintenanceTasksRuns < ActiveRecord::Migration[6.0]
  def change
    add_column(:maintenance_tasks_runs, :arguments, :text)
  end
end
