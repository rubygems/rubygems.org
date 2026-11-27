# frozen_string_literal: true

require "test_helper"

class OIDC::IdTokenTest < ActiveSupport::TestCase
  should belong_to :api_key_role
  should belong_to :api_key
  should have_one(:provider)
  should have_one(:user)

  should validate_presence_of :jwt

  test "validates jti uniqueness" do
    api_key_role = FactoryBot.create(:oidc_api_key_role)
    id_token = FactoryBot.create(:oidc_id_token, api_key_role:)
    assert_raises(ActiveRecord::RecordInvalid) do
      FactoryBot.create(:oidc_id_token, provider: id_token.provider, jwt: id_token.jwt, api_key_role:)
    end
  end

  test "validates jti uniqueness across a provider's roles" do
    api_key_role = FactoryBot.create(:oidc_api_key_role)
    other_role = FactoryBot.create(:oidc_api_key_role, provider: api_key_role.provider)
    FactoryBot.create(:oidc_id_token, api_key_role:, jti: "dupe-jti")

    duplicate = FactoryBot.build(:oidc_id_token, api_key_role: other_role, jti: "dupe-jti")

    refute_predicate duplicate, :valid?
    assert_includes duplicate.errors.attribute_names, :"jwt.claims.jti"
  end

  test "enforces jti uniqueness across a provider's roles at the database level" do
    api_key_role = FactoryBot.create(:oidc_api_key_role)
    other_role = FactoryBot.create(:oidc_api_key_role, provider: api_key_role.provider)
    FactoryBot.create(:oidc_id_token, api_key_role:, jti: "dupe-jti")

    duplicate = FactoryBot.build(
      :oidc_id_token,
      api_key_role: other_role,
      api_key: FactoryBot.create(:api_key, owner: other_role.user),
      jti: "dupe-jti"
    )

    assert_raises(ActiveRecord::RecordNotUnique) { duplicate.save!(validate: false) }
  end

  test "allows the same jti from another provider" do
    id_token = FactoryBot.create(:oidc_id_token, jti: "shared-jti")
    other = FactoryBot.create(:oidc_id_token, jti: "shared-jti")

    refute_equal id_token.provider, other.provider
    assert_predicate other, :persisted?
  end

  test "requires a jti claim" do
    id_token = FactoryBot.build(:oidc_id_token, jti: nil)

    refute_predicate id_token, :valid?
    assert_includes id_token.errors.attribute_names, :jti
  end

  test "#to_json" do
    id_token = FactoryBot.create(:oidc_id_token)

    assert_equal id_token.payload.to_json, id_token.to_json
  end

  test "#to_xml" do
    id_token = FactoryBot.create(:oidc_id_token)

    assert_equal id_token.payload.to_xml(root: "oidc:id_token"), id_token.to_xml
  end

  test "#to_yaml" do
    id_token = FactoryBot.create(:oidc_id_token)

    assert_equal id_token.payload.to_yaml, id_token.to_yaml
  end
end
