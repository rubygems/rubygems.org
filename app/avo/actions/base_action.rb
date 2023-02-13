class BaseAction < Avo::BaseAction
  field :comment, as: :textarea, required: true,
    help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."

  class ActionHandler
    include ActiveSupport::Callbacks
    define_callbacks :handle, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }

    def initialize( # rubocop:disable Metrics/ParameterLists
      fields:, current_user:, arguments:, resource:, action:, models: nil
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

    def sole_model
      error "Expected a single model, but #{models.size} given" unless models.size == 1
      models.sole
    end

    def in_audited_transaction(&)
      User.transaction do
        changed_records = {}
        ActiveSupport::Notifications.subscribed(proc do |_name, _started, _finished, _unique_id, data|
          data[:connection].transaction_manager.current_transaction.records.uniq(&:__id__).each do |record|
            (changed_records[record] ||= {}).merge!(record.changes_to_save) do |_key, (old, _), (_, new)|
              [old, new]
            end
          end
        end, "sql.active_record", &)

        audited_changed_records = changed_records.to_h do |record, changes|
          [
            record.to_global_id.uri,
            { changes:, unchanged: record.attributes.except(*changes.keys) }
          ]
        end

        audit = Audit.create!(
          admin_github_user: current_user,
          auditable: @current_model,
          action: @action.name,
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
