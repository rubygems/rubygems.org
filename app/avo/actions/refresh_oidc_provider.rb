class Avo::Actions::RefreshOIDCProvider < Avo::Actions::ApplicationAction
  self.name = "Refresh OIDC Provider"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to refresh #{record.issuer}?"
  }

  self.confirm_button_label = "Refresh"

  class ActionHandler < Avo::Actions::ActionHandler
    def handle_record(provider)
      RefreshOIDCProviderJob.perform_now(provider:)
    end
  end
end
