require_relative "../middleware"

class Gemcutter::Middleware::SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    # Ensure COOP header is set on all responses, including static error pages
    headers["Cross-Origin-Opener-Policy"] ||= "same-origin"

    [status, headers, body]
  end
end
