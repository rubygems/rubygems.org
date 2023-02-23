class ReleaseReservedNamespace < BaseAction
  self.name = "Release reserved namespace"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to Release #{record.name} namespace?"
  }

  self.confirm_button_label = "Release Namespace"

  class ActionHandler < ActionHandler
    def handle_model(rubygem)
      rubygem.update_attribute(:updated_at, 101.days.ago)
    end
  end
end

