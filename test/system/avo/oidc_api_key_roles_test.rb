# frozen_string_literal: true

require "application_system_test_case"

class Avo::OIDCApiKeyRolesSystemTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  # The wrapper of each condition on the form, with its remove link
  CONDITIONS = "[data-field-id='conditions'] .nested-form-wrapper[data-new-record]"

  test "changing the conditions of a role" do
    requires_avo_pro # the edit form renders the searchable user association

    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    role = create(:oidc_api_key_role)
    provider = role.provider

    visit avo.resources_oidc_api_key_role_path(role)
    click_on "Edit"

    # Only the conditions can be changed
    assert_field "Name", with: role.name, disabled: true
    assert_field "Valid for", with: "PT30M", disabled: true
    assert_selector :select, "oidc_api_key_role_access_policy_statements_0__effect", selected: "Allow", disabled: true
    assert_field "oidc_api_key_role_access_policy_statements_0__principal_oidc", with: provider.issuer, disabled: true
    assert_no_link "Add another Statement"
    assert_no_link "Remove Statement"

    select "String Matches", from: "oidc_api_key_role_access_policy_statements_0__conditions_0__operator"
    fill_in "oidc_api_key_role_access_policy_statements_0__conditions_0__value", with: "repo:fakeuser/oidc-test:ref:refs/heads/.*"

    click_on "Add another Condition"

    assert_css CONDITIONS, count: 2
    within all(CONDITIONS).last do
      find("select").select "String Equals"
      find("input[name$='[claim]']").set "repository"
      find("input[name$='[value]']").set "fakeuser/oidc-test"
    end

    fill_in "Comment", with: "Allow pushes from every branch of the repository"
    click_on "Save"

    page.assert_text "Manual update of OIDC::ApiKeyRole"
    page.assert_text "Allow pushes from every branch of the repository"

    audit = Audit.sole

    page.assert_text audit.id

    assert_equal role, audit.auditable
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Allow pushes from every branch of the repository", audit.comment

    statement = role.reload.access_policy.statements.sole

    assert_equal "allow", statement.effect
    assert_equal provider.issuer, statement.principal.oidc
    assert_equal [
      %w[string_matches sub repo:fakeuser/oidc-test:ref:refs/heads/.*],
      %w[string_equals repository fakeuser/oidc-test]
    ], statement.conditions.map { [it.operator, it.claim, it.value] }

    # Conditions can be removed too
    visit avo.resources_oidc_api_key_role_path(role)
    click_on "Edit"

    assert_css CONDITIONS, count: 2
    within all(CONDITIONS).last do
      click_on "Remove Condition"
    end

    assert_css CONDITIONS, count: 1

    fill_in "Comment", with: "The repository condition is redundant"
    click_on "Save"

    page.assert_text "The repository condition is redundant"

    assert_equal 2, Audit.count

    statement = role.reload.access_policy.statements.sole

    assert_equal "allow", statement.effect
    assert_equal provider.issuer, statement.principal.oidc
    assert_equal [%w[string_matches sub repo:fakeuser/oidc-test:ref:refs/heads/.*]],
      statement.conditions.map { [it.operator, it.claim, it.value] }
  end
end
