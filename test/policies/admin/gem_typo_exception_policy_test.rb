require "test_helper"

class Admin::GemTypoExceptionPolicyTest < AdminPolicyTestCase
  setup do
    @exception = create(:gem_typo_exception)

    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@exception], policy_scope!(
      @admin,
      GemTypoException
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, GemTypoException, :avo_index?

    refute_authorizes @non_admin, GemTypoException, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @exception, :avo_show?

    refute_authorizes @non_admin, @exception, :avo_show?
  end

  def test_avo_create
    assert_authorizes @admin, GemTypoException, :avo_create?

    refute_authorizes @non_admin, GemTypoException, :avo_create?
  end

  def test_avo_update
    assert_authorizes @admin, @exception, :avo_update?

    refute_authorizes @non_admin, @exception, :avo_update?
  end

  def test_avo_destroy
    assert_authorizes @admin, @exception, :avo_destroy?

    refute_authorizes @non_admin, @exception, :avo_destroy?
  end
end
