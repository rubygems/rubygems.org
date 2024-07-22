require "test_helper"

class Admin::GitHubUserPolicyTest < AdminPolicyTestCase
  def policy_class
    Admin::GitHubUserPolicy
  end

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
    assert_authorizes @admin, @user, :avo_show?
    assert_authorizes @admin, @user, :avo_show?
    assert_authorizes @admin, @admin, :avo_show?

    refute_authorizes @user, @user, :avo_show?
    refute_authorizes @user, @admin, :avo_show?
  end

  def test_avo_create
    refute_authorizes @user, @user, :avo_create?
    refute_authorizes @admin, @admin, :avo_create?
  end

  def test_avo_update
    refute_authorizes @user, @user, :avo_update?
    refute_authorizes @admin, @admin, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @user, @user, :avo_destroy?
    refute_authorizes @admin, @admin, :avo_destroy?
  end
end
