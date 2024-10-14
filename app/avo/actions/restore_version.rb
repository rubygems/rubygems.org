class Avo::Actions::RestoreVersion < Avo::Actions::ApplicationAction
  self.name = "Restore version"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.record.deletion.present?
  }
  self.message = lambda {
    "Are you sure you would like to restore #{record.slug} with "
  }
  self.confirm_button_label = "Restore version"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(version)
      version.deletion&.restore!
    end
  end
end
