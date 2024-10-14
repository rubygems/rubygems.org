class Avo::Actions::UploadVersionsFile < Avo::Actions::ApplicationAction
  self.name = "Upload Versions File"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Upload"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      UploadVersionsFileJob.perform_later

      succeed("Upload job scheduled")

      Version.last
    end
  end
end
