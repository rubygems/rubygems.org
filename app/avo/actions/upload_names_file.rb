class Avo::Actions::UploadNamesFile < Avo::Actions::ApplicationAction
  self.name = "Upload Names File"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :index
  }
  self.standalone = true
  self.confirm_button_label = "Upload"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_standalone
      UploadNamesFileJob.perform_later

      succeed("Upload job scheduled")

      Version.last
    end
  end
end
