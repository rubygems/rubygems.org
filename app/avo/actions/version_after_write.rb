class Avo::Actions::VersionAfterWrite < Avo::Actions::ApplicationAction
  self.name = "Run version post-write job"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") &&
      view == :show &&
      resource.record.deletion.blank?
  }

  self.message = lambda {
    "Are you sure you would like to run the after-write job for #{record.full_name}? The version is #{'not ' unless record.indexed?} indexed."
  }

  self.confirm_button_label = "Run Job"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(version)
      AfterVersionWriteJob.new(version: version).perform(version: version)
    end
  end
end
