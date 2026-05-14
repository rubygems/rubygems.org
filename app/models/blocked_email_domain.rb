# frozen_string_literal: true

class BlockedEmailDomain < ApplicationRecord
  enum :source, { upstream: 0, manual: 1 }

  DOMAIN_FORMAT = /\A[a-z0-9][a-z0-9.-]*\.[a-z]{2,}\z/i

  validates :domain, presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT }
  validates :notes, length: { maximum: 500 }, allow_blank: true

  after_initialize :default_source_to_manual, if: :new_record?
  before_validation :normalize_domain

  scope :matching_email, ->(email) { where(domain: candidate_domains(email)) }

  # Returns the BlockedEmailDomain row matching email_or_domain (by any suffix),
  # or nil if no match. Allowlist short-circuits to nil. Callers that just want
  # a yes/no can use #blocks?; callers that need the row (e.g., to tag a metric
  # by source) use #match.
  def self.match(email_or_domain)
    candidates = candidate_domains(email_or_domain)
    return nil if candidates.empty?
    return nil if EmailDomainAllowlist.exists?(domain: candidates)
    where(domain: candidates).first
  end

  def self.blocks?(email_or_domain)
    !match(email_or_domain).nil?
  end

  def self.candidate_domains(email_or_domain)
    raw = email_or_domain.to_s
    domain = raw.include?("@") ? raw.split("@").last : raw
    domain = domain.to_s.downcase.strip
    return [] if domain.blank?

    parts = domain.split(".")
    Array.new(parts.length) { |i| parts[i..].join(".") }
  end

  private

  def normalize_domain
    self.domain = domain&.strip&.downcase
  end

  # New records default to :manual so admin-created rows can never accidentally
  # land as :upstream. The sync job explicitly sets :upstream via upsert_all,
  # which bypasses callbacks and is unaffected.
  def default_source_to_manual
    self.source ||= :manual
  end
end
