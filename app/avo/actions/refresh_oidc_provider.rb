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
      connection = Faraday.new(provider.issuer, request: { timeout: 2 }) do |f|
        f.request :json
        f.response :logger, logger, headers: false, errors: true, bodies: true
        f.response :raise_error
        f.response :json
      end
      resp = connection.get("/.well-known/openid-configuration")

      provider.configuration = resp.body
      provider.jwks = connection.get(provider.configuration.jwks_uri).body

      provider.save!
    end
  end
end
