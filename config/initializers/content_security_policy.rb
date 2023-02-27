# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src    :self, "https://fonts.gstatic.com"
  policy.img_src     :self, "https://secure.gaug.es", "https://gravatar.com", "https://www.gravatar.com", "https://secure.gravatar.com",
    "https://*.fastly-insights.com", "https://avatars.githubusercontent.com"
  policy.object_src  :none
  policy.script_src  :self, "https://secure.gaug.es", "https://www.fastly-insights.com"
  policy.style_src   :self, "https://fonts.googleapis.com"
  policy.connect_src :self, "https://s3-us-west-2.amazonaws.com/rubygems-dumps/", "https://*.fastly-insights.com", "https://fastly-insights.com", "https://api.github.com"
  policy.form_action :self, "https://github.com/login/oauth/authorize"
  policy.frame_ancestors :self

  # Specify URI for violation reports
  policy.report_uri lambda {
    ActionDispatch::Http::URL.url_for(
      protocol: 'https',
      host: 'csp-report.browser-intake-datadoghq.com',
      path: '/api/v2/logs',
      params: {
        "dd-api-key": ENV['DATADOG_CSP_API_KEY'].presence,
        "dd-evp-origin": 'content-security-policy',
        ddsource: 'csp-report',
        ddtags: {
          service: "rubygems.org",
          version: AppRevision.version,
          env: Rails.env,
          trace_id: Datadog::Tracing.correlation&.trace_id,
          "gemcutter.user.id": (current_user.id if respond_to?(:signed_in?) && signed_in?)
        }.compact.map { |k, v| "#{k}:#{v}" }.join(',')
      }.compact
    )
  }
end

# Generate session nonces for permitted importmap and inline scripts
Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI. See:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# config.content_security_policy_report_only = truepoint
