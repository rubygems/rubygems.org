# frozen_string_literal: true

require "test_helper"

class Admin::OrganizationDomainPolicyTest < AdminPolicyTestCase
  WRITE_ACTIONS = %i[avo_create? avo_update? avo_destroy?].freeze

  setup do
    @domain = FactoryBot.create(:organization_domain, :verified)
    @check = FactoryBot.create(:organization_domain_check, organization_domain: @domain)
    @admin = FactoryBot.create(:admin_github_user, :is_admin)
    @non_admin = FactoryBot.create(:admin_github_user)
  end

  def test_scope
    assert_equal [@domain], policy_scope!(@admin, OrganizationDomain).to_a
    assert_equal [@check], policy_scope!(@admin, OrganizationDomainCheck).to_a
  end

  def test_avo_index_and_show
    [@domain, @check].each do |record|
      assert_authorizes @admin, record, :avo_index?
      assert_authorizes @admin, record, :avo_show?
      refute_authorizes @non_admin, record, :avo_index?
      refute_authorizes @non_admin, record, :avo_show?
    end
  end

  def test_read_only
    [@domain, @check].product(WRITE_ACTIONS).each do |record, action|
      refute_authorizes @admin, record, action
    end
  end

  def test_act_on
    assert_authorizes @admin, @domain, :act_on?
    refute_authorizes @non_admin, @domain, :act_on?
  end

  def test_associations
    assert_authorizes @admin, @domain, :view_checks?
    refute_authorizes @admin, @domain, :edit_checks?
    refute_authorizes @admin, @domain, :create_checks?
    refute_authorizes @admin, @domain, :destroy_checks?
    assert_authorizes @admin, @domain.organization, :view_domains?
    refute_authorizes @admin, @domain.organization, :create_domains?
  end
end
