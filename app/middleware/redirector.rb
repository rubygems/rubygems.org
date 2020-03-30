class Redirector
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    allowed_hosts = [Gemcutter::HOST, "index.rubygems.org", "fastly.rubygems.org", "bundler.rubygems.org", "ipv6.rubygems.org"]

    if !allowed_hosts.include?(request.host) && request.path !~ %r{^/api|^/internal} && request.host !~ /docs/
      fake_request = Rack::Request.new(env.merge("HTTP_HOST" => Gemcutter::HOST))
      redirect_to(fake_request.url)
    elsif request.path =~ %r{^/(book|chapter|export|read|shelf|syndicate)} && request.host !~ /docs/
      redirect_to("https://docs.rubygems.org#{request.path}")
    elsif %r{^/pages/docs$}.match?(request.path)
      redirect_to("https://guides.rubygems.org")
    elsif %r{^/pages/gem_docs$}.match?(request.path)
      redirect_to("https://guides.rubygems.org/command-reference")
    elsif %r{^/pages/api_docs$}.match?(request.path)
      redirect_to("https://guides.rubygems.org/rubygems-org-api")
    else
      @app.call(env)
    end
  end

  private

  def redirect_to(url)
    [301, { "Location" => url }, []]
  end
end
