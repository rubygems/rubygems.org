class LinkVerification < ApplicationRecord
  belongs_to :linkable, polymorphic: true

  MAX_FAILURES = 10
  VALIDITY = 1.month

  def self.verified
    where(last_verified_at: VALIDITY.ago.beginning_of_day..)
  end

  def self.unverified
    never_verified
      .or(last_verified_before(VALIDITY.ago.beginning_of_day))
  end

  def self.never_verified
    where(last_verified_at: nil)
  end

  def self.last_verified_before(time)
    where(last_verified_at: ...time)
  end

  def self.pending_verification
    never_verified
      .or(last_verified_before(3.weeks.ago.beginning_of_day))
      .where(failures_since_last_verification: 0)
      .https_uri
  end

  def self.https_uri
    where(arel_table[:uri].matches("https://%"))
  end

  def self.linkable(linkable)
    where(linkable:)
  end

  def self.for_uri(uri)
    where(uri:)
  end

  def unverified?
    !verified?
  end

  def verified?
    return false unless (verified_at = last_verified_at.presence)

    verified_at > VALIDITY.ago
  end

  def should_verify?
    return false unless https?
    return false unless failures_since_last_verification <= 0

    unverified? || last_verified_at.before?(3.weeks.ago.beginning_of_day)
  end

  def verify_later
    VerifyLinkJob.perform_later(link_verification: self)
  end

  def retry_if_needed
    if previously_new_record? && should_verify?
      verify_later
      return self
    end

    return unless https?
    return unless failures_since_last_verification.positive? && last_failure_at.present?
    return unless last_verified_at.nil? || last_verified_at.before?(last_failure_at)

    update!(failures_since_last_verification: 0)
  end

  def https?
    uri.start_with?("https://")
  end
end
