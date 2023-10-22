require "test_helper"

class OIDC::ApiKeyPermissionsTest < ActiveSupport::TestCase
  make_my_diffs_pretty!

  should validate_presence_of :scopes
  should validate_presence_of :valid_for

  test "validates scopes are known" do
    permissions = OIDC::ApiKeyPermissions.new(scopes: ["unknown"])
    permissions.validate

    assert_equal ["unknown scope: unknown"], permissions.errors.messages[:"scopes[0]"]
  end

  test "validates scopes are unique" do
    permissions = OIDC::ApiKeyPermissions.new(scopes: %w[openid openid])
    permissions.validate

    assert_equal ["must be unique"], permissions.errors.messages[:scopes]
  end

  test "validates gems has maximum length of 1" do
    permissions = OIDC::ApiKeyPermissions.new(gems: %w[a b])
    permissions.validate

    assert_equal ["may include at most 1 gem"], permissions.errors.messages[:gems]
  end
end
