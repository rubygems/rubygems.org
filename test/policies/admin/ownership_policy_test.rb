require "test_helper"

class Admin::OwnershipPolicyTest < AdminPolicyTestCase
  setup do
    @ownership = FactoryBot.create(:ownership)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@ownership], policy_scope!(@admin, Ownership).to_a
  end

  def test_avo_index
    refute_predicate policy!(@admin, Ownership), :avo_index?
    refute_predicate policy!(@non_admin, Ownership), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @ownership), :avo_show?
    refute_predicate policy!(@non_admin, @ownership), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, Ownership), :avo_create?
    refute_predicate policy!(@non_admin, Ownership), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @ownership), :avo_update?
    refute_predicate policy!(@non_admin, @ownership), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @ownership), :avo_destroy?
    refute_predicate policy!(@non_admin, @ownership), :avo_destroy?
  end
end
