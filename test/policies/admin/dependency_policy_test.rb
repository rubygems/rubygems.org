require "test_helper"

class Admin::DependencyPolicyTest < AdminPolicyTestCase
  setup do
    @dependency = create(:dependency)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@dependency], policy_scope!(
      @admin,
      Dependency
    ).to_a
  end

  def test_avo_show
    assert_authorizes @admin, @dependency, :avo_show?

    refute_authorizes @non_admin, @dependency, :avo_show?
  end
end
