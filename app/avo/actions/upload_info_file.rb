class Avo::Actions::UploadInfoFile < Avo::Actions::ApplicationAction
  self.name = "Upload Info File"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.confirm_button_label = "Upload"

  class ActionHandler < ActionHandler
    def handle_record(rubygem)
      UploadInfoFileJob.perform_later(rubygem_name: rubygem.name)

      succeed("Upload job scheduled")
    end
  end
end
