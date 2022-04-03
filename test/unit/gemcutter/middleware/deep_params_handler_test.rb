require "test_helper"
require_relative "../../../../lib/gemcutter/middleware/deep_params_handler"

class Gemcutter::Middleware::DeepParamsHandlerTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Gemcutter::Middleware::DeepParamsHandler.new(-> { [200, {}, ""] })
  end

  context "malicious request breaking deep params rack limit" do
    should "gracefully fail" do
      limit = Rack::Utils.param_depth_limit + 1
      malicious_url = "/?#{'[test]' * limit}=test"
      get malicious_url

      assert_equal 302, last_response.status
    end
  end
end
