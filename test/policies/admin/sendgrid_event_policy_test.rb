require "test_helper"

class Admin::SendgridEventPolicyTest < AdminPolicyTestCase
  setup do
    @sendgrid_event = FactoryBot.create(:sendgrid_event)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@sendgrid_event], policy_scope!(
      @admin,
      SendgridEvent
    ).to_a
  end

  def test_avo_index
    refute_predicate policy!(@admin, ApiKey), :avo_index?
    refute_predicate policy!(@non_admin, ApiKey), :avo_index?
  end

  def test_avo_show
    assert_predicate policy!(@admin, @sendgrid_event), :avo_show?
    refute_predicate policy!(@non_admin, @sendgrid_event), :avo_show?
  end

  def test_avo_create
    refute_predicate policy!(@admin, ApiKey), :avo_create?
    refute_predicate policy!(@non_admin, ApiKey), :avo_create?
  end

  def test_avo_update
    refute_predicate policy!(@admin, @sendgrid_event), :avo_update?
    refute_predicate policy!(@non_admin, @sendgrid_event), :avo_update?
  end

  def test_avo_destroy
    refute_predicate policy!(@admin, @sendgrid_event), :avo_destroy?
    refute_predicate policy!(@non_admin, @sendgrid_event), :avo_destroy?
  end

  def test_act_on
    refute_predicate policy!(@admin, @sendgrid_event), :act_on?
    refute_predicate policy!(@non_admin, @sendgrid_event), :act_on?
  end
end
