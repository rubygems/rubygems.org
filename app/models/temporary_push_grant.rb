# frozen_string_literal: true

# A publish-only grant under the Temporary Push Access Policy: the grantee may push
# the listed, reviewed artifacts of one version of a gem they do not own, through an
# operator-issued API key, until the grant expires 72 hours after activation.
# It never changes ownership. Requests and decisions are recorded in the public log
# (request_url); operator actions on the grant are recorded as Avo audits.
class TemporaryPushGrant < ApplicationRecord
  DURATION = 72.hours
  OWNER_RESPONSE_PERIOD = 14.days
  REQUIRED_APPROVALS = 2

  belongs_to :rubygem
  belongs_to :grantee, class_name: "User"
  belongs_to :api_key, optional: true, inverse_of: :temporary_push_grant
  # A correction is the one follow-up release the policy allows for an original grant.
  belongs_to :original_grant, class_name: "TemporaryPushGrant", optional: true, inverse_of: :correction
  has_one :correction, class_name: "TemporaryPushGrant", foreign_key: :original_grant_id,
    inverse_of: :original_grant, dependent: :restrict_with_error
  has_many :artifacts, class_name: "TemporaryPushGrantArtifact", dependent: :destroy, inverse_of: :temporary_push_grant
  has_many :approvals, class_name: "TemporaryPushGrantApproval", dependent: :destroy, inverse_of: :temporary_push_grant
  has_many :audits, as: :auditable, inverse_of: :auditable, dependent: :restrict_with_exception

  validates :version, :source_commit, :request_url, :justification, :requester_github_login,
    :grantee_github_login, :outreach_sent_at, :response_deadline_at, presence: true
  validates :source_commit, format: /\A\h{40}(\h{24})?\z/
  validates :request_url, format: %r{\Ahttps://\S+\z}
  validates :correction_reason, presence: true, if: :original_grant
  validates :original_grant_id, uniqueness: true, allow_nil: true
  validate :shortened_response_period_is_justified
  validate :correction_of_an_original_grant_for_the_same_gem, if: :original_grant

  def correction?
    original_grant_id.present?
  end

  def status
    if revoked_at then :revoked
    elsif activated_at.nil? then :draft
    elsif expired? then :expired
    elsif suspended_at then :suspended
    elsif artifacts.all?(&:published?) then :completed
    else :active
    end
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  # Everything the two operators approve. Approvals and the technical review record the
  # digest they saw, so any later change to the scope or artifacts voids them.
  def scope_digest
    Digest::SHA256.hexdigest(JSON.generate(
                               rubygem_id:, grantee_id:, version:, source_commit:, request_url:, justification:,
                               requester_github_login:, grantee_github_login:, original_grant_id:, correction_reason:,
                               outreach_sent_at: outreach_sent_at&.utc&.iso8601, response_deadline_at: response_deadline_at&.utc&.iso8601,
                               shortened_response_reason:,
                               artifacts: artifacts.order(:platform).pluck(:platform, :sha256)
                             ))
  end

  def independent_approvals
    digest = scope_digest
    approvals.includes(:admin_github_user).select { |approval| approval.scope_digest == digest && approval.independent? }
  end

  def approved?
    independent_approvals.size >= REQUIRED_APPROVALS
  end

  def technically_reviewed?
    technical_reviewed_at.present? && technical_review_digest == scope_digest
  end

  def independent_login?(login)
    [requester_github_login, grantee_github_login].none? { it.to_s.casecmp?(login.to_s) }
  end

  def approve!(admin_github_user, conflict_disclosure:)
    with_lock do
      raise ActiveRecord::RecordInvalid, self if activation_locked?("approved")
      # Re-approving after a scope change replaces the operator's stale approval.
      approvals.find_or_initialize_by(admin_github_user:).update!(conflict_disclosure:, scope_digest:)
    end
  end

  def record_technical_review!(reviewer:, notes:)
    with_lock do
      raise ActiveRecord::RecordInvalid, self if activation_locked?("reviewed")
      unless independent_login?(reviewer) && reviewer.present?
        errors.add(:technical_reviewer, "must be someone other than the requester and grantee")
        raise ActiveRecord::RecordInvalid, self
      end
      update!(technical_reviewer: reviewer, technical_review_notes: notes,
              technical_reviewed_at: Time.current, technical_review_digest: scope_digest)
    end
  end

  def activation_errors # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    problems = []
    problems << "has already been activated" if activated_at
    problems << "has been revoked" if revoked_at
    problems << "needs #{REQUIRED_APPROVALS} independent operator approvals of its current scope" unless approved?
    problems << "needs an independent technical review of its current scope" unless technically_reviewed?
    problems << "must list at least one approved artifact" if artifacts.none?
    problems << "cannot be activated before the owner response deadline" if response_deadline_at&.future?
    problems << "grantee must have multi-factor authentication enabled" unless grantee.mfa_enabled?
    problems << "grantee must be a confirmed account in good standing" if grantee.unconfirmed? || grantee.blocked?
    problems << "grantee already owns #{rubygem.name} and does not need a grant" if grantee.owns_gem?(rubygem)
    problems.concat(correction_activation_errors) if correction?
    problems
  end

  # Issues the operator key, starts the expiry clock and emails the plaintext key to
  # the grantee's account address. The key is never stored, shown to the operator or
  # queued: it is delivered synchronously, so a failed delivery rolls activation back.
  def activate!
    with_lock do
      problems = activation_errors
      if problems.any?
        problems.each { errors.add(:base, it) }
        raise ActiveRecord::RecordInvalid, self
      end

      now = Time.current
      key = "rubygems_#{SecureRandom.hex(24)}"
      expiry = correction? ? original_grant.expires_at : now + DURATION
      issued_key = ApiKey.create!(
        owner: grantee, name: "temporary-push-grant-#{id}", scopes: %i[push_rubygem],
        mfa: true, expires_at: expiry, hashed_key: Digest::SHA256.hexdigest(key)
      )
      update!(activated_at: now, expires_at: expiry, api_key: issued_key)
      Mailer.temporary_push_grant_activated(self, key).deliver_now
    end
  end

  def suspend!(reason)
    with_lock do
      raise_invalid("only an active grant can be suspended") unless %i[active completed].include?(status)
      update!(suspended_at: Time.current, suspension_reason: reason)
    end
  end

  # Resuming never extends the original expiry.
  def resume!
    with_lock do
      raise_invalid("only a suspended grant can be resumed") unless status == :suspended
      update!(suspended_at: nil, suspension_reason: nil)
    end
  end

  def revoke!(reason)
    with_lock do
      raise_invalid("has already been revoked") if revoked_at
      update!(revoked_at: Time.current, revocation_reason: reason)
      api_key&.expire! unless api_key&.expired?
    end
  end

  # Why an upload through this grant's key must be refused, or nil when it is
  # acceptable. Callers lock the grant first so revocation and expiry hold at the
  # moment the artifact is accepted. Each artifact publishes once because the
  # registry never accepts a second version with the same number and platform.
  def upload_denial_reason(rubygem, version)
    unless rubygem.persisted? && rubygem.id == rubygem_id && !rubygem.name_changed?
      return "This temporary push grant only authorizes #{self.rubygem.name}."
    end
    return "This temporary push grant is #{publication_state}, so it no longer authorizes publication." unless publishable?
    return "This temporary push grant only authorizes version #{self.version}." unless version.number == self.version

    artifact = artifact_for(version)
    return "This temporary push grant does not authorize the #{version.platform} platform." unless artifact
    return if artifact.matches?(version)
    "The uploaded gem does not match the reviewed checksum for #{self.rubygem.name} #{version.number} (#{version.platform})."
  end

  def artifact_for(version)
    artifacts.find_by(platform: version.platform)
  end

  private

  def publishable?
    publication_state == :active
  end

  def publication_state
    return :revoked if original_grant&.revoked_at
    return :suspended if original_grant&.suspended_at
    return :unapproved if activated_at && !(approved? && technically_reviewed?)
    status
  end

  def activation_locked?(verb)
    return false unless activated_at || revoked_at
    errors.add(:base, "cannot be #{verb} after activation or revocation")
    true
  end

  def raise_invalid(message)
    errors.add(:base, message)
    raise ActiveRecord::RecordInvalid, self
  end

  def correction_activation_errors
    problems = []
    original = original_grant
    problems << "original grant was never activated" unless original.activated_at
    problems << "original grant has been revoked" if original.revoked_at
    problems << "original grant has expired, so a new grant is required" if original.expired?
    if original.artifacts.exists?(sha256: artifacts.select(:sha256))
      problems << "correction cannot re-authorize artifacts approved by the original grant"
    end
    problems
  end

  def shortened_response_period_is_justified
    return unless outreach_sent_at && response_deadline_at
    return if response_deadline_at >= outreach_sent_at + OWNER_RESPONSE_PERIOD || shortened_response_reason.present?

    errors.add(:shortened_response_reason, "must explain why a response period shorter than 14 days is necessary")
  end

  def correction_of_an_original_grant_for_the_same_gem
    errors.add(:original_grant, "must be an original grant, not a correction") if original_grant.correction?
    errors.add(:original_grant, "must be for the same gem") if original_grant.rubygem_id != rubygem_id
    errors.add(:original_grant, "cannot be the grant itself") if original_grant_id == id && persisted?
  end
end
