require "test_helper"

class Admin::SubscriptionPolicyTest < AdminPolicyTestCase
  setup do
    @subscription = create(:subscription)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_scope
    assert_equal [@subscription], policy_scope!(
      @admin,
      Subscription
    ).to_a

    assert_empty policy_scope!(
      @non_admin,
      Subscription
    ).to_a
  end

  def test_avo_show
    assert_authorizes @admin, @subscription, :avo_show?

    refute_authorizes @non_admin, @subscription, :avo_show?
  end
end
