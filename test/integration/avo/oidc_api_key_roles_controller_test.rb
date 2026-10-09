# frozen_string_literal: true

require "test_helper"

class Avo::OIDCApiKeyRolesControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting api key roles as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_oidc_api_key_roles_path

    assert_response :success

    oidc_api_key_role = create(:oidc_api_key_role)

    get avo.resources_oidc_api_key_roles_path

    assert_response :success
    page.assert_text oidc_api_key_role.name

    get avo.resources_oidc_api_key_role_path(oidc_api_key_role)

    assert_response :success
    page.assert_text oidc_api_key_role.name
  end

  test "editing an api key role as admin only allows changing the conditions" do
    requires_avo_pro # the edit form renders the searchable user association

    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)

    get avo.edit_resources_oidc_api_key_role_path(oidc_api_key_role)

    assert_response :success

    [
      "[token]",
      "[name]",
      "[oidc_provider_id]",
      "[api_key_permissions][valid_for]",
      "[api_key_permissions][scopes]",
      "[api_key_permissions][gems]",
      "[access_policy][statements][0][effect]",
      "[access_policy][statements][0][principal][oidc]"
    ].each do |name|
      assert_select "[name='oidc/api_key_role#{name}'][disabled]", minimum: 1
    end

    %w[operator claim value].each do |name|
      input = "[name='oidc/api_key_role[access_policy][statements][0][conditions][0][#{name}]']"

      assert_select input, count: 1
      assert_select "#{input}[disabled]", count: 0
    end

    assert_select "a", text: /Add another Condition/
    assert_select "a", text: /Add another Statement/, count: 0
    assert_select "a", text: /Remove Statement/, count: 0
  end

  test "updating the conditions of an api key role as admin" do
    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin
    oidc_api_key_role = create(:oidc_api_key_role)

    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Also allow pushes from the release workflow",
        access_policy: {
          statements: {
            "0" => {
              conditions: {
                "0" => { operator: "string_equals", claim: "sub", value: "repo:fakeuser/oidc-test:ref:refs/heads/main" },
                # Conditions added on the form get a timestamp for an index
                "1759881600000" => {
                  operator: "string_matches", claim: "workflow_ref", value: "fakeuser/oidc-test/.github/workflows/release.yml@.*"
                }
              }
            }
          }
        }
      }
    }

    audit = Audit.sole

    assert_redirected_to avo.resources_audit_path(audit)

    statement = oidc_api_key_role.reload.access_policy.statements.sole

    assert_equal "allow", statement.effect
    assert_equal oidc_api_key_role.provider.issuer, statement.principal.oidc
    assert_equal [
      %w[string_equals sub repo:fakeuser/oidc-test:ref:refs/heads/main],
      %w[string_matches workflow_ref fakeuser/oidc-test/.github/workflows/release.yml@.*]
    ], statement.conditions.map { [it.operator, it.claim, it.value] }

    assert_equal admin, audit.admin_github_user
    assert_equal oidc_api_key_role, audit.auditable
    assert_equal "Manual update of OIDC::ApiKeyRole", audit.action
    assert_equal "Also allow pushes from the release workflow", audit.comment

    changes = audit.audited_changes.dig("records", oidc_api_key_role.to_global_id.uri.to_s, "changes")

    assert_equal %w[access_policy updated_at], changes.keys.sort
    assert_equal [
      { "operator" => "string_equals", "claim" => "sub", "value" => "repo:fakeuser/oidc-test:ref:refs/heads/main" },
      { "operator" => "string_matches", "claim" => "workflow_ref", "value" => "fakeuser/oidc-test/.github/workflows/release.yml@.*" }
    ], changes.dig("access_policy", 1, "statements", 0, "conditions")
  end

  test "updating an api key role as admin ignores everything but the conditions" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes
    other_user = create(:user)
    other_provider = create(:oidc_provider)

    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Trying to change more than the conditions",
        id: oidc_api_key_role.id + 1,
        token: "rg_oidc_akr_11111111111111111111",
        name: "Renamed by an admin",
        oidc_provider_id: other_provider.id,
        user_id: other_user.id,
        deleted_at: Time.current,
        api_key_permissions: { valid_for: "PT1H", scopes: %w[yank_rubygem], gems: [] },
        access_policy: {
          statements: {
            "0" => {
              effect: "deny",
              principal: { oidc: "https://attacker.example.com" },
              conditions: {
                "0" => { operator: "string_equals", claim: "sub", value: "repo:fakeuser/oidc-test:ref:refs/heads/release" }
              }
            },
            "1" => {
              effect: "allow",
              principal: { oidc: oidc_api_key_role.provider.issuer },
              conditions: {
                "0" => { operator: "string_matches", claim: "sub", value: ".*" }
              }
            }
          }
        }
      }
    }

    audit = Audit.sole

    assert_redirected_to avo.resources_audit_path(audit)

    oidc_api_key_role = OIDC::ApiKeyRole.find(oidc_api_key_role.id)
    statement = oidc_api_key_role.access_policy.statements.sole

    assert_equal "allow", statement.effect
    assert_equal oidc_api_key_role.provider.issuer, statement.principal.oidc
    assert_equal [%w[string_equals sub repo:fakeuser/oidc-test:ref:refs/heads/release]],
      statement.conditions.map { [it.operator, it.claim, it.value] }
    assert_equal attributes.except("access_policy", "updated_at"), oidc_api_key_role.attributes.except("access_policy", "updated_at")

    assert_equal %w[access_policy], audit.audited_changes["fields"].keys
    assert_equal %w[access_policy updated_at], audit.audited_changes.dig("records", oidc_api_key_role.to_global_id.uri.to_s, "changes").keys.sort
  end

  test "rejected updates of an api key role as admin leave it untouched" do
    requires_avo_pro # the edit form is rendered again on failure

    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes

    # Without a sufficiently detailed comment
    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "typo",
        access_policy: {
          statements: { "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: ".*" } } } }
        }
      }
    }

    assert_response :unprocessable_entity
    page.assert_text "must supply a sufficiently detailed comment"

    # With conditions the role does not validate with
    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Restricting the role to a claim the provider does not have",
        access_policy: {
          statements: { "0" => { conditions: { "0" => { operator: "string_equals", claim: "unknown_claim", value: "anything" } } } }
        }
      }
    }

    assert_response :unprocessable_entity
    page.assert_text "unknown for the provider"

    assert_empty Audit.all
    assert_equal attributes, OIDC::ApiKeyRole.find(oidc_api_key_role.id).attributes
  end

  test "not updating an api key role as an operator outside the rubygems.org team" do
    requires_avo_pro

    admin = create(:admin_github_user, :is_admin)
    info_data = admin.info_data.deep_dup
    info_data[:viewer][:organization][:teams][:edges].reject! { |edge| edge.dig(:node, :slug) == "rubygems-org" }
    admin.update!(info_data:)
    admin_sign_in_as admin
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes

    get avo.edit_resources_oidc_api_key_role_path(oidc_api_key_role)

    assert_redirected_to avo.root_path

    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Trying to change the conditions without being allowed to",
        access_policy: {
          statements: { "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: ".*" } } } }
        }
      }
    }

    assert_redirected_to avo.root_path
    assert_empty Audit.all
    assert_equal attributes, OIDC::ApiKeyRole.find(oidc_api_key_role.id).attributes
  end

  test "not creating or destroying api key roles as admin" do
    requires_avo_pro

    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)

    get avo.new_resources_oidc_api_key_role_path

    assert_redirected_to avo.root_path

    assert_no_difference -> { OIDC::ApiKeyRole.count } do
      post avo.resources_oidc_api_key_roles_path, params: {
        "oidc/api_key_role" => { comment: "Trying to create a role from the admin" }
      }
    end

    assert_redirected_to avo.root_path

    delete avo.resources_oidc_api_key_role_path(oidc_api_key_role)

    assert_redirected_to avo.root_path
    assert_predicate OIDC::ApiKeyRole.where(id: oidc_api_key_role.id), :exists?
    assert_empty Audit.all
  end
end
