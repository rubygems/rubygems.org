require "test_helper"

class Onboarding::NameControllerTest < ActionController::TestCase
  setup do
    @user = create(:user, :mfa_enabled)
    @gem = create(:rubygem, owners: [@user])

    sign_in_as(@user)
  end

  context "GET new" do
    should "ask the user to start creating a new organization" do
      get :new

      assert_select "input[name=?]", "organization_onboarding[title]"
    end

    context "when the user has an existing onboarding" do
      setup do
        @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending, title: "Existing Name")
      end

      should "render with the in-progress onboarding" do
        get :new

        assert_select "input[name=?][value=?]", "organization_onboarding[title]", @organization_onboarding.title
      end
    end
  end

  context "POST create" do
    should "create a new onboarding and redirect to the next step" do
      post :create, params: { organization_onboarding: { title: "New Name" } }

      assert_redirected_to onboarding_gems_path
    end

    context "when the user has an existing onboarding" do
      setup do
        @organization_onboarding = create(:organization_onboarding, created_by: @user, status: :pending, title: "Existing Name")
      end

      should "update the existing onboarding and redirect to the next step" do
        post :create, params: { organization_onboarding: { title: "Updated Name" } }

        assert_redirected_to onboarding_gems_path
        assert_equal "Updated Name", @organization_onboarding.reload.title
      end
    end

    context "when the onboarding is invalid" do
      should "render the form with an error" do
        post :create, params: { organization_onboarding: { title: "" } }

        assert_response :unprocessable_entity
      end
    end
  end
end
