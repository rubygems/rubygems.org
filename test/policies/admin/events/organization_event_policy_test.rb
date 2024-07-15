require "test_helper"

class Admin::Events::OrganizationEventPolicyTest < AdminPolicyTestCase
  setup do
    @organization = FactoryBot.create(:organization)
    @event = Events::OrganizationEvent.first
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@event], policy_scope!(@admin, Events::OrganizationEvent).to_a
  end

  def test_show
    assert_authorizes @admin, @event, :avo_show?
    refute_authorizes @non_admin, @event, :avo_show?
  end

  def test_create
    refute_authorizes @admin, @event, :avo_create?
    refute_authorizes @non_admin, @event, :avo_create?
  end

  def test_update
    refute_authorizes @admin, @event, :avo_update?
    refute_authorizes @non_admin, @event, :avo_update?
  end

  def test_destroy
    refute_authorizes @admin, @event, :avo_destroy?
    refute_authorizes @non_admin, @event, :avo_destroy?
  end
end
