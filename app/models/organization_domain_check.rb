# frozen_string_literal: true

# Append-only record of one DNS verification attempt.
class OrganizationDomainCheck < ApplicationRecord
  ERROR_GROUPS = {
    lookup_failed: %w[timeout resolver_unavailable],
    record_missing: %w[domain_not_found record_not_found record_at_wrong_name],
    record_mismatch: %w[value_quoted token_mismatch value_mismatch],
    conflict: %w[already_verified],
    unknown: %w[unknown_error]
  }.each_value(&:freeze).freeze

  belongs_to :organization_domain

  enum :result, { success: "success", failure: "failure" }, validate: true
  enum :error_code, ERROR_GROUPS.values.flatten.index_with(&:itself), validate: { allow_nil: true }

  validates :checked_at, presence: true

  def error_group
    ERROR_GROUPS.find { |_group, codes| codes.include?(error_code) }&.first
  end
end
