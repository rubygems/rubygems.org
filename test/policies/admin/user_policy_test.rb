require "test_helper"

class Admin::UserPolicyTest < AdminPolicyTestCase
  setup do
    @user = FactoryBot.create(:user)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
  end

  def test_show
  end

  def test_create
  end

  def test_update
  end

  def test_destroy
  end

  def test_search
    assert_authorizes @admin, @user, :avo_search?
    refute_authorizes @non_admin, @user, :avo_search?
  end
end
