require "test_helper"

class User::WithPrivateFieldsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  context "#mfa_warning" do
    context "when mfa is recommended" do
      setup do
        @user = User::WithPrivateFields.new(email_confirmed: true, handle: "test")
        @user.stubs(:mfa_recommended?).returns true
      end

      context "when mfa is disabled" do
        should "include warning in user json" do
          expected_notice = I18n.t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp

          assert_includes JSON.parse(@user.to_json)["warning"], expected_notice
        end
      end

      context "when mfa is enabled" do
        context "on `ui_only` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
          end

          should "include warning in user json" do
            expected_notice = I18n.t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp

            assert_includes JSON.parse(@user.to_json)["warning"], expected_notice
          end
        end

        context "on `ui_and_gem_signin` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
          end

          should "not include warning in user json" do
            unexpected_notice = I18n.t("multifactor_auths.api.mfa_recommended_not_yet_enabled").chomp

            refute_includes JSON.parse(@user.to_json)["warning"].to_s, unexpected_notice
          end
        end

        context "on `ui_and_api` level" do
          setup do
            @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          end

          should "not include warning in user json" do
            unexpected_notice = I18n.t("multifactor_auths.api.mfa_recommended_weak_level_enabled").chomp

            refute_includes JSON.parse(@user.to_json)["warning"].to_s, unexpected_notice
          end
        end
      end
    end
  end
end
