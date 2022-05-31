require "test_helper"

class User::WithPrivateFieldsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  context "#mfa_warnings" do
    context "when mfa is recommended" do
      setup do
        @user = User::WithPrivateFields.new(email_confirmed: true, handle: "test")
        @user.stubs(:mfa_recommended?).returns true
      end

      context "when mfa is disabled" do
        should "include warnings in user json" do
          expected_notice =
            "For protection of your account and gems, we encourage you to set up multifactor authentication"\
            " at https://rubygems.org/multifactor_auth/new. Your account will be required to have MFA enabled in the future."

          assert_match expected_notice, @user.to_json
        end
      end

      context "when mfa is enabled" do
        context "on `ui_only` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
          end

          should "include warnings in user json" do
            expected_notice =
              "For protection of your account and gems, we encourage you to change your multifactor authentication"\
              " level to 'UI and gem signin' or 'UI and API' at https://rubygems.org/settings/edit."\
              " Your account will be required to have MFA enabled on one of these levels in the future."

            assert_match expected_notice, @user.to_json
          end
        end

        context "on `ui_and_gem_signin` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          end

          should "not include warnings in user json" do
            unexpected_notice =
              "For protection of your account and gems"

            refute_match unexpected_notice, @user.to_json
          end
        end

        context "on `ui_and_api` level" do
          setup do
            @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
          end

          should "not include warnings in user json" do
            unexpected_notice =
              "For protection of your account and gems"

            refute_match unexpected_notice, @user.to_json
          end
        end
      end
    end
  end
end
