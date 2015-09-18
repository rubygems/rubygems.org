Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    env[:clearance].try(:current_user)
  end

  admin_authenticator do
    user = authenticate_resource_owner!
    if Gemcutter.admins.include? user.try(:email)
      user
    else
      fail Doorkeeper::Errors::DoorkeeperError, 'Not an admin'
    end
  end

  default_scopes :public

  access_token_methods :from_bearer_authorization

  native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  force_ssl_in_redirect_uri SimpleSSLRequirement::SSL_ENVIRONMENTS.include?(Rails.env)

  grant_flows %w(authorization_code)

  # All applications are trusted!
  skip_authorization do |resource_owner, client|
    true
  end
end
