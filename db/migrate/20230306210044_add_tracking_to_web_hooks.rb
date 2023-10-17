class AddTrackingToWebHooks < ActiveRecord::Migration[7.0]
  def change
    add_column :web_hooks, :disabled_reason, :text, null: true  # rubocop:disable Rails/BulkChangeTable
    add_column :web_hooks, :disabled_at, :timestamp, null: true
    add_column :web_hooks, :last_success, :timestamp, null: true
    add_column :web_hooks, :last_failure, :timestamp, null: true
    add_column :web_hooks, :successes_since_last_failure, :integer, default: 0
    add_column :web_hooks, :failures_since_last_success, :integer, default: 0
  end
end
