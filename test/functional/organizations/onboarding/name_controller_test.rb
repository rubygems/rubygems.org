require "test_helper"

class Organizations::Onboarding::NameControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :mfa_enabled)
    @gem = create(:rubygem, owners: [@user])

    FeatureFlag.enable_for_actor(FeatureFlag::ORGANIZATIONS, @user)
  end

  should "require feature flag enablement" do
    with_feature(FeatureFlag::ORGANIZATIONS, enabled: false, actor: @user) do
      get organization_onboarding_name_path(as: @user)

      assert_response :not_found

      post organization_onboarding_name_path(as: @user), params: { organization_onboarding: {
        organization_name: "New Name", organization_handle: @gem.name, name_type: "gem"
      } }

      assert_response :not_found
    end
  end

  context "GET new" do
    should "ask the user to start creating a new organization" do
      get organization_onboarding_name_path(as: @user)

      assert_select "input[name=?]", "organization_onboarding[organization_name]"
    end

    context "when the user has an existing onboarding" do
      setup do
        @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending, organization_name: "Existing Name")
      end

      should "render with the in-progress onboarding" do
        get organization_onboarding_name_path(as: @user)

        assert_select "input[name=?][value=?]", "organization_onboarding[organization_name]", @organization_onboarding.organization_name
      end
    end

    context "when the user has an existing failed onboarding" do
      setup do
        @organization_onboarding = create(
          :organization_onboarding,
          :failed,
          created_by: @user,
          organization_name: "Failed Name"
        )
      end

      should "render with the failed onboarding" do
        get organization_onboarding_name_path(as: @user)

        assert_select "input[name=?][value=?]", "organization_onboarding[organization_name]", @organization_onboarding.organization_name
      end
    end
  end

  context "POST create" do
    should "create a new onboarding and redirect to the next step" do
      post organization_onboarding_name_path(as: @user), params: { organization_onboarding: {
        organization_name: "New Name", organization_handle: @gem.name, name_type: "gem"
      } }

      assert OrganizationOnboarding.exists?(organization_name: "New Name", organization_handle: @gem.name, name_type: "gem")
      assert_redirected_to organization_onboarding_gems_path
    end

    context "when the user has an existing onboarding" do
      setup do
        @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending, organization_name: "Existing Name")
      end

      should "update the existing onboarding and redirect to the next step" do
        post organization_onboarding_name_path(as: @user), params: { organization_onboarding: {
          organization_name: "Updated Name"
        } }

        assert_redirected_to organization_onboarding_gems_path
        assert_equal "Updated Name", @organization_onboarding.reload.organization_name
      end
    end

    context "when the onboarding is invalid" do
      should "render the form with an error" do
        post organization_onboarding_name_path(as: @user), params: { organization_onboarding: {
          organization_name: ""
        } }

        assert_response :unprocessable_content
      end
    end
  end
end
