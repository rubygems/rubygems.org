# frozen_string_literal: true

require "application_system_test_case"

class Avo::BlockedEmailDomainsSystemTest < ApplicationSystemTestCase
  test "block email domain — creates an audited manual entry" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    visit avo.resources_blocked_email_domains_path

    click_button "Actions"
    click_on "Block Email Domain"

    fill_in "Domain", with: "newly-disposable.example"
    fill_in "Notes", with: "reported by abuse team"
    click_button "Block Email Domain"
    page.assert_text "Must supply a sufficiently detailed comment"

    fill_in "Comment", with: "Reported by abuse team on 2026-05-15"
    click_button "Block Email Domain"

    page.assert_text "Action ran successfully!"

    blocked = BlockedEmailDomain.find_by!(domain: "newly-disposable.example")

    assert_predicate blocked, :manual?
    assert_equal "reported by abuse team", blocked.notes

    audit = blocked.audits.sole

    assert_equal "Block Email Domain", audit.action
    assert_equal admin_user, audit.admin_github_user
    assert_equal "Reported by abuse team on 2026-05-15", audit.comment
  end

  test "unblock email domain — destroys a manual entry with an audit" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    blocked = create(:blocked_email_domain, domain: "departing.example", notes: "old")
    blocked_id = blocked.id

    visit avo.resources_blocked_email_domain_path(blocked)

    click_button "Actions"
    click_on "Unblock Email Domain"

    fill_in "Comment", with: "Domain owner is now legitimate"
    click_button "Unblock Email Domain"

    page.assert_text "Action ran successfully!"

    refute BlockedEmailDomain.exists?(blocked_id)

    audit = Audit.where(
      auditable_type: "BlockedEmailDomain",
      auditable_id: blocked_id,
      action: "Unblock Email Domain"
    ).sole

    assert_equal admin_user, audit.admin_github_user
    assert_equal "Domain owner is now legitimate", audit.comment
  end

  test "unblock action is not available on upstream-sourced rows" do
    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    upstream_row = create(:blocked_email_domain, :upstream)

    visit avo.resources_blocked_email_domain_path(upstream_row)

    # No actions are available on upstream rows, so the Actions button is disabled.
    assert_no_text "Unblock Email Domain"
    assert_raises(Capybara::ElementNotFound) do
      find("button:not([disabled])", text: "Actions")
    end
  end
end
