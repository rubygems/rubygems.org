# frozen_string_literal: true

module AvoAuditable
  extend ActiveSupport::Concern

  prepended do
    include Auditable

    prepend_around_action :unscope_users
  end

  def perform_action_and_record_errors(&blk)
    super do
      action = params.fetch(:action)
      destroying = action == "destroy"
      fields = destroying ? {} : cast_nullable(model_params)

      # A missing comment has to be rejected the same way a short one is.
      # `comment` is not an attribute of the record, so a request that simply
      # leaves it out would otherwise skip this check entirely and be audited
      # with the generated action name in place of an explanation. Destroying
      # does not render the comment field, so it stays exempt. Matches the check
      # actions make in Avo::Actions::ApplicationAction.
      unless destroying || fields[:comment].presence&.then { it.length >= 10 }
        @record.errors.add :comment, "must supply a sufficiently detailed comment"
      end

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
