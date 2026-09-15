# frozen_string_literal: true

require "application_system_test_case"

class Avo::EmailDomainAllowlistSystemTest < ApplicationSystemTestCase
  test "allowlist email domain — creates an audited entry" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    visit avo.resources_email_domain_allowlists_path

    click_button "Actions"
    click_on "Allowlist Email Domain"

    fill_in "Domain", with: "privaterelay.appleid.com"
    fill_in "Notes", with: "Apple Hide-My-Email forwarding"
    fill_in "Comment", with: "Allowing forwarding service per ops review 2026-05"
    click_button "Allowlist Email Domain"

    page.assert_text "Action ran successfully!"

    allowed = EmailDomainAllowlist.find_by!(domain: "privaterelay.appleid.com")

    assert_equal "Apple Hide-My-Email forwarding", allowed.notes

    audit = allowed.audits.sole

    assert_equal "Allowlist Email Domain", audit.action
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Allowing forwarding service per ops review 2026-05", audit.comment
  end

  test "remove from allowlist — destroys an entry with an audit" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    allowed = create(:email_domain_allowlist, domain: "expired.example.com")
    allowed_id = allowed.id

    visit avo.resources_email_domain_allowlist_path(allowed)

    click_button "Actions"
    click_on "Remove from Allowlist"

    fill_in "Comment", with: "Service shut down, removing exemption"
    click_button "Remove from Allowlist"

    page.assert_text "Action ran successfully!"

    refute EmailDomainAllowlist.exists?(allowed_id)

    audit = Audit.where(
      auditable_type: "EmailDomainAllowlist",
      auditable_id: allowed_id,
      action: "Remove from Allowlist"
    ).sole

    assert_equal admin_user, audit.admin_github_user
    assert_equal "Service shut down, removing exemption", audit.comment
  end
end
