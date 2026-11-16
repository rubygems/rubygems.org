# frozen_string_literal: true

require "test_helper"

class OrganizationDomainCheckTest < ActiveSupport::TestCase
  should belong_to(:organization_domain)

  should "have exactly the four outcomes" do
    assert_equal %w[matched record_not_found record_mismatch other_error].sort, OrganizationDomainCheck.outcomes.keys.sort
    assert_equal %w[success failure].sort, OrganizationDomainCheck.results.keys.sort
  end

  should "require checked_at and a valid result and outcome" do
    refute_predicate build(:organization_domain_check, checked_at: nil), :valid?
    refute_predicate build(:organization_domain_check, result: nil), :valid?
    refute_predicate build(:organization_domain_check, result: "bogus"), :valid?
    refute_predicate build(:organization_domain_check, outcome: nil), :valid?
    refute_predicate build(:organization_domain_check, outcome: "bogus"), :valid?
  end

  should "not have error codes or groups any more" do
    refute OrganizationDomainCheck.const_defined?(:ERROR_GROUPS)
    refute_includes OrganizationDomainCheck.column_names, "error_code"
  end

  should "return only the latest check per domain" do
    one = create(:organization_domain)
    two = create(:organization_domain)
    create(:organization_domain_check, organization_domain: one, checked_at: 3.hours.ago)
    newest = create(:organization_domain_check, :failure, organization_domain: one, checked_at: 1.hour.ago)
    create(:organization_domain_check, organization_domain: one, checked_at: 2.hours.ago)
    other = create(:organization_domain_check, organization_domain: two)

    assert_equal({ one.id => newest, two.id => other }, OrganizationDomainCheck.latest_by_domain_id([one.id, two.id]))
  end
end
