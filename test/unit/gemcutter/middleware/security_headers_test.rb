require "test_helper"

class Gemcutter::Middleware::SecurityHeadersTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      use Gemcutter::Middleware::SecurityHeaders
      run ->(_env) { [200, { "Content-Type" => "text/html" }, ["OK"]] }
    end
  end

  should "add Cross-Origin-Opener-Policy header to responses" do
    get "/"

    assert_equal "same-origin", last_response.headers["Cross-Origin-Opener-Policy"]
  end

  should "not override existing Cross-Origin-Opener-Policy header" do
    custom_app = Rack::Builder.new do
      use Gemcutter::Middleware::SecurityHeaders
      run ->(_env) { [200, { "Cross-Origin-Opener-Policy" => "unsafe-none" }, ["OK"]] }
    end

    get "/", {}, "rack.test" => true
    # Make a request using the custom app
    status, headers, _body = custom_app.call(Rack::MockRequest.env_for("/"))

    assert_equal "unsafe-none", headers["Cross-Origin-Opener-Policy"]
  end

  should "add Cross-Origin-Opener-Policy header to error responses" do
    error_app = Rack::Builder.new do
      use Gemcutter::Middleware::SecurityHeaders
      run ->(_env) { [404, { "Content-Type" => "text/html" }, ["Not Found"]] }
    end

    status, headers, _body = error_app.call(Rack::MockRequest.env_for("/nonexistent"))

    assert_equal 404, status
    assert_equal "same-origin", headers["Cross-Origin-Opener-Policy"]
  end

  should "add Cross-Origin-Opener-Policy header to 500 error responses" do
    error_app = Rack::Builder.new do
      use Gemcutter::Middleware::SecurityHeaders
      run ->(_env) { [500, { "Content-Type" => "text/html" }, ["Internal Server Error"]] }
    end

    status, headers, _body = error_app.call(Rack::MockRequest.env_for("/error"))

    assert_equal 500, status
    assert_equal "same-origin", headers["Cross-Origin-Opener-Policy"]
  end
end
