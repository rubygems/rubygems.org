class Avo::Actions::OnboardOrganization < Avo::Actions::ApplicationAction
  self.name = "Onboard Organization"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to onboard this organization?"
  }

  self.confirm_button_label = "Onboard"

  def handle(query:, **_)
    query.each(&:onboard!)
  end
end
