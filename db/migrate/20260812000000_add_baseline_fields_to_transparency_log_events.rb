# frozen_string_literal: true

class AddBaselineFieldsToTransparencyLogEvents < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Keep these separate so Strong Migrations can inspect each operation.
    # rubocop:disable Rails/BulkChangeTable
    add_column :transparency_log_events, :baseline_id, :uuid
    add_column :transparency_log_events, :observed_at, :datetime
    add_column :transparency_log_events, :payload_attributes, :jsonb, null: false, default: {}
    # rubocop:enable Rails/BulkChangeTable

    add_index :transparency_log_events, %i[baseline_id event_type],
      algorithm: :concurrently,
      where: "baseline_id IS NOT NULL"
  end
end
