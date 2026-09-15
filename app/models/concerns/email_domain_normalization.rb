# frozen_string_literal: true

module EmailDomainNormalization
  extend ActiveSupport::Concern

  DOMAIN_FORMAT = /\A[a-z0-9][a-z0-9.-]*\.[a-z]{2,}\z/i

  included do
    validates :domain, presence: true,
      uniqueness: { case_sensitive: false },
      length: { maximum: 253 },
      format: { with: DOMAIN_FORMAT }

    before_validation :normalize_domain
    validate :domain_must_be_registrable
  end

  class_methods do
    def candidate_domains(email_or_domain)
      raw = email_or_domain.to_s
      domain = raw.include?("@") ? raw.split("@").last : raw
      domain = domain.downcase.strip
      return [] if domain.blank?

      parts = domain.split(".")
      Array.new(parts.length) { |i| parts[i..].join(".") }
    end
  end

  private

  def normalize_domain
    self.domain = domain&.strip&.downcase
  end

  def domain_must_be_registrable
    return if domain.blank?
    return if PublicSuffix.valid?(domain)
    errors.add(:domain, :public_suffix)
  end
end
