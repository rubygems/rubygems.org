require "test_helper"

class WebauthnVerificationTest < ActiveSupport::TestCase
  subject { build(:webauthn_verification) }

  should belong_to :user

  should validate_uniqueness_of(:user_id)
  should validate_presence_of(:path_token)
  should validate_uniqueness_of(:path_token)
  should validate_presence_of(:path_token_expires_at)

  context "#expire_path_token" do
    setup do
      travel_to Time.utc(2023, 1, 1, 0, 0, 0) do
        user = create(:user)
        @verification = create(:webauthn_verification, user: user)
      end
    end

    should "set the path_token_expires_at to 1 second ago" do
      travel_to Time.utc(2023, 1, 1, 0, 1, 0) do
        @verification.expire_path_token

        assert_equal Time.utc(2023, 1, 1, 0, 0, 59), @verification.path_token_expires_at
      end
    end
  end

  context "#path_token_expired?" do
    setup do
      travel_to Time.utc(2023, 1, 1, 0, 0, 0) do
        user = create(:user)
        @verification = create(:webauthn_verification, user: user)
      end
    end

    context "when the token is still live" do
      should "return false" do
        travel_to Time.utc(2023, 1, 1, 0, 0, 1) do
          refute_predicate @verification, :path_token_expired?
        end
      end
    end

    context "when the token has expired" do
      should "return true" do
        travel_to Time.utc(2023, 9, 9, 9, 9, 9) do
          assert_predicate @verification, :path_token_expired?
        end
      end
    end
  end

  context "#generate_otp" do
    setup do
      @webauthn_verification = create(:webauthn_verification, otp: nil, otp_expires_at: nil)
      @generated_time = Time.utc(2023, 1, 1, 0, 0, 0)
      travel_to @generated_time do
        @webauthn_verification.generate_otp
      end
      @webauthn_verification.reload
    end

    should "create a token that is 16 characters long" do
      assert_equal 16, @webauthn_verification.otp.length
    end

    should "set a 2 minute expiry" do
      assert_equal @generated_time + 2.minutes, @webauthn_verification.otp_expires_at
    end
  end

  context "#verify_otp" do
    setup do
      @user = create(:user)
      @current_time = Time.utc(2023, 1, 1, 0, 1, 0)
      travel_to @current_time
      freeze_time
    end

    context "when otp is correct and not expired" do
      setup do
        @verification = create(:webauthn_verification, user: @user)
      end

      should "return true" do
        assert @verification.verify_otp(@verification.otp)
      end

      should "update otp expiry to 1 second in the past" do
        @verification.verify_otp(@verification.otp)

        assert_equal @current_time - 1.second, @verification.otp_expires_at
      end
    end

    context "when otp is incorrect" do
      setup do
        @expires_at = 2.minutes.from_now
        @verification = create(:webauthn_verification, user: @user, otp: "jiEm2mm2sJtRqAVx7U1i", otp_expires_at: @expires_at)
      end

      should "return false" do
        refute @verification.verify_otp("Yxf57d1wEUSWyXrrLMRv")
      end

      should "not update expiry" do
        @verification.verify_otp("Yxf57d1wEUSWyXrrLMRv")

        assert_equal @expires_at, @verification.otp_expires_at
      end
    end

    context "when otp is expired" do
      setup do
        @expires_at = @current_time - 1.minute
        @verification = create(:webauthn_verification, user: @user, otp_expires_at: @expires_at)
      end

      should "return false" do
        refute @verification.verify_otp(@verification.otp)
      end

      should "not update expiry" do
        @verification.verify_otp(@verification.otp)

        assert_equal @expires_at, @verification.otp_expires_at
      end
    end

    context "when webauthn otp has not been generated" do
      setup do
        @verification = create(:webauthn_verification, user: @user, otp: nil, otp_expires_at: nil)
      end

      context "with a nil otp" do
        should "return false" do
          refute @verification.verify_otp(nil)
        end

        should "not update expiry" do
          @verification.verify_otp(nil)

          assert_nil @verification.otp_expires_at
        end
      end

      context "with a non nil otp" do
        should "return false" do
          refute @verification.verify_otp("Yxf57d1wEUSWyXrrLMRv")
        end

        should "not update expiry" do
          @verification.verify_otp("Yxf57d1wEUSWyXrrLMRv")

          assert_nil @verification.otp_expires_at
        end
      end
    end

    teardown do
      travel_back
    end
  end
end
