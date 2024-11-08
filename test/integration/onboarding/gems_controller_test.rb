require "test_helper"

class Onboarding::GemsControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @namesake_gem = create(:rubygem, owners: [@user])
    @gem = create(:rubygem, owners: [@user])
    @organization_onboarding = create(
      :organization_onboarding,
      created_by: @user,
      status: :pending,
      name_type: "gem",
      organization_handle: @namesake_gem.name,
      organization_name: "Existing Name"
    )

    sign_in_as(@user)
  end

  context "PATCH update" do
    should "save the selected gems and redirect to the next step" do
      patch :update, params: { organization_onboarding: { rubygems: [@gem.id] } }

      assert_redirected_to onboarding_users_path
      assert_equal [@namesake_gem.id, @gem.id], @organization_onboarding.reload.rubygems
    end

    should "allow selecting no additional gems" do
      patch :update

      assert_redirected_to onboarding_users_path
      assert_equal [@namesake_gem.id], @organization_onboarding.reload.rubygems
    end

    should "ignore empty params" do
      notmygem = create(:rubygem)
      patch :update, params: { organization_onboarding: { rubygems: [""] } }

      assert_redirected_to onboarding_users_path
      assert_equal [@namesake_gem.id], @organization_onboarding.reload.rubygems
    end

    should "invalidate unknown gems" do
      notmygem = create(:rubygem)
      patch :update, params: { organization_onboarding: { rubygems: [notmygem.id] } }

      assert_response :unprocessable_entity
      assert_equal [@namesake_gem.id], @organization_onboarding.reload.rubygems
    end
  end
end
