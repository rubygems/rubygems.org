# frozen_string_literal: true

# Rejects email addresses whose domain falls under a reserved or special-use
# name that can never carry deliverable mail:
#
#   * RFC 2606 — .test, .example, .invalid, .localhost (TLDs);
#                example.com, example.net, example.org (second-level)
#   * RFC 6761 — .localhost, .invalid, .example, .test (special-use, same set)
#   * RFC 6762 / mDNS — .local
#   * RFC 7686 — .onion
class ReservedDomainValidator < ActiveModel::EachValidator
  RESERVED_TLDS = %w[test example invalid localhost local onion].freeze
  RESERVED_DOMAINS = %w[example.com example.net example.org].freeze

  def validate_each(record, attribute, value)
    return if value.blank?
    domain = value.split("@").last
    return if domain.blank?

    domain = domain.downcase
    return unless reserved?(domain)

    record.errors.add(attribute, I18n.t("activerecord.errors.messages.reserved_domain", domain: domain))
  end

  private

  def reserved?(domain)
    return true if RESERVED_DOMAINS.any? { |d| domain == d || domain.end_with?(".#{d}") }
    tld = domain.split(".").last
    RESERVED_TLDS.include?(tld)
  end
end
