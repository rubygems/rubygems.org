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
  include EmailDomainNormalization

  has_many :audits, as: :auditable, dependent: :nullify

  validates :notes, length: { maximum: 500 }, allow_blank: true

  def self.allows?(email_or_domain)
    candidates = candidate_domains(email_or_domain)
    return false if candidates.empty?
    exists?(domain: candidates)
  end
end
