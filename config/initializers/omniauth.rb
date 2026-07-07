# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  configure do |config|
    config.path_prefix = "/oauth"
  end

  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: %w[
    read:user
    read:org
  ].join(",")
end

OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")
OmniAuth.config.logger = SemanticLogger[OmniAuth]

class FailureEndpoint < OmniAuth::FailureEndpoint
  # ensures that same-site: strict cookies are available for csrf validation
  def call
    if env["omniauth.error.type"] == :csrf_detected && env["HTTP_SEC_FETCH_SITE"] == "cross-site"
      request = Rack::Request.new(env)
      # avoid overwriting the (real) session cookie
      request.session.options[:skip] = true
      # redirect to the same path, but with a meta refresh to avoid the browser treating the request as cross-site
      [303, {}, ["<!DOCTYPE html><html><head><meta http-equiv='refresh' content='0; #{request.fullpath}' /></head></html>"]]
    else
      super
    end
  end
end

OmniAuth.config.on_failure = FailureEndpoint

# TODO: Delete this when pull#186 is merged for omniauth-oauth2
# TLDR: There's a bug in the comparison for the `state` value if the state from the omniauth callback
#   is not yet set in the session. Deleting the params from the session causes a nil-byte error that bubbles
#   up to OmniAuth's catch for StandardErrors and will redirect to our FailureEndpoint
#   - We can avoid this by calling .to_s on nil and returning "" in the secure_compare
# https://github.com/omniauth/omniauth-oauth2/issues/189
# https://github.com/omniauth/omniauth-oauth2/issues/189#issuecomment-4624416883
# https://github.com/omniauth/omniauth-oauth2/pull/186
OmniAuth::Strategies::OAuth2.prepend(Module.new do
  def secure_compare(string_a, string_b)
    super(string_a.to_s, string_b.to_s)
  end
end)
