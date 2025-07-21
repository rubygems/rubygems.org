require "test_helper"

class Organizations::GemsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, remember_token_expires_at: Gemcutter::REMEMBER_FOR.from_now)
    post session_path(session: { who: @user.handle, password: PasswordHelpers::SECURE_TEST_PASSWORD })

    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, @user)
  end

  test "should require feature flag enablement" do
    with_feature(FeatureFlag::ORGANIZATIONS, enabled: false, actor: @user) do
      @organization = create(:organization, owners: [@user])

      get "/organizations/#{@organization.to_param}/gems"

      assert_response :not_found
    end
  end

  test "should get index" do
    @organization = create(:organization, owners: [@user])
    @organization.rubygems << create(:rubygem, name: "arrakis", number: "1.0.0")

    get "/organizations/#{@organization.to_param}/gems"

    assert page.has_content? "arrakis"
  end

  test "should get index with no gems" do
    @organization = create(:organization, owners: [@user])

    get "/organizations/#{@organization.to_param}/gems"

    assert page.has_content? "No gems yet"
  end
end
