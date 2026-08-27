# frozen_string_literal: true

require "application_system_test_case"

class Avo::AdvisoriesSystemTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  test "sync advisories from the index" do
    Advisory::OSV::Fetcher.any_instance.expects(:fetch).never

    admin_user = create(:admin_github_user, :is_admin)
    avo_sign_in_as admin_user

    visit avo.resources_advisories_path

    click_button "Actions"
    click_on "Sync Advisories"

    select "OSV", from: "Source"
    fill_in "Comment", with: "Warming the advisories table before enabling the public flag"
    click_button "Sync"

    page.assert_text "Advisory sync job scheduled"
    page.assert_text "Sync Advisories"

    assert_enqueued_jobs 1, only: SyncAdvisoriesJob
    assert_enqueued_with(job: SyncAdvisoriesJob, args: [source: "Advisory::OSV", force: true])

    audit = Audit.where(action: "Sync Advisories").sole

    assert_equal admin_user, audit.admin_github_user
    assert_equal admin_user, audit.auditable
    assert_equal "Warming the advisories table before enabling the public flag", audit.comment
  end
end
