require "test_helper"

class Admin::Admin::GitHubUserPolicyTest < AdminPolicyTestCase
  setup do
    @user = FactoryBot.create(:admin_github_user)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
  end

  def test_scope
    assert_equal [@user], policy_scope!(
      @user,
      Admin::GitHubUser
    ).to_a

    assert_equal [@user, @admin], policy_scope!(
      @admin,
      Admin::GitHubUser
    ).to_a
  end

  def test_avo_show
    assert_predicate policy!(@admin, @user), :avo_show?
    assert_predicate policy!(@admin, @admin), :avo_show?
    refute_predicate policy!(@user, @user), :avo_show?
    refute_predicate policy!(@user, @admin), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@user, @user), :avo_create?
    refute_predicate policy!(@admin, @admin), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@user, @user), :avo_update?
    refute_predicate policy!(@admin, @admin), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@user, @user), :avo_destroy?
    refute_predicate policy!(@admin, @admin), :avo_destroy?
  end
end
