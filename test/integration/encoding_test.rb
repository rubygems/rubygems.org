require 'test_helper'

class EncodingTest < ActionDispatch::IntegrationTest
  test "invalid utf-8 characters should be sanitized" do
    get "/api/v1/dependencies?gems=vagrant,vagrant-login,vagrant-share,vagrant%ADvbguest"
    assert_response :success
  end
end
