require "test_helper"

class Admin::RubygemTransferPolicyTest < AdminPolicyTestCase
  setup do
    @rubygem_transfer = FactoryBot.create(:rubygem_transfer)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@rubygem_transfer], policy_scope!(
      @admin,
      RubygemTransfer
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, RubygemTransfer, :avo_index?

    refute_authorizes @non_admin, RubygemTransfer, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @rubygem_transfer, :avo_show?

    refute_authorizes @non_admin, @rubygem_transfer, :avo_show?
  end

  def test_act_on
    assert_authorizes @admin, @rubygem_transfer, :act_on?

    refute_authorizes @non_admin, @rubygem_transfer, :act_on?
  end
end
