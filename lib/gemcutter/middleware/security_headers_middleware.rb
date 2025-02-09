class SecurityHeadersMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Ensure COOP is set for all responses (HTML, APIs, static files, errors)
    headers["Cross-Origin-Opener-Policy"] = "same-origin"

    [status, headers, response]
  end
end
