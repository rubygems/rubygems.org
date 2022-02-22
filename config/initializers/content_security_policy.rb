# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  unless Rails.env.development?
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, "https://secure.gaug.es", "https://gravatar.com", "https://secure.gravatar.com", "https://*.fastly-insights.com"
    policy.object_src  :none
    policy.script_src  :self, "https://secure.gaug.es", "https://www.fastly-insights.com"
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.connect_src :self, "https://s3-us-west-2.amazonaws.com/rubygems-dumps/", "https://*.fastly-insights.com", "https://fastly-insights.com", "https://api.github.com"
    policy.form_action :self
    policy.frame_ancestors :self
  end

  # Specify URI for violation reports
  # policy.report_uri "/csp-violation-report-endpoint"
end

# Generate session nonces for permitted importmap and inline scripts
# Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
# Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI. See:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# config.content_security_policy_report_only = truepoint
