# frozen_string_literal: true

# Adds the RFC-facing query and versioning fields to transparency log events.
class AddRfcFieldsToTransparencyLogEvents < ActiveRecord::Migration[8.1]
  EVENT_IDENTITY_COLUMNS = [
    [:resource_type, :string, limit: 50],
    [:resource_name, :string, limit: 255],
    [:resource_id, :string, limit: 128],
    [:subject_id, :string, limit: 128],
    [:subject_handle, :string, limit: 128],
    [:spec_version, :string, limit: 32],
    [:corrects_event_uuid, :uuid, {}]
  ].freeze

  REQUIRED_EVENT_IDENTITY_COLUMNS = %i[
    resource_type
    resource_name
    spec_version
  ].freeze

  QUERY_INDEXES = [
    %i[resource_type resource_name created_at],
    %i[actor_type actor_id created_at],
    %i[actor_type actor_handle created_at],
    %i[status created_at],
    :corrects_event_uuid
  ].freeze

  BACKFILL_EXISTING_EVENTS_SQL = <<~SQL.squish
    UPDATE transparency_log_events
    SET resource_type = COALESCE(resource_type, 'rubygem'),
        resource_name = COALESCE(resource_name, subject_name),
        spec_version = COALESCE(spec_version, canonical_payload->>'specVersion', '1.0')
  SQL

  disable_ddl_transaction!

  def change
    add_event_identity_columns
    backfill_required_event_identity_columns
    add_query_indexes
  end

  private

  def add_event_identity_columns
    EVENT_IDENTITY_COLUMNS.each do |column_name, column_type, options|
      add_column :transparency_log_events, column_name, column_type, **options
    end
  end

  def backfill_required_event_identity_columns
    safety_assured do
      backfill_existing_events
      enforce_required_event_identity_columns
    end
  end

  def add_query_indexes
    QUERY_INDEXES.each do |columns|
      add_index :transparency_log_events, columns, algorithm: :concurrently
    end
  end

  def backfill_existing_events
    reversible do |dir|
      dir.up { execute BACKFILL_EXISTING_EVENTS_SQL }
    end
  end

  def enforce_required_event_identity_columns
    REQUIRED_EVENT_IDENTITY_COLUMNS.each do |column_name|
      change_column_null :transparency_log_events, column_name, false
    end
  end
end
