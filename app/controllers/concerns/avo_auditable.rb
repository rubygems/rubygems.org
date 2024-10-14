module AvoAuditable
  extend ActiveSupport::Concern

  prepended do
    include Auditable

    prepend_around_action :unscope_users
  end

  def perform_action_and_record_errors(&blk)
    super do
      action = params.fetch(:action)
      fields = action == "destroy" ? {} : cast_nullable(model_params)

      @record.errors.add :comment, "must supply a sufficiently detailed comment" if fields[:comment]&.then { _1.length < 10 }
      raise ActiveRecord::RecordInvalid, @record if @record.errors.present?
      action_name = "Manual #{action} of #{@record.class}"

      value, @audit = in_audited_transaction(
        auditable: @record,
        admin_github_user: _current_user,
        action: action_name,
        fields: fields.reverse_merge(comment: action_name),
        arguments: {},
        models: [@record],
        &blk
      )
      value
    end
  end

  def after_update_path
    return avo.resources_audit_path(@audit) if @audit.present?

    super
  end

  def after_create_path
    return avo.resources_audit_path(@audit) if @audit.present?

    super
  end

  def unscope_users(&)
    User.unscoped(&)
  end
end
