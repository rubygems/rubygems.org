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
end
