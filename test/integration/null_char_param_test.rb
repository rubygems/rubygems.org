require "test_helper"

class NullCharParamTest < ActionDispatch::IntegrationTest
  test "params with null character respond with bad request" do
    get "/search?utf8=%E2%9C%93&query=php://input%00.&search_submit=%E2%8C%95"
    assert_response :bad_request
  end

  test "nested params with null character respond with bad request" do
    get "/search?utf8=%E2%9C%93&query[some]=php://input%00.&search_submit=%E2%8C%95"
    assert_response :bad_request
  end

  test "cookie with null character responds with bad request for sign in" do
    get "/users/new", headers: { "HTTP_COOKIE" => "remember_token=php://input%00.;rubygems_session=php://input%00." }
  end

  test "cookie with null character responds with bad request for releases page" do
    get "/releases/popular", headers: { "HTTP_COOKIE" => "rubygems_session=php://input%00." }
  end
end
