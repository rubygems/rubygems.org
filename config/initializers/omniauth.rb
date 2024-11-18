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
