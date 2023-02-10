require "test_helper"

class UserMultifactorMethodsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  context "#mfa_enabled" do
    should "return true if multifactor auth is not disabled" do
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      assert_predicate @user, :mfa_enabled?
    end

    should "return true if multifactor auth is disabled" do
      @user.disable_mfa!
      refute_predicate @user, :mfa_enabled?
    end
  end

  context "#disable_mfa!" do
    setup do
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      @user.disable_mfa!
    end

    should "disable mfa" do
      assert_predicate @user, :mfa_disabled?
      assert_empty @user.mfa_seed
      assert_empty @user.mfa_recovery_codes
    end
  end

  context "#verify_and_enable_mfa!" do
    setup do
      @seed = ROTP::Base32.random_base32
      @expiry = 30.minutes.from_now
    end

    should "enable mfa" do
      @user.verify_and_enable_mfa!(
        @seed,
        :ui_and_api,
        ROTP::TOTP.new(@seed).now,
        @expiry
      )

      assert_predicate @user, :mfa_enabled?
    end

    should "add error if qr code expired" do
      @user.verify_and_enable_mfa!(
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
      @user.verify_and_enable_mfa!(
        @seed,
        :ui_and_api,
        ROTP::TOTP.new(ROTP::Base32.random_base32).now,
        @expiry
      )

      refute_predicate @user, :mfa_enabled?
      assert_contains @user.errors[:base], "Your OTP code is incorrect."
    end
  end

  context "#enable_mfa!" do
    setup do
      @seed = ROTP::Base32.random_base32
      @level = :ui_and_api
      @user.enable_mfa!(@seed, @level)
    end

    should "enable mfa" do
      assert_equal @seed, @user.mfa_seed
      assert_predicate @user, :mfa_ui_and_api?
      assert_equal 10, @user.mfa_recovery_codes.length
    end
  end

  context "#mfa_gem_signin_authorized?" do
    setup do
      @seed = ROTP::Base32.random_base32
    end

    should "return true if mfa is ui_and_api and otp is correct" do
      @user.enable_mfa!(@seed, :ui_and_api)
      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
    end

    should "return true if mfa is ui_and_gem_signin and otp is correct" do
      @user.enable_mfa!(@seed, :ui_and_gem_signin)
      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
    end

    should "return true if mfa is disabled" do
      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
    end

    should "return true if mfa is ui_only" do
      @user.enable_mfa!(@seed, :ui_only)
      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
    end

    should "return false if otp is incorrect" do
      @user.enable_mfa!(@seed, :ui_and_gem_signin)
      refute @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
    end
  end

  context "#mfa_recommended_not_yet_enabled?" do
    setup do
      @popular_rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
        rubygem_id: @popular_rubygem.id
      )
    end

    should "return true if instance owns a gem that exceeds recommended threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_recommended_not_yet_enabled?
    end

    should "return false if instance owns a gem that exceeds recommended threshold and has mfa enabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)

      refute_predicate @user, :mfa_recommended_not_yet_enabled?
    end

    should "return false if instance does not own a gem that exceeds recommended threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: create(:rubygem))

      refute_predicate @user, :mfa_recommended_not_yet_enabled?
    end
  end

  context "#mfa_recommended_weak_level_enabled?" do
    setup do
      @popular_rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_RECOMMENDED_THRESHOLD + 1,
        rubygem_id: @popular_rubygem.id
      )
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    end

    should "return true if instance owns a gem that exceeds recommended threshold and has mfa ui_only" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_recommended_weak_level_enabled?
    end

    should "return false if instance owns a gem that exceeds recommended threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.disable_mfa!

      refute_predicate @user, :mfa_recommended_weak_level_enabled?
    end

    should "return false if instance does not own a gem that exceeds recommended threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: create(:rubygem))

      refute_predicate @user, :mfa_recommended_weak_level_enabled?
    end
  end

  context "#mfa_required_not_yet_enabled?" do
    setup do
      @popular_rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: @popular_rubygem.id
      )
    end

    should "return true if instance owns a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_required_not_yet_enabled?
    end

    should "return false if instance owns a gem that exceeds required threshold and has mfa enabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)

      refute_predicate @user, :mfa_required_not_yet_enabled?
    end

    should "return false if instance does not own a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: create(:rubygem))

      refute_predicate @user, :mfa_required_not_yet_enabled?
    end
  end

  context "#mfa_required_weak_level_enabled?" do
    setup do
      @popular_rubygem = create(:rubygem)
      GemDownload.increment(
        Rubygem::MFA_REQUIRED_THRESHOLD + 1,
        rubygem_id: @popular_rubygem.id
      )
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
    end

    should "return true if instance owns a gem that exceeds required threshold and has mfa ui_only" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_required_weak_level_enabled?
    end

    should "return false if instance owns a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.disable_mfa!

      refute_predicate @user, :mfa_required_weak_level_enabled?
    end

    should "return false if instance does not own a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: create(:rubygem))

      refute_predicate @user, :mfa_required_weak_level_enabled?
    end
  end

  context "#otp_verified?" do
    setup do
      @user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
    end

    should "return true if otp is correct" do
      assert @user.otp_verified?(ROTP::TOTP.new(@user.mfa_seed).now)
    end

    should "return true for otp in last interval" do
      last_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current - 30)
      assert @user.otp_verified?(last_otp)
    end

    should "return true for otp in next interval" do
      next_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current + 30)
      assert @user.otp_verified?(next_otp)
    end

    should "return false if otp is incorrect" do
      refute @user.otp_verified?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
    end

    should "return true if recovery code is correct" do
      recovery_code = @user.mfa_recovery_codes.first

      assert @user.otp_verified?(recovery_code)
      refute_includes @user.mfa_recovery_codes, recovery_code
    end
  end

  context ".without_mfa" do
    setup do
      create(:user, mfa_level: :ui_and_api)
    end

    should "return instances without mfa" do
      user_without_mfa = User.without_mfa

      assert_equal 1, user_without_mfa.size
      assert_equal @user, user_without_mfa.first
    end
  end
end
