require "test_helper"

class Admin::MembershipPolicyTest < AdminPolicyTestCase
  setup do
    @membership = FactoryBot.create(:membership)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@membership], policy_scope!(@admin, Membership).to_a
  end

  def test_avo_index
    refute_authorizes @admin, Membership, :avo_index?
    refute_authorizes @non_admin, Membership, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @membership, :avo_show?

    refute_authorizes @non_admin, @membership, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, Membership, :avo_create?
    refute_authorizes @non_admin, Membership, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @membership, :avo_update?
    refute_authorizes @non_admin, @membership, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @membership, :avo_destroy?
    refute_authorizes @non_admin, @membership, :avo_destroy?
  end
end
