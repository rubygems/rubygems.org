# frozen_string_literal: true

# Rejects email addresses whose domain (or any parent of it) appears in the
# BlockedEmailDomain table. The table is kept in sync with the upstream
# disposable-email-domains project and may also contain admin-added entries.
# An entry on EmailDomainAllowlist exempts a domain (and its subdomains).
class DisposableEmailDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    domain = value.split("@").last
    return if domain.blank?

    domain = domain.downcase
    match = BlockedEmailDomain.match(domain)
    return unless match

    # Low-cardinality tag (only two possible values: upstream/manual) lets us
    # answer "how often is this firing, and from which list source?".
    StatsD.increment("email_domain.blocked", tags: { source: match.source })

    # Surface the matched parent (e.g., "mailinator.com") rather than the raw
    # input (e.g., "sub.mailinator.com") so the user can see exactly which
    # entry blocked them.
    record.errors.add(attribute, :disposable_email_domain, domain: match.domain)
  end
end
