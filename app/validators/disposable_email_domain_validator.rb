# frozen_string_literal: true

class DisposableEmailDomainValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    domain = value.split("@").last
    return if domain.blank?

    domain = domain.downcase
    return unless BlockedEmailDomain.blocks?(domain)

    record.errors.add(attribute, I18n.t("activerecord.errors.messages.disposable_email_domain", domain: domain))
  end
end
