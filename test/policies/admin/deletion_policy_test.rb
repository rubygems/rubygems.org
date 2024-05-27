require "test_helper"

class Admin::DeletionPolicyTest < AdminPolicyTestCase
  setup do
    @version = create(:version)
    @deletion = Deletion.create!(version: @version, user: create(:user))
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@deletion], policy_scope!(
      @admin,
      Deletion
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, Deletion), :avo_index?
    refute_predicate policy!(@non_admin, Deletion), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @deletion), :avo_show?
    refute_predicate policy!(@non_admin, @deletion), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, Deletion), :avo_create?
    refute_predicate policy!(@non_admin, Deletion), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @deletion), :avo_update?
    refute_predicate policy!(@non_admin, @deletion), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @deletion), :avo_destroy?
    refute_predicate policy!(@non_admin, @deletion), :avo_destroy?
  end
end
