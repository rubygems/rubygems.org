require "test_helper"

class Admin::RubygemPolicyTest < AdminPolicyTestCase
  setup do
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
    @rubygem = FactoryBot.create(:rubygem)
  end

  def test_scope
    assert_equal [@rubygem], policy_scope!(
      @admin,
      Rubygem
    ).to_a
  end

  def test_avo_index
    assert_authorizes @admin, Rubygem, :avo_index?

    refute_authorizes @non_admin, Rubygem, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @rubygem, :avo_show?

    refute_authorizes @non_admin, @rubygem, :avo_show?
  end
end
