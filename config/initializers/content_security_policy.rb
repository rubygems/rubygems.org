# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, "https://fonts.gstatic.com"
    policy.img_src     :self, "https://secure.gaug.es", "https://gravatar.com", "https://www.gravatar.com", "https://secure.gravatar.com",
      "https://*.fastly-insights.com", "https://avatars.githubusercontent.com"
    policy.object_src  :none
    # NOTE: This scirpt_src is overridden for all requests in ApplicationController
    # This is the baseline in case the override is ever skipped
    policy.script_src :self, "https://secure.gaug.es", "https://www.fastly-insights.com"
    policy.style_src :self, "https://fonts.googleapis.com"
    policy.connect_src :self, "https://s3-us-west-2.amazonaws.com/rubygems-dumps/", "https://*.fastly-insights.com", "https://fastly-insights.com",
      "https://api.github.com", "http://localhost:*"
    policy.form_action :self, "https://github.com/login/oauth/authorize"
    policy.frame_ancestors :self
    policy.base_uri :self

    # Specify URI for violation reports
    policy.report_uri lambda {
      dd_api_key = ENV['DATADOG_CSP_API_KEY'].presence
      url = ActionDispatch::Http::URL.url_for(
        protocol: 'https',
        host: 'csp-report.browser-intake-datadoghq.com',
        path: '/api/v2/logs',
        params: {
          "dd-api-key": dd_api_key,
          "dd-evp-origin": 'content-security-policy',
          ddsource: 'csp-report',
          ddtags: {
            service: "rubygems.org",
            version: AppRevision.version,
            env: Rails.env,
            trace_id: Datadog::Tracing.correlation&.trace_id,
            "gemcutter.user.id": (current_user.id if respond_to?(:signed_in?) && signed_in?)
          }.compact.map { |k, v| "#{k}:#{v}" }.join(',')
        }
      )
      # ensure we compute the URL on development/test,
      # but onlu return it if the API key is configures
      url if dd_api_key
    }
  end
end

# Generate session nonces for permitted importmap, inline scripts, and inline styles.
Rails.application.config.content_security_policy_nonce_generator = lambda { |request|
  # Suggested nonce generator doesn't work on first page load https://github.com/rails/rails/issues/48463
  # Related PR attempting to fix: https://github.com/rails/rails/pull/48510
  request.session.send(:load_for_write!) # force session to be created
  request.session.id.to_s.presence || SecureRandom.base64(16)
}
Rails.application.config.content_security_policy_nonce_directives = %w[script-src style-src]
