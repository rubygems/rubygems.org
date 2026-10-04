# frozen_string_literal: true

class PrefixReservation < ApplicationRecord
  validates :prefix, uniqueness: { case_sensitive: false },
    presence: true,
    length: { maximum: Gemcutter::MAX_FIELD_LENGTH, minimum: 3 }
  validate :downcase_prefix_check

  belongs_to :organization

  scope :covering, lambda { |name|
    where("left(?, length(prefix)) = lower(prefix)", name.to_s.downcase.strip)
  }

  def self.reserved?(name)
    covering(name).exists?
  end

  def permitted?(rubygem)
    return true if rubygem.organization_id == organization_id
    # TODO: do we need to do these last two? Will a gem always be owned by an organization?
    return true if rubygem.pushed_by.is_a?(User) && organization.user_is_member?(rubygem.pushed_by)
    return true if rubygem.owners.any? { organization.user_is_member?(it) }

    pending_trusted_publisher_member?(rubygem.name)
  end

  def conflict_message(name)
    "'#{name}' starts with '#{prefix}', a prefix reserved by the #{organization.handle} organization."
  end

  private

  # A gem first pushed by a trusted publisher has no owner yet at validation
  # time; the pending publisher records the user who claimed the name.
  def pending_trusted_publisher_member?(rubygem_name)
    OIDC::PendingTrustedPublisher.unexpired.rubygem_name_is(rubygem_name).any? { organization.user_is_member?(it.user) }
  end

  def downcase_prefix_check
    return unless prefix.to_s != prefix.to_s.downcase
    errors.add(:prefix, "must be all lowercase")
  end
end
