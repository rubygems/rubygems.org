# frozen_string_literal: true

require "test_helper"

class Avo::OrganizationDomainsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  setup do
    @organization = create(:organization, name: "Acme Corp")
    @domain = create(:organization_domain, :verified, organization: @organization, domain: "acme.example.com")
    create(:organization_domain_check, :failure, organization_domain: @domain,
      outcome: "record_mismatch", message: "A TXT record exists at x but its value does not match.")
  end

  test "listing domains" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_organization_domains_path

    assert_response :success
    page.assert_text "acme.example.com"
  end

  test "showing a domain with its token and the delete action" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_organization_domain_path(@domain)

    assert_response :success
    page.assert_text "acme.example.com"
    page.assert_text "Acme Corp"
    page.assert_text @domain.token
    page.assert_text "Check queued at"
    page.assert_text "Delete Organization Domain"
  end

  test "listing check history including outcome and message" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_associations_index_path(
      resource_name: "organization_domains", id: @domain.id, related_name: "checks"
    )

    assert_response :success
    page.assert_text "record_mismatch"
    page.assert_text "A TXT record exists at x but its value does not match."
  end

  test "listing an organization's domains" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_associations_index_path(
      resource_name: "organizations", id: @organization.handle, related_name: "domains"
    )

    assert_response :success
    page.assert_text "acme.example.com"
  end

  test "domains cannot be created, edited or destroyed" do
    requires_avo_pro

    admin_sign_in_as create(:admin_github_user, :is_admin)

    assert_no_difference [-> { OrganizationDomain.count }, -> { Audit.count }] do
      get avo.new_resources_organization_domain_path

      assert_redirected_to avo.root_path

      get avo.edit_resources_organization_domain_path(@domain)

      assert_redirected_to avo.root_path

      patch avo.resources_organization_domain_path(@domain), params: { organization_domain: { token: "forged" } }

      assert_redirected_to avo.root_path

      delete avo.resources_organization_domain_path(@domain)

      assert_redirected_to avo.root_path
    end

    assert OrganizationDomain.exists?(@domain.id)
    refute_equal "forged", @domain.token
  end

  test "admins outside the rubygems.org team cannot see domains" do
    requires_avo_pro

    admin_sign_in_as admin_outside_rubygems_org_team

    get avo.resources_organization_domain_path(@domain)

    assert_redirected_to avo.root_path
    refute_match @domain.token, response.body
  end

  test "deleting a domain through the action as an admin outside the rubygems.org team is denied" do
    requires_avo_pro

    admin_sign_in_as admin_outside_rubygems_org_team
    attributes = @domain.attributes

    assert_no_difference [-> { Audit.count }, -> { Events::OrganizationEvent.count }] do
      post "/admin/resources/organization_domains/actions",
        params: {
          action_id: "Avo::Actions::DeleteOrganizationDomain",
          resource_view: "show",
          fields: { comment: "Deleting without permission" },
          id: @domain.id
        },
        as: :turbo_stream
    end

    assert_redirected_to avo.root_path
    assert_equal attributes, OrganizationDomain.find(@domain.id).attributes
    assert_empty Audit.where(action: "Delete Organization Domain")
  end
end
