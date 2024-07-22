class AddTrackingToWebHooks < ActiveRecord::Migration[7.0]
  def change
    change_table(:web_hooks, bulk: true) do |t|
      t.text :disabled_reason, null: true
      t.timestamp :disabled_at, null: true
      t.timestamp :last_success, null: true
      t.timestamp :last_failure, null: true
      t.integer :successes_since_last_failure, default: 0
      t.integer :failures_since_last_success, default: 0
    end
  end
end
