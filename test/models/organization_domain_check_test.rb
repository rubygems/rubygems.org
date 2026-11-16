# frozen_string_literal: true

require "test_helper"

class OrganizationDomainCheckTest < ActiveSupport::TestCase
  should belong_to(:organization_domain)

  should "map every error_code to exactly one group" do
    grouped = OrganizationDomainCheck::ERROR_GROUPS.values.flatten

    assert_equal OrganizationDomainCheck.error_codes.keys.sort, grouped.sort
    assert_equal grouped.uniq, grouped
    assert_predicate OrganizationDomainCheck::ERROR_GROUPS, :frozen?
  end

  should "use the groups from the spec" do
    assert_equal(
      {
        lookup_failed: %w[timeout resolver_unavailable],
        record_missing: %w[domain_not_found record_not_found record_at_wrong_name],
        record_mismatch: %w[value_quoted token_mismatch value_mismatch],
        conflict: %w[already_verified],
        unknown: %w[unknown_error]
      }, OrganizationDomainCheck::ERROR_GROUPS
    )
  end

  should "return the error group for the error code" do
    assert_equal :record_mismatch, build(:organization_domain_check, :failure, error_code: "token_mismatch").error_group
    assert_equal :lookup_failed, build(:organization_domain_check, :failure, error_code: "timeout").error_group
  end

  should "have no error group on success" do
    assert_nil build(:organization_domain_check).error_group
  end

  should "require checked_at and a valid result" do
    refute_predicate build(:organization_domain_check, checked_at: nil), :valid?
    refute_predicate build(:organization_domain_check, result: nil), :valid?
    refute_predicate build(:organization_domain_check, error_code: "bogus"), :valid?
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
