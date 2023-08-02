require "test_helper"

class Avo::MaintenanceTaskRunsControllerTest < ActionDispatch::IntegrationTest
  include AdminHelpers

  test "getting runs as admin" do
    admin = create(:admin_github_user, :is_admin)
    admin_sign_in_as admin

    get avo.resources_maintenance_tasks_runs_path

    assert_response :success

    MaintenanceTasks::Runner.run(name: "Maintenance::UserTotpSeedEmptyToNilTask")

    get avo.resources_maintenance_tasks_runs_path

    assert_response :success

    get avo.resources_maintenance_tasks_run_path(MaintenanceTasks::Run.sole)

    assert_response :success
  end
end
