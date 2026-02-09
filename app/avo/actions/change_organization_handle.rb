class Avo::Actions::ChangeOrganizationHandle < Avo::Actions::ApplicationAction
  def fields
    field :new_handle, as: :text, required: true
    super
  end

  self.name = "Change Organization Handle"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }
  self.message = lambda {
    "Are you sure you would like to change the handle for organization '#{record.handle}'?"
  }
  self.confirm_button_label = "Change Handle"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(organization)
      organization.handle = fields["new_handle"]

      organization.save!
    end
  end
end
