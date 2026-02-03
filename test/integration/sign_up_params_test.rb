require "test_helper"

class SignUpParamsTest < ActionDispatch::IntegrationTest
  test "sign up when user param is string" do
    assert_nothing_raised do
      get "/sign_up?user=JJJ12QQQ"
    end
  end
end
