# gracefully fail on malicious request breaking rack's query parser
#
# this is temporary solution for now
# TODO: remove once https://github.com/rack/rack/pull/1837 is solved
module Gemcutter::Middleware # rubocop:disable Style/ClassAndModuleChildren
  class DeepParamsHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      Rack::Request.new(env).params
      status, headers, response = @app.call(env)
      [status, headers, response]
    rescue RangeError
      [302, { "Location" => "/400.html" }, []]
    end
  end
end
