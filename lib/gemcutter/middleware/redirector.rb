module Gemcutter::Middleware
  class Redirector
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)

      allowed_hosts = [Gemcutter::HOST, "index.rubygems.org", "fastly.rubygems.org", "bundler.rubygems.org"]

      if !allowed_hosts.include?(request.host) && request.path !~ %r{^/api|^/internal} && request.host !~ /docs/
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
