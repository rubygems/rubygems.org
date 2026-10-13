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
    conditions = statement.conditions.map { [it.operator, it.claim, it.value] }

    assert_equal "allow", statement.effect
    assert_equal oidc_api_key_role.provider.issuer, statement.principal.oidc
    assert_equal [
      %w[string_equals sub repo:fakeuser/oidc-test:ref:refs/heads/main],
      %w[string_matches workflow_ref fakeuser/oidc-test/.github/workflows/release.yml@.*]
    ], conditions

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

    event = oidc_api_key_role.user.events.where(tag: Events::UserEvent::OIDC_API_KEY_ROLE_ACCESS_POLICY_CHANGED).sole

    refute_predicate event.additional, :by_owner
    assert_equal oidc_api_key_role.to_global_id, event.additional.api_key_role_gid
    assert_equal [
      "sub string_equals repo:fakeuser/oidc-test:ref:refs/heads/main",
      "workflow_ref string_matches fakeuser/oidc-test/.github/workflows/release.yml@.*"
    ], event.additional.conditions
  end

  # NestedField#to_permitted_param permits every field it holds regardless of
  # `disabled`, so effect and principal do reach the controller and are stopped
  # only by merge_conditions. Pinned so widening it has to be deliberate.
  test "only the conditions of a statement are permitted beyond the fixed fields" do
    resource = Avo::Resources::OIDCApiKeyRole.new(record: create(:oidc_api_key_role), view: Avo::ViewInquirer.new("edit"))
    resource.detect_fields

    assert_equal [
      { access_policy: [statements: [:effect, { principal: [:oidc] }, { conditions: %i[operator claim value] }]] },
      :id_tokens,
      :comment
    ], resource.get_field_definitions.select(&:updatable).map(&:to_permitted_param)
  end

  # The update redirects to the audit, whose diff reads the access policy back
  # through the nested field.
  test "the audit page renders the access policy diff" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)

    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Pinning the role to the repository as well",
        access_policy: {
          statements: { "0" => { conditions: {
            "0" => { operator: "string_equals", claim: "sub", value: "repo:fakeuser/oidc-test:ref:refs/heads/main" }
          } } }
        }
      }
    }

    get avo.resources_audit_path(Audit.sole)

    assert_response :success
    page.assert_text "Access policy"
    page.assert_text "Conditions"
    page.assert_text "repo:segiddins/oidc-test:ref:refs/heads/main"
    page.assert_text "repo:fakeuser/oidc-test:ref:refs/heads/main"
  end

  test "updating an api key role as admin drops every field but the access policy" do
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
              conditions: {
                "0" => { operator: "string_equals", claim: "sub", value: "repo:fakeuser/oidc-test:ref:refs/heads/release" }
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
    conditions = statement.conditions.map { [it.operator, it.claim, it.value] }

    assert_equal "allow", statement.effect
    assert_equal oidc_api_key_role.provider.issuer, statement.principal.oidc
    assert_equal [%w[string_equals sub repo:fakeuser/oidc-test:ref:refs/heads/release]], conditions
    assert_equal attributes.except("access_policy", "updated_at"), oidc_api_key_role.attributes.except("access_policy", "updated_at")

    assert_equal %w[access_policy], audit.audited_changes["fields"].keys
    assert_equal %w[access_policy updated_at], audit.audited_changes.dig("records", oidc_api_key_role.to_global_id.uri.to_s, "changes").keys.sort
  end

  test "not changing the effect or principal of a statement as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes

    [
      { effect: "deny" },
      { principal: { oidc: "https://attacker.example.com" } }
    ].each do |crafted|
      patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
        "oidc/api_key_role" => {
          comment: "Trying to change the trust relationship itself",
          access_policy: {
            statements: {
              "0" => crafted.merge(
                conditions: { "0" => { operator: "string_matches", claim: "sub", value: ".*" } }
              )
            }
          }
        }
      }

      assert_response :unprocessable_entity
      page.assert_text "can only have their conditions changed"

      assert_empty Audit.all
      assert_equal attributes, OIDC::ApiKeyRole.find(oidc_api_key_role.id).attributes
    end
  end

  # Checked here as well as in the test that needs Avo Pro.
  test "not updating an api key role as admin without a detailed comment" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes
    policy = { statements: { "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: ".*" } } } } }

    [{ comment: "typo" }, { comment: "" }, {}].each do |comment|
      patch avo.resources_oidc_api_key_role_path(oidc_api_key_role),
        params: { "oidc/api_key_role" => comment.merge(access_policy: policy) }

      assert_response :unprocessable_entity
      page.assert_text "must supply a sufficiently detailed comment"

      assert_empty Audit.all
      assert_equal attributes, OIDC::ApiKeyRole.find(oidc_api_key_role.id).attributes
    end
  end

  # Statements are matched by position, so a form rendered against a policy that
  # has since changed would write onto a statement the admin never looked at.
  test "not updating an api key role as admin from a form rendered against a different policy" do
    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role, access_policy: {
                                 statements: [
                                   { effect: "allow",
conditions: [operator: "string_equals", claim: "sub", value: "repo:fakeuser/public:ref:refs/heads/main"] },
                                   { effect: "allow",
conditions: [operator: "string_equals", claim: "sub", value: "repo:fakeuser/secret:ref:refs/heads/main"] }
                                 ]
                               })
    attributes = oidc_api_key_role.reload.attributes

    # The form was rendered when the role had a single statement, so only one is submitted
    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Widening the public repository statement to all of its branches",
        access_policy: {
          statements: {
            "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: "repo:fakeuser/public:ref:refs/heads/.*" } } }
          }
        }
      }
    }

    assert_response :unprocessable_entity
    page.assert_text "may have changed since the form was opened"

    assert_empty Audit.all
    assert_equal attributes, OIDC::ApiKeyRole.find(oidc_api_key_role.id).attributes
  end

  test "rejected updates of an api key role as admin leave it untouched" do
    requires_avo_pro # the edit form is rendered again on failure

    admin_sign_in_as create(:admin_github_user, :is_admin)
    oidc_api_key_role = create(:oidc_api_key_role)
    attributes = oidc_api_key_role.reload.attributes

    ["typo", ""].each do |comment|
      patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
        "oidc/api_key_role" => {
          comment:,
          access_policy: {
            statements: { "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: ".*" } } } }
          }
        }
      }

      assert_response :unprocessable_entity
      page.assert_text "must supply a sufficiently detailed comment"
    end

    # A request that leaves the comment out entirely must not slip past the check
    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
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

    # With a pattern that does not compile
    patch avo.resources_oidc_api_key_role_path(oidc_api_key_role), params: {
      "oidc/api_key_role" => {
        comment: "Widening the role with a pattern I got wrong",
        access_policy: {
          statements: { "0" => { conditions: { "0" => { operator: "string_matches", claim: "sub", value: "repo:fakeuser/[" } } } }
        }
      }
    }

    assert_response :unprocessable_entity
    page.assert_text "is not a valid regular expression"

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
