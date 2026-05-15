# frozen_string_literal: true

# A domain whose addresses are permitted to register on rubygems.org *even if*
# they would otherwise be blocked by a BlockedEmailDomain entry (typically an
# upstream-sourced one).
#
# This is the operator-controlled escape hatch. When upstream adds a domain
# that we know is a legitimate forwarding service (Apple Hide-My-Email,
# SimpleLogin, Firefox Relay, etc.), an admin adds it here and signups resume
# without the next sync wiping the exemption.
#
# Matching uses the same suffix-walk as BlockedEmailDomain. An allowlist row
# for `privaterelay.appleid.com` covers `xyz.privaterelay.appleid.com` too.
class EmailDomainAllowlist < ApplicationRecord
  has_many :audits, as: :auditable, dependent: :nullify

  DOMAIN_FORMAT = BlockedEmailDomain::DOMAIN_FORMAT

  validates :domain, presence: true,
    uniqueness: { case_sensitive: false },
    length: { maximum: 253 },
    format: { with: DOMAIN_FORMAT }
  validates :notes, length: { maximum: 500 }, allow_blank: true
  validate :domain_must_be_registrable

  before_validation :normalize_domain

  def self.allows?(email_or_domain)
    candidates = BlockedEmailDomain.candidate_domains(email_or_domain)
    return false if candidates.empty?
    exists?(domain: candidates)
  end

  private

  def normalize_domain
    self.domain = domain&.strip&.downcase
  end

  # Reject entries whose value is itself a public suffix (eTLD). An allowlist
  # row for "co.uk" would exempt every UK address from the blocklist, which is
  # almost certainly a misclick.
  def domain_must_be_registrable
    return if domain.blank?
    return if PublicSuffix.valid?(domain)
    errors.add(:domain, :public_suffix)
  end
end
