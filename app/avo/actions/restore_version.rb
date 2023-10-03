class RestoreVersion < BaseAction
  self.name = "Restore version"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.model.yanked?
  }
  self.message = lambda {
    "Are you sure you would like to restore #{record.slug} with "
  }
  self.confirm_button_label = "Restore version"

  class ActionHandler < ActionHandler
    def handle_model(version)
      Deletion.where(version: version).find_each do |deletion|
        deletion.restore!
      end
    end
  end
end
