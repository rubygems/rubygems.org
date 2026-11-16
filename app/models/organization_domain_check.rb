# frozen_string_literal: true

class OrganizationDomainCheck < ApplicationRecord
  MAX_MESSAGE_LENGTH = 500

  belongs_to :organization_domain

  enum :result, { success: "success", failure: "failure" }, validate: true
  enum :outcome, {
    matched: "matched",
    record_not_found: "record_not_found",
    record_mismatch: "record_mismatch",
    other_error: "other_error"
  }, validate: true

  validates :checked_at, presence: true

  def self.latest_by_domain_id(domain_ids)
    where(organization_domain_id: domain_ids)
      .select("DISTINCT ON (organization_domain_id) organization_domain_checks.*")
      .order(:organization_domain_id, checked_at: :desc, id: :desc)
      .index_by(&:organization_domain_id)
  end
end
