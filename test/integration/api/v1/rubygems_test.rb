require 'test_helper'

class Api::V1::RubygemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
  end

  test "request with array of api keys returns unauthorize" do
    get "/api/v1/gems?api_key=#{@user.api_key}", as: :json
    assert_response :success

    get "/api/v1/gems?api_key[]=#{@user.api_key}&api_key[]=key1", as: :json
    assert_response :unauthorized
  end
end
