# frozen_string_literal: true

# This migration comes from maintenance_tasks (originally 20230622035229)
class AddMetadataToRuns < ActiveRecord::Migration[6.0]
  def change
    add_column(:maintenance_tasks_runs, :metadata, :text)
  end
end
