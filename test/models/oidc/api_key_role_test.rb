require "test_helper"

class OIDC::ApiKeyRoleTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should belong_to :provider
  should belong_to :user
  should have_many :id_tokens
  should validate_presence_of :api_key_permissions
  should validate_presence_of :access_policy

  setup do
    @role = build(:oidc_api_key_role)
  end

  test "inspect with nested attributes" do
    assert_match "string_equals", @role.inspect
  end

  test "pretty_inspect with nested attributes" do
    assert_match "string_equals", @role.pretty_inspect
  end

  test "validates gems belong to the user" do
    @role.api_key_permissions.gems = ["does_not_exist"]
    @role.validate

    assert_equal ["(does_not_exist) does not belong to user #{@role.user.handle}"], @role.errors.messages[:"api_key_permissions.gems[0]"]
  end

  test "validates condition claims are known" do
    @role.access_policy.statements = [OIDC::AccessPolicy::Statement.new(
      effect: "allow",
      conditions: [
        { operator: "string_equals", claim: "unknown", value: "" }
      ],
      principal: { oidc: "" }
    )]
    @role.validate

    assert_equal ["unknown claim for the provider"], @role.errors.messages[:"access_policy.statements[0].conditions[0].claim"]
  end

  test "validates nested models" do
    @role.access_policy.statements = [OIDC::AccessPolicy::Statement.new(
      principal: { oidc: nil }
    )]
    @role.validate

    assert_equal ["can't be blank"], @role.errors.messages[:"access_policy.statements[0].principal.oidc"]
  end
end
