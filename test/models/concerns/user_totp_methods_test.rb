require "test_helper"

class UserTotpMethodsTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = create(:user)
  end

  context "#totp_enabled?" do
    should "return true if totp is enabled" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

      assert_predicate @user, :totp_enabled?
    end

    should "return false if totp is disabled" do
      @user.disable_totp!

      refute_predicate @user, :totp_enabled?
    end
  end

  context "#totp_disabled?" do
    should "return true if totp is disabled" do
      @user.disable_totp!

      assert_predicate @user, :totp_disabled?
    end

    should "return false if totp is enabled" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

      refute_predicate @user, :totp_disabled?
    end
  end

  context "#disable_totp!" do
    setup do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    end

    should "send mfa disabled email" do
      perform_disable_totp_job

      assert_emails 1

      assert_equal "Multi-factor authentication disabled on RubyGems.org", last_email.subject
      assert_equal [@user.email], last_email.to
    end

    should "set mfa_level to disabled if webauthn is also disabled" do
      perform_disable_totp_job

      assert_equal "disabled", @user.mfa_level
    end

    should "maintain the mfa_level if webauthn is enabled" do
      @credential = create(:webauthn_credential, user: @user)
      perform_disable_totp_job

      assert_equal "ui_only", @user.mfa_level
    end

    should "delete recovery codes if webauthn is disabled" do
      perform_disable_totp_job

      assert_empty @user.mfa_recovery_codes
    end

    context "when webauthn is enabled" do
      setup do
        @credential = create(:webauthn_credential, user: @user)

        @user_recovery_codes = @user.mfa_recovery_codes
      end

      should "not delete recovery codes" do
        perform_disable_totp_job

        assert_equal @user_recovery_codes, @user.mfa_recovery_codes
      end
    end
  end

  context "#verify_and_enable_totp!" do
    setup do
      @seed = ROTP::Base32.random_base32
      @expiry = 30.minutes.from_now
    end

    should "enable mfa" do
      @user.verify_and_enable_totp!(
        @seed,
        :ui_and_api,
        ROTP::TOTP.new(@seed).now,
        @expiry
      )

      assert_predicate @user, :mfa_enabled?
    end

    should "add error if qr code expired" do
      @user.verify_and_enable_totp!(
        @seed,
        :ui_and_api,
        ROTP::TOTP.new(@seed).now,
        5.minutes.ago
      )

      refute_predicate @user, :mfa_enabled?
      expected_error = "The QR-code and key is expired. Please try registering a new device again."

      assert_contains @user.errors[:base], expected_error
    end

    should "add error if otp code is incorrect" do
      @user.verify_and_enable_totp!(
        @seed,
        :ui_and_api,
        ROTP::TOTP.new(ROTP::Base32.random_base32).now,
        @expiry
      )

      refute_predicate @user, :mfa_enabled?
      assert_contains @user.errors[:base], "Your OTP code is incorrect."
    end
  end

  context "#enable_totp!" do
    setup do
      @seed = ROTP::Base32.random_base32
    end

    context "if webauthn is disabled" do
      should "enable mfa" do
        assert_changes "@user.mfa_level", from: "disabled", to: "ui_and_api" do
          @user.enable_totp!(@seed, "ui_and_api")
        end
      end

      should "set mfa seed" do
        assert_changes "@user.mfa_seed", from: nil, to: @seed do
          @user.enable_totp!(@seed, "ui_and_api")
        end
      end

      should "generate recovery codes" do
        assert_changes "@user.mfa_recovery_codes.length", 10 do
          @user.enable_totp!(@seed, "ui_and_api")
        end
      end
    end

    context "if webauthn is enabled" do
      setup do
        create(:webauthn_credential, user: @user)
      end

      should "not reset mfa level and recovery codes" do
        assert_no_changes ["@user.mfa_level", "@user.mfa_recovery_codes"] do
          @user.enable_totp!(@seed, "ui_and_gem_signin")
        end
      end

      should "set mfa seed" do
        @user.enable_totp!(@seed, "ui_and_gem_signin")

        assert_equal @seed, @user.mfa_seed
      end
    end
  end

  def perform_disable_totp_job
    perform_enqueued_jobs only: ActionMailer::MailDeliveryJob do
      @user.disable_totp!
    end
  end
end
