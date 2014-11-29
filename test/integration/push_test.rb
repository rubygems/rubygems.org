require 'test_helper'

class PushTest < ActionDispatch::IntegrationTest
  setup do
    Dir.chdir(Rails.root.join("tmp"))
    @user = create(:user, email: "nick@example.com", api_key: "secret123")
    cookies[:remember_token] = @user.remember_token
  end

  test "pushing a gem" do
    build_gem "sandworm", "1.0.0"

    post api_v1_rubygems_path, File.read("sandworm-1.0.0.gem"), {"HTTP_AUTHORIZATION" => @user.api_key, "CONTENT_TYPE" => "application/octet-stream"}
    assert_response :success

    get rubygem_path("sandworm")
    assert_response :success
    assert page.has_content?("sandworm")
    assert page.has_content?("1.0.0")
  end

  teardown do
    Dir.chdir(Rails.root)
  end
end
