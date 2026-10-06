# frozen_string_literal: true

require "test_helper"

class Admin::HistoricalOwnershipPolicyTest < AdminPolicyTestCase
  setup do
    @historical_ownership = FactoryBot.create(:historical_ownership)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@historical_ownership], policy_scope!(@admin, HistoricalOwnership).to_a
  end

  def test_avo_index
    refute_authorizes @admin, HistoricalOwnership, :avo_index?
    refute_authorizes @non_admin, HistoricalOwnership, :avo_index?
  end

  def test_avo_show
    assert_authorizes @admin, @historical_ownership, :avo_show?

    refute_authorizes @non_admin, @historical_ownership, :avo_show?
  end

  def test_avo_create
    refute_authorizes @admin, HistoricalOwnership, :avo_create?
    refute_authorizes @non_admin, HistoricalOwnership, :avo_create?
  end

  def test_avo_update
    refute_authorizes @admin, @historical_ownership, :avo_update?
    refute_authorizes @non_admin, @historical_ownership, :avo_update?
  end

  def test_avo_destroy
    refute_authorizes @admin, @historical_ownership, :avo_destroy?
    refute_authorizes @non_admin, @historical_ownership, :avo_destroy?
  end
end
