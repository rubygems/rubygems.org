# frozen_string_literal: true

class Avo::Actions::ApproveTemporaryPushGrant < Avo::Actions::TemporaryPushGrantAction
  self.name = "Approve Temporary Push Grant"
  self.message = lambda {
    "Approve grant ##{record.id}: #{record.grantee.handle} may publish #{record.rubygem.name} #{record.version} " \
      "(#{record.artifacts.map(&:platform).join(', ')}) from #{record.source_commit}?"
  }
  self.confirm_button_label = "Approve"

  def fields
    field :conflict_disclosure, as: :textarea, required: true,
      help: "Disclose any relevant conflicts, or state that you have none. A conflicted operator cannot approve."
    super
  end

  class ActionHandler < Avo::Actions::TemporaryPushGrantAction::ActionHandler
    def handle_record(grant)
      return error("Conflict disclosure is required") if fields[:conflict_disclosure].blank?

      grant.approve!(current_user, conflict_disclosure: fields[:conflict_disclosure])
      succeed "Recorded #{current_user.login}'s approval of grant ##{grant.id}"
    end
  end
end
