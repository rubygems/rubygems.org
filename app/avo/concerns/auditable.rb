module Auditable
  extend ActiveSupport::Concern

  included do
    include SemanticLogger::Loggable

    def merge_changes!(changes, changes_to_save)
      changes.merge!(changes_to_save) do |_key, (old, _), (_, new)|
        [old, new]
      end
    end

    def in_audited_transaction(auditable:, admin_github_user:, action:, fields:, arguments:, models:, &) # rubocop:disable Metrics
      logger.debug { "Auditing changes to #{auditable}: #{fields}" }

      User.transaction do
        changed_records = {}
        value = ActiveSupport::Notifications.subscribed(proc do |_name, _started, _finished, _unique_id, data|
          records = data[:connection].transaction_manager.current_transaction.records || []
          records.uniq(&:__id__).each do |record|
            merge_changes!((changed_records[record] ||= {}), record.attributes.transform_values { [nil, _1] }) if record.new_record?
            merge_changes!((changed_records[record] ||= {}), record.changes_to_save)
          end
        end, "sql.active_record", &)
        auditable = value if auditable == :return

        audited_changed_records = changed_records.to_h do |record, changes|
          key = record.to_global_id.uri
          changes = merge_changes!(changes, record.attributes.slice("id").transform_values { [_1, _1] }) if changes.key?("id")
          changes = merge_changes!(changes, record.attributes.compact.transform_values { [_1, nil] }) if record.destroyed?

          [key, { changes:, unchanged: record.attributes.except(*changes.keys) }]
        end

        audit = Audit.create!(
          admin_github_user:,
          auditable:,
          action:,
          comment: fields.fetch(:comment),
          audited_changes: {
            records: audited_changed_records,
            fields: fields.except(:comment),
            arguments: arguments,
            models: models&.map { _1.to_global_id.uri }
          }
        )

        [value, audit]
      end
    end
  end
end
