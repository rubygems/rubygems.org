require "test_helper"

class Admin::LogTicketPolicyTest < AdminPolicyTestCase
  setup do
    @log_ticket = FactoryBot.create(:log_ticket)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@log_ticket], policy_scope!(
      @admin,
      LogTicket
    ).to_a
  end

  def test_avo_index
    refute_authorizes @admin, ApiKey, :avo_index?
    refute_authorizes @non_admin, ApiKey, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @log_ticket, :avo_show?

    refute_authorizes @non_admin, @log_ticket, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, ApiKey, :avo_create?
    refute_authorizes @non_admin, ApiKey, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @log_ticket, :avo_update?
    refute_authorizes @non_admin, @log_ticket, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @log_ticket, :avo_destroy?
    refute_authorizes @non_admin, @log_ticket, :avo_destroy?
  end
end
