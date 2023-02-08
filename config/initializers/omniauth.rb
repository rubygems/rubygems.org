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
