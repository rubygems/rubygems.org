class RestoreVersion < BaseAction
  self.name = "Restore version"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.model.indexed == false
  }
  self.message = lambda {
    "Are you sure you would like to restore #{record.slug} with "
  }
  self.confirm_button_label = "Restore version"

  class ActionHandler < ActionHandler
    def handle_model(version)
      rubygem = version.rubygem
      Deletion.where(rubygem: rubygem.name, number: version.number, platform: version.platform).each do |deletion|
        deletion.version = rubygem.find_version!(number: deletion.number, platform: deletion.platform)
        deletion.restore!
      end
    end
  end
end
