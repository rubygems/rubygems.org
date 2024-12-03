require "test_helper"

class Admin::VersionPolicyTest < AdminPolicyTestCase
  setup do
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
    @version = FactoryBot.create(:version, :yanked)
  end

  def test_scope
    assert_equal [@version], policy_scope!(
      @admin,
      Version
    ).to_a
    assert_empty policy_scope!(
      @non_admin,
      Version
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, Version, :avo_index?

    refute_authorizes @non_admin, Version, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @version, :avo_show?

    refute_authorizes @non_admin, @version, :avo_show?
  end

  def test_act_on
    assert_authorizes @admin, @version, :act_on?

    refute_authorizes @non_admin, @version, :act_on?
  end
end
