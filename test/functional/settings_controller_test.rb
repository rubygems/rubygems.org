# frozen_string_literal: true

require "test_helper"

class SettingsControllerTest < ActionController::TestCase
  context "when not logged in" do
    setup do
      @user = create(:user)
      get :edit
    end
    should redirect_to("the sign in page") { sign_in_path }
  end

  context "when logged in" do
    setup do
      @user = create(:user)
      sign_in_as(@user)
    end

    context "on the redesigned settings page" do
      setup { get :edit }

      should respond_with :success

      should "render the page heading" do
        assert_select "h1", text: "Edit settings"
      end

      should "render the subject sidebar with settings marked active" do
        assert_select "nav a[href=?]", edit_settings_path, text: /Settings/
        assert_select "nav a[href=?].bg-orange-100", edit_settings_path
      end

      should "group the multi-factor authentication controls in a card" do
        assert_select "h2", text: /Multi-factor authentication/
        assert_select "h3", text: "Security device"
        assert_select "h3", text: "Authentication app"
      end

      should "list the account links" do
        assert_select "a[href=?]", new_password_path
        assert_select "a[href=?]", profile_api_keys_path
        assert_select "a[href=?]", profile_oidc_pending_trusted_publishers_path
      end
    end

    context "when user owns a gem with more than MFA_REQUIRED_THRESHOLD downloads" do
      setup do
        @rubygem = create(:rubygem)
        create(:ownership, rubygem: @rubygem, user: @user)
        GemDownload.increment(
          Rubygem::MFA_REQUIRED_THRESHOLD + 1,
          rubygem_id: @rubygem.id
        )
      end

      context "user has mfa disabled" do
        setup { get :edit }
        should "flash a warning message" do
          assert_response :success
          assert page.has_content? "For protection of your account and your gems, you are required to set up multi-factor authentication."
        end
      end

      context "user has mfa set to weak level" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          get :edit
        end

        should "stay on edit settings page without redirecting" do
          assert_response :success
          assert page.has_content? "Edit settings"
        end
      end

      context "user has MFA set to strong level, expect normal behaviour" do
        setup do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          get :edit
        end

        should "stay on edit settings page without redirecting" do
          assert_response :success
          assert page.has_content? "Edit settings"
        end
      end
    end
  end
end
