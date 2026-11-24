# frozen_string_literal: true

# One reviewed gem file a temporary push grant may publish once, identified by its
# platform and the SHA-256 of its exact bytes.
class TemporaryPushGrantArtifact < ApplicationRecord
  belongs_to :temporary_push_grant, inverse_of: :artifacts
  belongs_to :version, optional: true, inverse_of: :temporary_push_grant_artifact

  normalizes :sha256, with: -> { it.strip.downcase }
  normalizes :platform, with: -> { it.strip }

  validates :platform, presence: true, uniqueness: { scope: :temporary_push_grant_id }
  validates :sha256, format: /\A\h{64}\z/
  validate :grant_scope_is_open, on: :create

  def published?
    version_id.present?
  end

  # Version#sha256 is base64; approved checksums are the hex digests reviewers record.
  def matches?(version)
    sha256 == version.sha256.unpack1("m0").unpack1("H*")
  end

  private

  def grant_scope_is_open
    return unless temporary_push_grant&.activated_at || temporary_push_grant&.revoked_at

    errors.add(:temporary_push_grant, "is activated or revoked, so its approved artifacts are fixed")
  end
end
