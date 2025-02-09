require "test_helper"
require_relative "../../../../lib/gemcutter/middleware/security_headers_middleware.rb"


class SecurityHeadersMiddlewareTest < ActiveSupport::TestCase
  def setup
    @app = ->(_env) { [200, { "Content-Type" => "text/html" }, ["OK"]] }
    @middleware = SecurityHeadersMiddleware.new(@app)
  end

  test "adds Cross-Origin-Opener-Policy header to responses" do
    env = Rack::MockRequest.env_for("/")
    status, headers, _body = @middleware.call(env)

    assert_equal 200, status
    assert_equal "same-origin", headers["Cross-Origin-Opener-Policy"]
  end

  test "preserves other existing headers" do
    env = Rack::MockRequest.env_for("/")
    _, headers, _ = @middleware.call(env)

    assert headers.key?("Content-Type")
  end

  test "works with non-HTML responses" do
    @app = ->(_env) { [200, { "Content-Type" => "application/json" }, ["{}"]] }
    @middleware = SecurityHeadersMiddleware.new(@app)

    env = Rack::MockRequest.env_for("/api/test")
    status, headers, _body = @middleware.call(env)

    assert_equal 200, status
    assert_equal "same-origin", headers["Cross-Origin-Opener-Policy"]
  end

  test "applies header to error pages" do
    @app = ->(_env) { [404, { "Content-Type" => "text/html" }, ["Not Found"]] }
    @middleware = SecurityHeadersMiddleware.new(@app)

    env = Rack::MockRequest.env_for("/nonexistent")
    status, headers, _body = @middleware.call(env)

    assert_equal 404, status
    assert_equal "same-origin", headers["Cross-Origin-Opener-Policy"]
  end
end