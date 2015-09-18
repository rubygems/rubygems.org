require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "supply no credentials to a protected resource" do
    get api_v1_rubygems_path
    assert_response :unauthorized
  end

  test "use an Oauth access token" do
    access = create(:oauth_access_token, resource_owner_id: @user.id)
    get api_v1_rubygems_path(format: :json), {}, {"HTTP_AUTHORIZATION" => "Bearer #{access.token}"}
    assert_response :success
  end

  test "use an invalid Oauth access token" do
    access = create(:oauth_access_token, resource_owner_id: @user.id)
    get api_v1_rubygems_path(format: :json), {}, {"HTTP_AUTHORIZATION" => "Bearer deadbeef"}
    assert_response :unauthorized
  end

  test "use an access token connected to an non-existent user" do
    @user.destroy
    access = create(:oauth_access_token, resource_owner_id: @user.id)
    get api_v1_rubygems_path(format: :json), {}, {"HTTP_AUTHORIZATION" => "Bearer #{access.token}"}
    assert_response :unauthorized
  end

  test "use Authorization header with API key" do
    get api_v1_rubygems_path(format: :json), {}, {"HTTP_AUTHORIZATION" => @user.api_key}
    assert_response :success
  end

  test "use Authorization header without valid API key" do
    get api_v1_rubygems_path(format: :json), {}, {"HTTP_AUTHORIZATION" => "deadbeef"}
    assert_response :unauthorized
  end
end
