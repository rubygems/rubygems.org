require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "supply no credentials to a protected resource" do
    authenticate
    assert_response :unauthorized
  end

  test "use an Oauth access token" do
    access = create(:oauth_access_token, resource_owner_id: @user.id)
    authenticate "Bearer #{access.token}"
    assert_response :success
  end

  test "use an invalid Oauth access token" do
    authenticate "Bearer deadbeef"
    assert_response :unauthorized
  end

  test "use an access token connected to an non-existent user" do
    @user.destroy
    access = create(:oauth_access_token, resource_owner_id: @user.id)
    authenticate "Bearer #{access.token}"
    assert_response :unauthorized
  end

  test "use Authorization header with API key" do
    authenticate @user.api_key
    assert_response :success
  end

  test "use Authorization header without valid API key" do
    authenticate "deadbeef"
    assert_response :unauthorized
  end

  private

  def authenticate(authorization = "")
    get api_v1_rubygems_path(format: :json), headers: { "HTTP_AUTHORIZATION" => authorization }
  end
end
