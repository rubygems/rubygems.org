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

  test "for_rubygem scope" do
    user = @role.user
    rubygem = create(:rubygem, owners: [user])
    rubygem_role = create(:oidc_api_key_role, api_key_permissions: { gems: [rubygem.name], scopes: ["push_rubygem"] }, user:)
    create(:oidc_api_key_role, api_key_permissions: { gems: [create(:rubygem, owners: [user]).name], scopes: ["push_rubygem"] }, user:)
    empty_gems = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: ["push_rubygem"] }, user:)
    nil_gems = create(:oidc_api_key_role, api_key_permissions: { gems: nil, scopes: ["push_rubygem"] }, user:)

    assert_equal [rubygem_role], OIDC::ApiKeyRole.for_rubygem(rubygem).to_a
    assert_equal [@role, empty_gems, nil_gems], OIDC::ApiKeyRole.for_rubygem(nil).to_a
  end

  test "for_scope scope" do
    role1 = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: %w[push_rubygem yank_rubygem] })
    role2 = create(:oidc_api_key_role, api_key_permissions: { gems: [], scopes: ["push_rubygem"] })

    assert_equal [role1, role2], OIDC::ApiKeyRole.for_scope("push_rubygem").to_a
    assert_equal [role1], OIDC::ApiKeyRole.for_scope("yank_rubygem").to_a
    assert_predicate OIDC::ApiKeyRole.for_scope("show_dashboard"), :none?
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

    assert_equal ["unknown for the provider"], @role.errors.messages[:"access_policy.statements[0].conditions[0].claim"]
  end

  test "validates nested models" do
    @role.access_policy.statements = [OIDC::AccessPolicy::Statement.new(
      principal: { oidc: nil }
    )]
    @role.provider = nil
    @role.validate

    assert_equal ["can't be blank"], @role.errors.messages[:"access_policy.statements[0].principal.oidc"]
  end
end
