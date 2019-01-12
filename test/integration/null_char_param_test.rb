require 'test_helper'

class NullCharParamTest < ActionDispatch::IntegrationTest
  test "params with null character respond with bad request" do
    get "/search?utf8=%E2%9C%93&query=php://input%00.&search_submit=%E2%8C%95"
    assert_response :bad_request
  end
end
