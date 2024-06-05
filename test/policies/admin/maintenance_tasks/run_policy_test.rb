require "test_helper"

class Admin::MaintenanceTasks::RunPolicyTest < AdminPolicyTestCase
  setup do
    @run = create(:maintenance_tasks_run)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@run], policy_scope!(
      @admin,
      MaintenanceTasks::Run
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, MaintenanceTasks::Run, :avo_index?

    refute_authorizes @non_admin, MaintenanceTasks::Run, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @run, :avo_show?

    refute_authorizes @non_admin, @run, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, MaintenanceTasks::Run, :avo_create?
    refute_authorizes @non_admin, MaintenanceTasks::Run, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @run, :avo_update?
    refute_authorizes @non_admin, @run, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @run, :avo_destroy?
    refute_authorizes @non_admin, @run, :avo_destroy?
  end
end
