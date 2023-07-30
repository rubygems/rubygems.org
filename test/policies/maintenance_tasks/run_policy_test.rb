require "test_helper"

class MaintenanceTasks::RunPolicyTest < ActiveSupport::TestCase
  setup do
    @run = create(:maintenance_tasks_run)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@run], Pundit.policy_scope!(
      @admin,
      MaintenanceTasks::Run
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, MaintenanceTasks::Run), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, MaintenanceTasks::Run), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @run), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @run), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, MaintenanceTasks::Run), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, MaintenanceTasks::Run), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @run), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @run), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @run), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @run), :avo_destroy?
  end
end
