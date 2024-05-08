require "test_helper"

class ApiKeyTest < ActiveSupport::TestCase
  should belong_to :owner
  should validate_presence_of(:name)
  should validate_presence_of(:hashed_key)
  should have_one(:api_key_rubygem_scope).dependent(:destroy)

  should "be valid with factory" do
    assert_predicate build(:api_key), :valid?
  end

  should "set owner to user by default" do
    api_key = create(:api_key)

    assert_equal api_key.user, api_key.owner
  end

  should "be invalid when name is empty string" do
    api_key = build(:api_key, name: "")

    refute_predicate api_key, :valid?
    assert_contains api_key.errors[:name], "can't be blank"
  end

  should "be invalid when name is longer than Gemcutter::MAX_FIELD_LENGTH" do
    api_key = build(:api_key, name: "aa" * Gemcutter::MAX_FIELD_LENGTH)

    refute_predicate api_key, :valid?
    assert_contains api_key.errors[:name], "is too long (maximum is 255 characters)"
  end

  context "#scope" do
    setup do
      @api_key = create(:api_key, scopes: %i[index_rubygems push_rubygem])
    end

    should "return enabled scopes" do
      assert_equal %i[index_rubygems push_rubygem], @api_key.scopes
    end
  end

  context "show_dashboard scope" do
    should "be valid when enabled exclusively" do
      assert_predicate build(:api_key, scopes: %i[show_dashboard]), :valid?
    end

    should "be invalid when enabled with any other scope" do
      refute_predicate build(:api_key, scopes: %i[show_dashboard push_rubygem]), :valid?
    end
  end

  context "gem scope" do
    setup do
      @ownership = create(:ownership)
      @api_key = create(:api_key, scopes: %w[push_rubygem], owner: @ownership.user, ownership: @ownership)
      @api_key_no_gem_scope = create(:api_key, key: SecureRandom.hex(24), scopes: %i[index_rubygems], owner: @ownership.user)
    end

    should "be invalid if non applicable API scope is enabled" do
      api_key = build(:api_key, scopes: %w[index_rubygems], owner: @ownership.user, ownership: @ownership)

      refute_predicate api_key, :valid?
      assert_contains api_key.errors[:rubygem], "scope can only be set for push/yank rubygem, and add/remove owner scopes"
    end

    should "be valid if applicable API scope is enabled" do
      %i[push_rubygem yank_rubygem add_owner remove_owner].each do |scope|
        api_key = build(:api_key, scopes: [scope], owner: @ownership.user, ownership: @ownership)

        assert_predicate api_key, :valid?
      end
    end

    context "#rubygem" do
      should "return scoped rubygem when present" do
        assert_equal @ownership.rubygem, @api_key.rubygem
      end

      should "return nil when scope is not defined" do
        assert_nil @api_key_no_gem_scope.rubygem
      end
    end

    context "#rubygem_id" do
      should "return scoped rubygem id when present" do
        assert_equal @ownership.rubygem_id, @api_key.rubygem_id
      end

      should "return nil when scope is not defined" do
        assert_nil @api_key_no_gem_scope.rubygem_id
      end
    end

    context "#rubygem_id=" do
      should "set ownership to a gem" do
        api_key = create(:api_key, key: SecureRandom.hex(24), scopes: %i[push_rubygem], owner: @ownership.user, rubygem_id: @ownership.rubygem_id)

        assert_equal @ownership.rubygem_id, api_key.rubygem_id
      end

      should "set ownership to nil when id is nil" do
        @api_key.rubygem_id = nil

        assert_nil @api_key.rubygem_id
      end

      should "add error when id is not associated with the user" do
        api_key = ApiKey.new(hashed_key: SecureRandom.hex(24), scopes: %i[push_rubygem], owner: @ownership.user, rubygem_id: -1)

        assert_contains api_key.errors[:rubygem], "must be a gem that you are an owner of"
      end
    end

    context "#rubygem_name=" do
      should "set ownership to a gem" do
        api_key = create(
          :api_key,
          key: SecureRandom.hex(24),
          scopes: %i[push_rubygem],
          owner: @ownership.user,
          rubygem_name: @ownership.rubygem.name
        )

        assert_equal @ownership.rubygem, api_key.rubygem
      end

      should "set ownership to nil when name is blank" do
        @api_key.rubygem_name = nil

        assert_nil @api_key.ownership
      end

      should "add error when gem is not associated with the user" do
        rubygem = create(:rubygem, name: "another-gem")
        api_key = ApiKey.new(
          hashed_key: SecureRandom.hex(24),
          scopes: %i[push_rubygem],
          owner: @ownership.user,
          rubygem_name: rubygem.name
        )

        assert_contains api_key.errors[:rubygem], "must be a gem that you are an owner of"
      end

      should "add error when name is not a valid gem name" do
        api_key = ApiKey.new(
          hashed_key: SecureRandom.hex(24),
          scopes: %i[push_rubygem],
          owner: @ownership.user,
          rubygem_name: "invalid-gem-name"
        )

        assert_contains api_key.errors[:rubygem], "could not be found"
      end
    end
  end

  context "#soft_deleted?" do
    should "return true if soft_deleted_at is set" do
      api_key = create(:api_key)
      api_key.soft_deleted_at = Time.now.utc

      assert_predicate api_key, :soft_deleted?
    end

    should "return false if soft_deleted_at is not set" do
      refute_predicate create(:api_key), :soft_deleted?
    end
  end

  context "#soft_delete!" do
    should "set soft_deleted_at" do
      api_key = create(:api_key)

      freeze_time do
        api_key.soft_delete!

        assert_equal Time.now.utc, api_key.soft_deleted_at
      end
    end
  end

  context "#soft_deleted_by_ownership?" do
    should "return true if soft deleted gem name is present" do
      ownership = create(:ownership)
      api_key = create(:api_key, scopes: %i[push_rubygem], owner: ownership.user, ownership: ownership)
      api_key.soft_delete!(ownership: ownership)

      assert_predicate api_key, :soft_deleted_by_ownership?
    end

    should "return false if key not soft deleted" do
      api_key = create(:api_key)

      refute_predicate api_key, :soft_deleted_by_ownership?
    end
  end

  should "be invalid if soft deleted" do
    api_key = create(:api_key)
    api_key.soft_delete!

    refute_predicate api_key, :valid?
    assert_contains api_key.errors[:base], "An invalid API key cannot be used. Please delete it and create a new one."
  end

  should "be invalid if expired" do
    api_key = create(:api_key, expires_at: 10.minutes.from_now)

    travel 20.minutes

    refute_predicate api_key, :valid?
    assert_contains api_key.errors[:base], "An expired API key cannot be used. Please create a new one."
  end

  context "#mfa_authorized?" do
    setup do
      @api_key = create(:api_key)
    end

    should "return true if mfa not enabled for api key" do
      @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)

      assert @api_key.mfa_authorized?(nil)
    end

    context "with totp" do
      should "return true when correct and mfa enabled" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

        assert @api_key.mfa_authorized?(ROTP::TOTP.new(@api_key.user.totp_seed).now)
      end

      should "return false when incorrect and mfa enabled" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

        refute @api_key.mfa_authorized?(ROTP::TOTP.new(ROTP::Base32.random_base32).now)
      end
    end

    context "with webauthn otp" do
      should "return true when correct and mfa enabled" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        webauthn_verification = create(:webauthn_verification, user: @api_key.user)

        assert @api_key.mfa_authorized?(webauthn_verification.otp)
      end

      should "return false when incorrect and mfa enabled" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)
        create(:webauthn_verification, user: @api_key.user, otp: "jiEm2mm2sJtRqAVx7U1i")
        incorrect_otp = "Yxf57d1wEUSWyXrrLMRv"

        refute @api_key.mfa_authorized?(incorrect_otp)
      end
    end

    context "with oidc id token" do
      setup do
        create(:oidc_id_token, api_key: @api_key)
      end

      should "return true if mfa not enabled for api key" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_gem_signin)

        assert @api_key.mfa_authorized?(nil)
      end

      should "return true if mfa enabled for api" do
        @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

        assert @api_key.mfa_authorized?(nil)
      end

      should "return true if mfa enabled for api key" do
        @api_key.update!(mfa: true)

        assert @api_key.mfa_authorized?(nil)
      end
    end
  end

  context "#mfa_enabled?" do
    setup do
      @api_key = create(:api_key, scopes: %i[index_rubygems])
    end

    should "return false with MFA disabled user" do
      refute_predicate @api_key, :mfa_enabled?

      @api_key.update(mfa: true)

      refute_predicate @api_key, :mfa_enabled?
    end

    should "return mfa with MFA UI enabled user" do
      @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_only)

      refute_predicate @api_key, :mfa_enabled?

      @api_key.update(mfa: true)

      assert_predicate @api_key, :mfa_enabled?
    end

    should "return true with MFA UI and API enabled user" do
      @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

      assert_predicate @api_key, :mfa_enabled?

      @api_key.update(mfa: true)

      assert_predicate @api_key, :mfa_enabled?
    end

    should "return false with MFA UI and API enabled user & short duration token" do
      @api_key.user.enable_totp!(ROTP::Base32.random_base32, :ui_and_api)

      [false, true].each do |mfa|
        @api_key.update(mfa: mfa, expires_at: @api_key.created_at + 14.minutes)

        refute_predicate @api_key, :mfa_enabled?

        @api_key.update(mfa: mfa, expires_at: @api_key.created_at + 15.minutes)

        assert_predicate @api_key, :mfa_enabled?
      end
    end
  end
end
