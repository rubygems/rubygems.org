require "test_helper"

class Organizations::Onboarding::GemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :mfa_enabled)
    @namesake_rubygem = create(:rubygem, owners: [@user])
    @gem = create(:rubygem, owners: [@user])
    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      namesake_rubygem: @namesake_rubygem,
      status: :pending,
      organization_handle: @namesake_rubygem.name,
      organization_name: "Existing Name"
    )
  end

  context "PATCH update" do
    should "save the selected gems and redirect to the next step" do
      patch organization_onboarding_gems_path(as: @user), params: { organization_onboarding: { rubygems: [@gem.id] } }

      assert_redirected_to organization_onboarding_users_path
      assert_equal [@namesake_rubygem.id, @gem.id], @organization_onboarding.reload.rubygems
    end

    should "allow selecting no additional gems" do
      patch organization_onboarding_gems_path(as: @user)

      assert_redirected_to organization_onboarding_users_path
      assert_equal [@namesake_rubygem.id], @organization_onboarding.reload.rubygems
    end

    should "ignore empty params" do
      patch organization_onboarding_gems_path(as: @user), params: { organization_onboarding: { rubygems: [""] } }

      assert_redirected_to organization_onboarding_users_path
      assert_equal [@namesake_rubygem.id], @organization_onboarding.reload.rubygems
    end

    should "invalidate unknown gems" do
      notmygem = create(:rubygem)
      patch organization_onboarding_gems_path(as: @user), params: { organization_onboarding: { rubygems: [notmygem.id] } }

      assert_response :unprocessable_entity
      assert_equal [@namesake_rubygem.id], @organization_onboarding.reload.rubygems
    end
  end
end
