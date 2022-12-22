require "test_helper"

class UserWebauthnMethodsTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  context "create" do
    should "set webauthn_id" do
      refute_nil @user.webauthn_id
    end
  end

  context "#webauthn_options_for_create" do
    should "returns options with id, and name" do
      user_create_options = @user.webauthn_options_for_create.user
      assert_equal @user.name, user_create_options.display_name
      assert_equal @user.webauthn_id, user_create_options.id
    end

    should "return an empty list for exclude if user does not have any prior existing webauthn credentials" do
      create_options = @user.webauthn_options_for_create
      assert_empty create_options.exclude
    end

    should "exclude pre-existing webauthn credentials when creating a new one" do
      webauthn_credential = create(:webauthn_credential, user: @user)
      create_options = @user.webauthn_options_for_create
      assert_equal [webauthn_credential.external_id], create_options.exclude
    end
  end

  context "#webauthn_options_for_get" do
    setup do
      @webauthn_credential = create(:webauthn_credential, user: @user)
    end

    should "get prexisting webauthn credentials" do
      get_options = @user.webauthn_options_for_get
      assert_equal [@webauthn_credential.external_id], get_options.allow
    end
  end

  context "#refresh_webauthn_verification" do
    setup do
      travel_to Time.utc(2023, 1, 1, 0, 0, 0) do
        @webauthn_verification = @user.refresh_webauthn_verification
      end
    end

    should "create a token that is 16 characters long" do
      assert_equal 16, @webauthn_verification.path_token.length
    end

    should "set a 5 minute expiry" do
      assert_equal Time.utc(2023, 1, 1, 0, 5, 0), @webauthn_verification.path_token_expires_at
    end

    should "store a path token in the database" do
      assert_equal @user.webauthn_verification.path_token, @webauthn_verification.path_token
    end

    should "reset the token each time the method is called" do
      token_before = @webauthn_verification.path_token
      @user.refresh_webauthn_verification

      refute_equal token_before, @user.webauthn_verification.path_token
    end
  end
end
