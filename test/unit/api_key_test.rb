require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  should belong_to :user
  should validate_presence_of(:name)
  should validate_presence_of(:user)
  should validate_presence_of(:hashed_key)

  should "be valid with factory" do
    assert build(:api_key).valid?
  end

  should "be invalid when name is empty string" do
    api_key = build(:api_key, name: "")
    refute api_key.valid?
    assert_contains api_key.errors[:name], "can't be blank"
  end

  should "be invalid when name is longer than Gemcutter::MAX_FIELD_LENGTH" do
    api_key = build(:api_key, name: "aa" * Gemcutter::MAX_FIELD_LENGTH)
    refute api_key.valid?
    assert_contains api_key.errors[:name], "is too long (maximum is 255 characters)"
  end

  context "#scope" do
    setup do
      @api_key = create(:api_key, index_rubygems: true, push_rubygem: true)
    end

    should "return enabled scopes" do
      assert_equal %i[index_rubygems push_rubygem], @api_key.enabled_scopes
    end
  end

  context "show_dashboard scope" do
    should "be valid when enabled exclusively" do
      assert build(:api_key, show_dashboard: true).valid?
    end

    should "be invalid when enabled with any other scope" do
      refute build(:api_key, show_dashboard: true, push_rubygem: true).valid?
    end
  end

  context "#mfa_enabled?" do
    setup do
      @api_key = create(:api_key, index_rubygems: true)
    end

    should "return false with MFA disabled user" do
      refute @api_key.mfa_enabled?

      @api_key.update(mfa: true)
      refute @api_key.mfa_enabled?
    end

    should "return mfa with MFA UI enabled user" do
      @api_key.user.enable_mfa!(ROTP::Base32.random_base32, :ui_only)
      refute @api_key.mfa_enabled?

      @api_key.update(mfa: true)
      assert @api_key.mfa_enabled?
    end

    should "return true with MFA UI and API enabled user" do
      @api_key.user.enable_mfa!(ROTP::Base32.random_base32, :ui_and_api)
      assert @api_key.mfa_enabled?

      @api_key.update(mfa: true)
      assert @api_key.mfa_enabled?
    end
  end
end
