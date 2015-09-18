Doorkeeper.configure do
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  # called in the AuthorizedApplicationsController by `before_action :authenticate_resource_owner!`
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

  # Restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  # called in the ApplicationsController by `before_action :authenticate_admin!`
  admin_authenticator do
    user = authenticate_resource_owner!
    if Gemcutter.admins.include? user.email
      user
    else
      fail Doorkeeper::Errors::DoorkeeperError, 'Not an admin'
    end
  end

  default_scopes  :public
  # optional_scopes :write, :update

  access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  native_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Forces the usage of the HTTPS protocol in non-native redirect uris.
  # OAuth2 delegates security in communication to the HTTPS protocol so it is wise to keep this enabled.
  force_ssl_in_redirect_uri SimpleSSLRequirement::SSL_ENVIRONMENTS.include?(Rails.env)

  # implicit and password grant flows have risks that you should understand before enabling:
  #   http://tools.ietf.org/html/rfc6819#section-4.4.2
  #   http://tools.ietf.org/html/rfc6819#section-4.4.3
  #
  grant_flows %w(authorization_code)

  # All applications are trusted, so auto-approve applications, and
  # user skips authorization step.
  skip_authorization do |resource_owner, client|
    true # We're only supporting trusted apps.
  end
end
