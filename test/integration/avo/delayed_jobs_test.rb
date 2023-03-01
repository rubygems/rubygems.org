require "test_helper"

class Avo::DelayedJobsTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting users as admin" do
    admin_sign_in_as create(:admin_github_user, :is_admin)

    get avo.resources_delayed_jobs_path
    assert_response :success

    delayed_job = Fastly.delay.purge({ path: "path", soft: true })

    get avo.resources_delayed_jobs_path
    assert_response :success
    assert page.has_content? delayed_job.name

    get avo.resources_delayed_job_path(delayed_job)
    assert_response :success
    assert page.has_content? delayed_job.name
  end
end
