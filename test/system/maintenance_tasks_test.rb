require "application_system_test_case"

class MaintenanceTasksTest < ApplicationSystemTestCase
  make_my_diffs_pretty!

  include ActiveJob::TestHelper

  def sign_in_as(user)
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "1",
      credentials: {
        token: user.oauth_token,
        expires: false
      },
      info: {
        name: user.login
      }
    )

    stub_github_info_request(user.info_data)

    visit admin_maintenance_tasks.root_path
    click_button "Log in with GitHub"

    page.assert_text "Maintenance Tasks"
  end

  test "auditing create run" do
    admin_user = create(:admin_github_user, :is_admin)
    sign_in_as admin_user

    visit admin_maintenance_tasks.root_path
    click_on "Maintenance::UserTotpSeedEmptyToNilTask"

    assert_difference "Audit.count", 1 do
      assert_enqueued_jobs 1, only: MaintenanceTasks::TaskJob do
        click_on "Run"

        page.assert_text "Enqueued"
      end
    end

    audit = Audit.sole

    assert_equal admin_user, audit.admin_github_user
    assert_equal "Manual create of Maintenance::UserTotpSeedEmptyToNilTask", audit.action
    assert_equal MaintenanceTasks::Run.sole, audit.auditable

    visit avo.resources_audit_path(audit)

    page.assert_text "Manual create of Maintenance::UserTotpSeedEmptyToNilTask"
    page.assert_text MaintenanceTasks::Run.sole.job_id
  end
end
