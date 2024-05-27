require "test_helper"

class Admin::LinksetPolicyTest < AdminPolicyTestCase
  setup do
    @linkset = FactoryBot.create(:rubygem).linkset
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@linkset], policy_scope!(
      @admin,
      Linkset
    ).to_a
  end

  def test_avo_index
    assert_predicate policy!(@admin, Linkset), :avo_index?
    refute_predicate policy!(@non_admin, Linkset), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @linkset), :avo_show?
    refute_predicate policy!(@non_admin, @linkset), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, Linkset), :avo_create?
    refute_predicate policy!(@non_admin, Linkset), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @linkset), :avo_update?
    refute_predicate policy!(@non_admin, @linkset), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @linkset), :avo_destroy?
    refute_predicate policy!(@non_admin, @linkset), :avo_destroy?
  end
end
