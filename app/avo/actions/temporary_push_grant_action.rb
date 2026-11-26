# frozen_string_literal: true

# Operator actions on a temporary push grant. Each runs in an audited transaction.
class Avo::Actions::TemporaryPushGrantAction < Avo::Actions::ApplicationAction
  self.visible = lambda {
    Admin::TemporaryPushGrantPolicy.new(current_user, resource.record).act_on? && view == :show
  }
  self.authorize = lambda {
    Admin::TemporaryPushGrantPolicy.new(current_user, action.record).act_on?
  }

  class ActionHandler < Avo::Actions::ActionHandler
    # Model guards raise RecordInvalid; show the reasons instead of a generic failure.
    # Registered after the base handler's rescue, so it runs inside it, outside the
    # audited transaction: a refused action rolls back and leaves no audit.
    set_callback :handle, :around, lambda { |handler, block|
      begin
        block.call
      rescue ActiveRecord::RecordInvalid => e
        handler.error e.record.errors.full_messages.to_sentence
      end
    }
  end
end
