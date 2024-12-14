require "test_helper"

class Admin::IpAddressPolicyTest < AdminPolicyTestCase
  setup do
    @ip_address = create(:ip_address)
    @admin = create(:admin_github_user, :is_admin)
    @non_admin = create(:admin_github_user)
  end

  def test_associations
    assert_association @admin, @ip_address, :user_events, Admin::Events::UserEventPolicy
    assert_association @admin, @ip_address, :rubygem_events, Admin::Events::RubygemEventPolicy
    assert_association @admin, @ip_address, :organization_events, Admin::Events::OrganizationEventPolicy
  end

  def test_scope
    assert_equal [@ip_address], policy_scope!(
      @admin,
      IpAddress
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, @ip_address, :avo_index?

    refute_authorizes @non_admin, @ip_address, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @ip_address, :avo_show?

    refute_authorizes @non_admin, @ip_address, :avo_show?
  end
end
