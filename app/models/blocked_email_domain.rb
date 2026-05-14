# frozen_string_literal: true

class BlockedEmailDomain < ApplicationRecord
  enum :source, { upstream: 0, manual: 1 }

  DOMAIN_FORMAT = /\A[a-z0-9][a-z0-9.-]*\.[a-z]{2,}\z/i

  validates :domain, presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT }
  validates :notes, length: { maximum: 500 }, allow_blank: true

  before_validation :normalize_domain

  scope :matching_email, ->(email) { where(domain: candidate_domains(email)) }

  def self.blocks?(email_or_domain)
    candidates = candidate_domains(email_or_domain)
    return false if candidates.empty?
    exists?(domain: candidates)
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
end
