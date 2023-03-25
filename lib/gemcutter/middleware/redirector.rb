module Gemcutter::Middleware
  class Redirector
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      allowed_hosts = [Gemcutter::HOST, "index.rubygems.org", "fastly.rubygems.org", "bundler.rubygems.org", "rubygems.team"]

      if allowed_hosts.exclude?(request.host) && request.path !~ %r{^/api|^/internal} && request.host.exclude?("docs")
        fake_request = Rack::Request.new(env.merge("HTTP_HOST" => Gemcutter::HOST))
        redirect_to(fake_request.url)
      else
        @app.call(env)
      end
    end

    private

    def redirect_to(url)
      [301, { "Location" => url }, []]
    end
  end
end
