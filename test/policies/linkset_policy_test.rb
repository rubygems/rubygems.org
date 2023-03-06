require "test_helper"

class LinksetPolicyTest < ActiveSupport::TestCase
  setup do
    @linkset = FactoryBot.create(:rubygem).linkset
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@linkset], Pundit.policy_scope!(
      @admin,
      Linkset
    ).to_a
  end

  def test_avo_index
    assert_predicate Pundit.policy!(@admin, Linkset), :avo_index?
    refute_predicate Pundit.policy!(@non_admin, Linkset), :avo_index?
  end

  def test_avo_show
    assert_predicate Pundit.policy!(@admin, @linkset), :avo_show?
    refute_predicate Pundit.policy!(@non_admin, @linkset), :avo_show?
  end

  def test_avo_create
    refute_predicate Pundit.policy!(@admin, Linkset), :avo_create?
    refute_predicate Pundit.policy!(@non_admin, Linkset), :avo_create?
  end

  def test_avo_update
    refute_predicate Pundit.policy!(@admin, @linkset), :avo_update?
    refute_predicate Pundit.policy!(@non_admin, @linkset), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Pundit.policy!(@admin, @linkset), :avo_destroy?
    refute_predicate Pundit.policy!(@non_admin, @linkset), :avo_destroy?
  end
end
