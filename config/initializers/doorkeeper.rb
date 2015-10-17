Doorkeeper.configure do
  orm :active_record

  resource_owner_authenticator do
    clearance_session = env[:clearance] # session = Clearance::Session.new(env)
    user = clearance_session && clearance_session.current_user

    if user
      user
    else
      session[:return_to] = request.fullpath
      redirect_to(sign_in_url)
    end
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

  force_ssl_in_redirect_uri Rails.application.config.force_ssl

  grant_flows %w(authorization_code)

  # All applications are trusted!
  skip_authorization do
    true
  end
end
