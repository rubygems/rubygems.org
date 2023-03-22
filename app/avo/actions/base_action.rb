class BaseAction < Avo::BaseAction
  field :comment, as: :textarea, required: true,
    help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."

  def self.inherited(base)
    super
    base.items_holder = Avo::ItemsHolder.new
    base.items_holder.items.replace items_holder.items.deep_dup
    base.items_holder.invalid_fields.replace items_holder.invalid_fields.deep_dup
  end

  class ActionHandler
    include ActiveSupport::Callbacks
    define_callbacks :handle, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }

    def initialize( # rubocop:disable Metrics/ParameterLists
      fields:,
      current_user:,
      arguments:,
      resource:,
      action:,
      models: nil
    )
      @models = models
      @fields = fields
      @current_user = current_user
      @arguments = arguments
      @resource = resource

      @action = action
    end

    attr_reader :models, :fields, :current_user, :arguments, :resource

    delegate :error, :avo, :keep_modal_open, :redirect_to, :inform,
      to: :@action

    set_callback :handle, :before do
      error "Must supply a sufficiently detailed comment" unless fields[:comment].presence&.then { _1.length >= 10 }
    end

    set_callback :handle, :around, lambda { |_, block|
      begin
        block.call
      rescue StandardError => e
        Rails.error.report(e, handled: true)
        error e.message.truncate(300)
      end
    }

    def do_handle
      run_callbacks :handle do
        handle
      end
      keep_modal_open if errored?
    end

    def errored?
      @action.response[:messages].any? { _1[:type] == :error }
    end

    def merge_changes!(changes, changes_to_save)
      changes.merge!(changes_to_save) do |_key, (old, _), (_, new)|
        [old, new]
      end
    end

    def in_audited_transaction(&)
      User.transaction do
        changed_records = {}
        ActiveSupport::Notifications.subscribed(proc do |_name, _started, _finished, _unique_id, data|
          records = data[:connection].transaction_manager.current_transaction.records || []
          records.uniq(&:__id__).each do |record|
            merge_changes!((changed_records[record] ||= {}), record.changes_to_save)
          end
        end, "sql.active_record", &)

        audited_changed_records = changed_records.to_h do |record, changes|
          key = record.to_global_id.uri
          changes = merge_changes!(changes, record.attributes.compact.transform_values { [_1, nil] }) if record.destroyed?

          [key, { changes:, unchanged: record.attributes.except(*changes.keys) }]
        end

        audit = Audit.create!(
          admin_github_user: current_user,
          auditable: @current_model,
          action: @action.action_name,
          comment: fields[:comment],
          audited_changes: {
            records: audited_changed_records,
            fields: fields.except(:comment),
            arguments: arguments,
            models: models.map { _1.to_global_id.uri }
          }
        )
        redirect_to avo.resources_audit_path(audit)
      end
    end

    def handle
      models.each do |model|
        @current_model = model
        in_audited_transaction do
          handle_model(model)
        end
      end
      @current_model = nil
    end
  end

  def handle(**args)
    "#{self.class}::ActionHandler"
      .constantize
      .new(**args, arguments:, action: self)
      .do_handle
  end
end
