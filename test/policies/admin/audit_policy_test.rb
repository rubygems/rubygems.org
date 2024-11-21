require "test_helper"

class Admin::AuditPolicyTest < AdminPolicyTestCase
  setup do
    @audit = create(:audit)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@audit], policy_scope!(
      @admin,
      Audit
    ).to_a

    assert_empty policy_scope!(
      @non_admin,
      Audit
    ).to_a
  end

  def test_avo_show
    assert_authorizes @admin, @audit, :avo_show?

    refute_authorizes @non_admin, @audit, :avo_show?
  end
end
