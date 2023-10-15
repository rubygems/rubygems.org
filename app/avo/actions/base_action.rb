class BaseAction < Avo::BaseAction
  include SemanticLogger::Loggable

  field :comment, as: :textarea, required: true,
    help: "A comment explaining why this action was taken.<br>Will be saved in the audit log.<br>Must be more than 10 characters."

  def self.inherited(base)
    super
    base.items_holder = Avo::ItemsHolder.new
    base.items_holder.instance_variable_get(:@items).replace items_holder.instance_variable_get(:@items).deep_dup
    base.items_holder.invalid_fields.replace items_holder.invalid_fields.deep_dup
  end

  class ActionHandler
    include Auditable
    include SemanticLogger::Loggable

    include ActiveSupport::Callbacks
    define_callbacks :handle, terminator: lambda { |target, result_lambda|
      result_lambda.call
      target.errored?
    }
    define_callbacks :handle_model, terminator: lambda { |target, result_lambda|
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
        error e.message.truncate(300)
      end
    }

    def do_handle
      run_callbacks :handle do
        handle
      end
    ensure
      keep_modal_open if errored?
    end

    def do_handle_model(model)
      run_callbacks :handle_model do
        handle_model(model)
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
        models:
      ) do
        run_callbacks :handle_standalone do
          handle_standalone
        end
      end
      redirect_to avo.resources_audit_path(audit)
    end

    def handle
      return do_handle_standalone if models.nil?
      models.each do |model|
        _, audit = in_audited_transaction(
          auditable: model,
          admin_github_user: current_user,
          action: action_name,
          fields:,
          arguments:,
          models:
        ) do
          do_handle_model(model)
        end
        redirect_to avo.resources_audit_path(audit)
      end
    end
  end

  def handle(**args)
    "#{self.class}::ActionHandler"
      .constantize
      .new(**args, arguments:, action: self)
      .do_handle
  end
end
