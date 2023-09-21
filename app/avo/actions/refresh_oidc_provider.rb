class RefreshOIDCProvider < BaseAction
  self.name = "Refresh OIDC Provider"
  self.visible = lambda {
    current_user.team_member?("rubygems-org") && view == :show
  }

  self.message = lambda {
    "Are you sure you would like to refresh #{record.issuer}?"
  }

  self.confirm_button_label = "Refresh"

  class ActionHandler < ActionHandler
    def handle_model(provider)
      RefreshOIDCProviderJob.perform_now(provider:)
    end
  end
end
