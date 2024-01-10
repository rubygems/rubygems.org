class Avo::Actions::ReleaseReservedNamespace < Avo::Actions::ApplicationAction
  self.name = "Release reserved namespace"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to Release #{record.name} namespace?"
  }

  self.confirm_button_label = "Release namespace"

  class ActionHandler < ActionHandler
    def handle_record(rubygem)
      rubygem.release_reserved_namespace!
    end
  end
end
