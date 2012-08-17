class RecoveryMode
  def self.matches?(request)
    !Rails.env.recovery?
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if request.path.starts_with?("/api/v1")
      [503, {"Content-Type" => "text/plain"}, ["RubyGems.org's API is currently recovering. Check out http://status.rubygems.org and @rubygems_status for more info."]]
    else
      @app.call(env)
    end
  end
end
