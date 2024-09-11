class Avo::Actions::ApplicationAction < Avo::BaseAction
  include SemanticLogger::Loggable

  def fields
    field :comment, as: :textarea, required: true,
      help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."
  end

  class Avo::Actions::ActionHandler
    include Auditable
    include SemanticLogger::Loggable

    include ActiveSupport::Callbacks
    define_callbacks :handle, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }
    define_callbacks :handle_record, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }
    define_callbacks :handle_standalone, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }

    def initialize( # rubocop:disable Metrics/ParameterLists
      fields:,
      current_user:,
      arguments:,
      resource:,
      action:,
      query:,
      records: nil
    )
      @records = records
      @fields = fields
      @current_user = current_user
      @arguments = arguments
      @resource = resource
      @query = query

      @action = action
    end

    attr_reader :records, :fields, :current_user, :arguments, :resource, :query

    delegate :error, :avo, :keep_modal_open, :redirect_to, :inform, :action_name, :succeed, :logger,
      to: :@action

    set_callback :handle, :before do
      error "Must supply a sufficiently detailed comment" unless fields[:comment].presence&.then { _1.length >= 10 }
    end

    set_callback :handle, :around, lambda { |_, block|
      begin
        block.call
      rescue StandardError => e
        Rails.error.report(e, handled: true)
        error e.message
      end
    }

    def do_handle
      run_callbacks :handle do
        handle
      end
    ensure
      keep_modal_open if errored?
    end

    def handle_record(record)
      raise NotImplementedError, "#{self.class}#handle_record is not implemented"
    end

    def handle_standalone
      raise NotImplementedError, "#{self.class}#handle_standalone is not implemented"
    end

    def do_handle_record(record)
      run_callbacks :handle_record do
        handle_record(record)
      end
    end

    def errored?
      @action.response[:messages].any? { _1[:type] == :error }
    end

    def do_handle_standalone
      _, audit = in_audited_transaction(
        auditable: :return,
        admin_github_user: current_user,
        action: action_name,
        fields:,
        arguments:,
        models: records
      ) do
        run_callbacks :handle_standalone do
          handle_standalone
        end
      end
      redirect_to avo.resources_audit_path(audit)
    end

    def handle
      return do_handle_standalone if @action.class.standalone
      records.each do |record|
        _, audit = in_audited_transaction(
          auditable: record,
          admin_github_user: current_user,
          action: action_name,
          fields:,
          arguments:,
          models: records
        ) do
          do_handle_record(record)
        end
        redirect_to avo.resources_audit_path(audit)
      end
    end
  end

  def handle(**args)
    action_handler = self.class.const_get(:ActionHandler)
      .new(**args, arguments:, action: self)

    action_handler.do_handle
  end
end
