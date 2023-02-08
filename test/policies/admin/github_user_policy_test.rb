require "test_helper"

class Admin::GitHubUserPolicyTest < ActiveSupport::TestCase
  setup do
    @user = FactoryBot.create(:admin_github_user)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
  end

  def test_scope
    assert_equal [@user], Admin::GitHubUserPolicy::Scope.new(
      @user,
      Admin::GitHubUser.all
    ).resolve.to_a

    assert_equal [@user, @admin], Admin::GitHubUserPolicy::Scope.new(
      @admin,
      Admin::GitHubUser.all
    ).resolve.to_a
  end

  def test_avo_show
    assert_predicate Admin::GitHubUserPolicy.new(@admin, @user), :avo_show?
    assert_predicate Admin::GitHubUserPolicy.new(@admin, @admin), :avo_show?
    refute_predicate Admin::GitHubUserPolicy.new(@user, @user), :avo_show?
    refute_predicate Admin::GitHubUserPolicy.new(@user, @admin), :avo_show?
  end

  def test_avo_create
    refute_predicate Admin::GitHubUserPolicy.new(@user, @user), :avo_create?
    refute_predicate Admin::GitHubUserPolicy.new(@admin, @admin), :avo_create?
  end

  def test_avo_update
    refute_predicate Admin::GitHubUserPolicy.new(@user, @user), :avo_update?
    refute_predicate Admin::GitHubUserPolicy.new(@admin, @admin), :avo_update?
  end

  def test_avo_destroy
    refute_predicate Admin::GitHubUserPolicy.new(@user, @user), :avo_destroy?
    refute_predicate Admin::GitHubUserPolicy.new(@admin, @admin), :avo_destroy?
  end
end
