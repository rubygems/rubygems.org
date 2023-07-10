require "test_helper"

class WebauthnCredentialTest < ActiveSupport::TestCase
  subject { build(:webauthn_credential) }

  should belong_to :user
  should validate_presence_of(:external_id)
  should validate_uniqueness_of(:external_id)
  should validate_presence_of(:public_key)
  should validate_presence_of(:nickname)
  should validate_presence_of(:sign_count)
  should validate_numericality_of(:sign_count).is_greater_than_or_equal_to(0)

  setup do
    @user = create(:user)
  end

  context "after create" do
    context "when user creates a webauthn credential and totp is disabled" do
      setup do
        @webauthn_credential = create(:webauthn_credential, user: @user)
      end

      should "set user mfa level to ui_and_api" do
        assert_equal "ui_and_api", @user.reload.mfa_level
      end

      should "set user mfa recovery codes" do
        assert_equal 10, @user.reload.mfa_recovery_codes.count
        assert_equal 10, @user.reload.hashed_mfa_recovery_codes.count
      end
    end

    context "when user has totp is enabled and creates a webauthn credential" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
        @codes = @user.mfa_recovery_codes
        @webauthn_credential = create(:webauthn_credential, user: @user)
      end

      should "not change user mfa level" do
        assert_equal "ui_and_gem_signin", @user.reload.mfa_level
      end

      should "not change user mfa recovery codes" do
        assert_equal @codes, @user.reload.mfa_recovery_codes
        @codes.zip(@user.reload.hashed_mfa_recovery_codes).each do |code, hashed_code|
          assert_equal BCrypt::Password.new(hashed_code), code
        end
      end
    end

    context "when user has two webauthn credentials and totp is disabled" do
      setup do
        @webauthn_credential = create(:webauthn_credential, user: @user)
        @user.update!(mfa_level: "ui_and_gem_signin")
        @codes = @user.mfa_recovery_codes
        @webauthn_credential2 = create(:webauthn_credential, user: @user)
      end

      should "not change user mfa level" do
        assert_equal "ui_and_gem_signin", @user.reload.mfa_level
      end

      should "not change user mfa recovery codes" do
        assert_equal @codes, @user.reload.mfa_recovery_codes
        @codes.zip(@user.reload.hashed_mfa_recovery_codes).each do |code, hashed_code|
          assert_equal BCrypt::Password.new(hashed_code), code
        end
      end
    end
  end

  context "after destroy" do
    setup do
      @webauthn_credential = create(:webauthn_credential, user: @user)
    end

    context "when user destroys a webauthn credential and totp is disabled" do
      should "disable mfa" do
        assert_changes -> { @user.reload.mfa_level }, from: "ui_and_api", to: "disabled" do
          @webauthn_credential.destroy!
        end
      end

      should "clear mfa recovery codes" do
        assert_changes -> { @user.reload.mfa_recovery_codes.count }, from: 10, to: 0 do
          assert_changes -> { @user.reload.hashed_mfa_recovery_codes.count }, from: 10, to: 0 do
            @webauthn_credential.destroy!
          end
        end
      end
    end

    context "when user has totp is enabled and destroys a webauthn credential" do
      setup do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        @webauthn_credential.destroy!
      end

      should "not change user mfa level" do
        assert_equal "ui_and_api", @user.reload.mfa_level
      end

      should "not change user mfa recovery codes" do
        assert_equal 10, @user.reload.mfa_recovery_codes.count
        assert_equal 10, @user.reload.hashed_mfa_recovery_codes.count
      end
    end

    context "when user has two webauthn credentials and totp is disabled" do
      setup do
        @webauthn_credential2 = create(:webauthn_credential, user: @user)
        @webauthn_credential.destroy!
      end

      should "not change user mfa level" do
        assert_equal "ui_and_api", @user.reload.mfa_level
      end

      should "not change user mfa recovery codes" do
        assert_equal 10, @user.reload.mfa_recovery_codes.count
        assert_equal 10, @user.reload.hashed_mfa_recovery_codes.count
      end
    end
  end
end
