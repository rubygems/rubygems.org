Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, "865362df5bb4a371a8d4", "f24d263913ee7a5405ab67edd566ff06ef7d01cc", scope: 'read:org', provider_ignores_state: true
end

OmniAuth::AuthenticityTokenProtection.default_options(key: "csrf.token", authenticity_param: "_csrf")
