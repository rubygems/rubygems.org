require "test_helper"

class UserMultifactorMethodsTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = create(:user)
  end

  context "validations" do
    context "mfa_level_for_enabled_devices" do
      context "when mfa_level is disabled" do
        should "be valid if there no mfa devices" do
          assert_predicate @user, :valid?
        end

        should "be invalid if totp is enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          @user.mfa_level = :disabled

          refute_predicate @user, :valid?
        end

        should "be invalid if webauthn is enabled" do
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :disabled

          refute_predicate @user, :valid?
        end

        should "be invalid if both totp and webauthn are enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :disabled

          refute_predicate @user, :valid?
        end
      end

      context "when mfa_level is ui_and_gem_signin" do
        should "be invalid if there no mfa devices" do
          @user.mfa_level = :ui_and_gem_signin

          refute_predicate @user, :valid?
        end

        should "be valid if totp is enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          @user.mfa_level = :ui_and_gem_signin

          assert_predicate @user, :valid?
        end

        should "be valid if webauthn is enabled" do
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :ui_and_gem_signin

          assert_predicate @user, :valid?
        end

        should "be valid if both totp and webauthn are enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :ui_and_gem_signin

          assert_predicate @user, :valid?
        end
      end

      context "when mfa_level is ui_and_api" do
        should "be invalid if there no mfa devices" do
          @user.mfa_level = :ui_and_api

          refute_predicate @user, :valid?
        end

        should "be valid if totp is enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          @user.mfa_level = :ui_and_api

          assert_predicate @user, :valid?
        end

        should "be valid if webauthn is enabled" do
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :ui_and_api

          assert_predicate @user, :valid?
        end

        should "be valid if both totp and webauthn are enabled" do
          @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
          create(:webauthn_credential, user: @user)
          @user.mfa_level = :ui_and_api

          assert_predicate @user, :valid?
        end
      end
    end
  end

  context "#mfa_enabled" do
    should "return true if multifactor auth is not disabled" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

      assert_predicate @user, :mfa_enabled?
    end

    should "return true if multifactor auth is disabled" do
      @user.disable_totp!

      refute_predicate @user, :mfa_enabled?
    end

    should "send mfa enabled email" do
      assert_emails 1 do
        @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)
      end

      assert_equal "Multi-factor authentication enabled on RubyGems.org", last_email.subject
      assert_equal [@user.email], last_email.to
    end
  end

  context "#mfa_device_count_one?" do
    should "return true if user has one webauthn credential and no totp" do
      create(:webauthn_credential, user: @user)

      assert_predicate @user, :mfa_device_count_one?
    end

    should "return true if user has totp enabled and no webauthn credential" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

      assert_predicate @user, :mfa_device_count_one?
    end

    should "return false if user has totp enabled and one webauthn credential" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      create(:webauthn_credential, user: @user)

      refute_predicate @user, :mfa_device_count_one?
    end

    should "return false if user has no totp and no webauthn credential" do
      refute_predicate @user, :mfa_device_count_one?
    end

    should "return false if user has two webauthn credentials" do
      create(:webauthn_credential, user: @user)
      create(:webauthn_credential, user: @user)

      refute_predicate @user, :mfa_device_count_one?
    end
  end

  context "#no_mfa_devices?" do
    should "return true if user has no totp and no webauthn credential" do
      assert_predicate @user, :no_mfa_devices?
    end

    should "return false if user has one webauthn credential" do
      create(:webauthn_credential, user: @user)

      refute_predicate @user, :no_mfa_devices?
    end

    should "return false if user has totp enabled" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

      refute_predicate @user, :no_mfa_devices?
    end

    should "return false if user has totp and webauthn enabled" do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
      create(:webauthn_credential, user: @user)

      refute_predicate @user, :no_mfa_devices?
    end
  end

  context "#mfa_gem_signin_authorized?" do
    setup do
      @seed = ROTP::Base32.random_base32
    end

    context "with totp" do
      should "return true when correct and if mfa is ui_and_api" do
        @user.enable_totp!(@seed, :ui_and_api)

        assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
      end

      should "return true when correct and if mfa is ui_and_gem_signin" do
        @user.enable_totp!(@seed, :ui_and_gem_signin)

        assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
      end

      should "return false when incorrect" do
        @user.enable_totp!(@seed, :ui_and_gem_signin)

        refute @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
      end
    end

    context "with webauthn otp" do
      should "return true when correct and if mfa is ui_and_api" do
        @user.enable_totp!(@seed, :ui_and_api)
        webauthn_verification = create(:webauthn_verification, user: @user)

        assert @user.mfa_gem_signin_authorized?(webauthn_verification.otp)
      end

      should "return true when correct and if mfa is ui_and_gem_signin" do
        @user.enable_totp!(@seed, :ui_and_gem_signin)
        webauthn_verification = create(:webauthn_verification, user: @user)

        assert @user.mfa_gem_signin_authorized?(webauthn_verification.otp)
      end

      should "return true when correct and if mfa is disabled" do
        webauthn_verification = create(:webauthn_verification, user: @user)

        assert @user.mfa_gem_signin_authorized?(webauthn_verification.otp)
      end

      should "return false when incorrect" do
        @user.enable_totp!(@seed, :ui_and_gem_signin)
        create(:webauthn_verification, user: @user, otp: "jiEm2mm2sJtRqAVx7U1i")
        incorrect_otp = "Yxf57d1wEUSWyXrrLMRv"

        refute @user.mfa_gem_signin_authorized?(incorrect_otp)
      end
    end

    should "return true if mfa is disabled" do
      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
    end

    should "return true if mfa is ui_only" do
      @user.enable_totp!(@seed, :ui_only)

      assert @user.mfa_gem_signin_authorized?(ROTP::TOTP.new(@seed).now)
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
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

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
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    end

    should "return true if instance owns a gem that exceeds recommended threshold and has mfa ui_only" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_recommended_weak_level_enabled?
    end

    should "return false if instance owns a gem that exceeds recommended threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.disable_totp!

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
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

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
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_only)
    end

    should "return true if instance owns a gem that exceeds required threshold and has mfa ui_only" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)

      assert_predicate @user, :mfa_required_weak_level_enabled?
    end

    should "return false if instance owns a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: @popular_rubygem)
      @user.disable_totp!

      refute_predicate @user, :mfa_required_weak_level_enabled?
    end

    should "return false if instance does not own a gem that exceeds required threshold and has mfa disabled" do
      create(:ownership, user: @user, rubygem: create(:rubygem))

      refute_predicate @user, :mfa_required_weak_level_enabled?
    end
  end

  context "#ui_mfa_verified?" do
    setup do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
    end

    context "with totp" do
      should "return true when correct" do
        assert @user.ui_mfa_verified?(ROTP::TOTP.new(@user.mfa_seed).now)
      end

      should "return true when correct in last interval" do
        last_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current - 30)

        assert @user.ui_mfa_verified?(last_otp)
      end

      should "return true when correct in next interval" do
        next_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current + 30)

        assert @user.ui_mfa_verified?(next_otp)
      end

      should "return false when incorrect" do
        refute @user.ui_mfa_verified?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
      end

      should "return false if the mfa_seed is blank" do
        @user.disable_totp!

        refute @user.ui_mfa_verified?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
      end
    end

    context "with webauthn otp" do
      should "return false" do
        webauthn_verification = create(:webauthn_verification, user: @user)

        refute @user.ui_mfa_verified?(webauthn_verification.otp)
      end
    end

    should "return true if recovery code is correct" do
      recovery_code = @user.mfa_recovery_codes.first

      assert @user.ui_mfa_verified?(recovery_code)
      refute_includes @user.mfa_recovery_codes, recovery_code
    end
  end

  context "#api_mfa_verified?" do
    setup do
      @user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
    end

    context "with totp" do
      should "return true when correct" do
        assert @user.api_mfa_verified?(ROTP::TOTP.new(@user.mfa_seed).now)
      end

      should "return true when correct in last interval" do
        last_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current - 30)

        assert @user.api_mfa_verified?(last_otp)
      end

      should "return true when correct in next interval" do
        next_otp = ROTP::TOTP.new(@user.mfa_seed).at(Time.current + 30)

        assert @user.api_mfa_verified?(next_otp)
      end

      should "return false if otp is incorrect" do
        refute @user.api_mfa_verified?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
      end
    end

    context "with webauthn otp" do
      should "return true when correct" do
        webauthn_verification = create(:webauthn_verification, user: @user)

        assert @user.api_mfa_verified?(webauthn_verification.otp)
      end

      should "return false when incorrect" do
        create(:webauthn_verification, user: @user, otp: "jiEm2mm2sJtRqAVx")
        incorrect_otp = "Yxf57d1wEUSWyXrr"

        refute @user.api_mfa_verified?(incorrect_otp)
      end

      should "return false when expired" do
        webauthn_verification = create(:webauthn_verification, user: @user, otp_expires_at: 2.minutes.ago)

        refute @user.api_mfa_verified?(webauthn_verification.otp)
      end

      context "when webauthn otp has not been generated" do
        setup do
          create(:webauthn_verification, user: @user, otp: nil, otp_expires_at: nil)
        end

        should "return false for an otp" do
          refute @user.api_mfa_verified?("Yxf57d1wEUSWyXrr")
        end

        should "return false if otp is nil" do
          refute @user.api_mfa_verified?(nil)
        end
      end
    end

    should "return true if recovery code is correct" do
      recovery_code = @user.mfa_recovery_codes.first

      assert @user.api_mfa_verified?(recovery_code)
      refute_includes @user.mfa_recovery_codes, recovery_code
    end
  end

  context ".without_mfa" do
    setup do
      create(:user).enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
    end

    should "return instances without mfa" do
      user_without_mfa = User.without_mfa

      assert_equal 1, user_without_mfa.size
      assert_equal @user, user_without_mfa.first
    end
  end
end
