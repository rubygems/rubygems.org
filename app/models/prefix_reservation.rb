# frozen_string_literal: true

class PrefixReservation < ApplicationRecord
  validates :prefix, uniqueness: { case_sensitive: false },
    presence: true,
    length: { maximum: Gemcutter::MAX_FIELD_LENGTH, minimum: 3 }
  validate :downcase_prefix_check
  validate :prefix_does_not_overlap

  belongs_to :organization

  scope :covering, lambda { |name|
    where("left(?, length(prefix)) = lower(prefix)", name.to_s.downcase.strip)
  }

  # Reservations where one prefix starts with the other, so a gem name could
  # match both. Exact matches are left to the uniqueness validation.
  scope :overlapping, lambda { |prefix|
    value = prefix.to_s.downcase.strip
    where("left(:value, length(prefix)) = lower(prefix) OR left(lower(prefix), length(:value)) = :value", value:)
      .where.not("lower(prefix) = ?", value)
  }

  def self.reserved?(name)
    covering(name).exists?
  end

  # A new gem under the prefix must be claimed for the reserving organization
  # by one of its members. A gem already in the organization can be renamed
  # into the prefix, since a member had to add it to the organization.
  def permitted?(rubygem)
    return false if organization.nil?
    return rubygem.organization_id == organization_id if rubygem.persisted?

    rubygem.claimed_organization == organization && organization.user_is_member?(rubygem.claimed_by)
  end

  def conflict_message(name)
    return "'#{name}' starts with '#{prefix}', a reserved prefix." if organization.nil?

    "'#{name}' starts with '#{prefix}', a prefix reserved by the #{organization.handle} organization. " \
      "If you are an admin of #{organization.handle}, add `spec.metadata[\"rubygems_organization\"] = " \
      "\"#{organization.handle}\"` to your gemspec to push it to the organization."
  end

  private

  # A name under two overlapping prefixes would be claimable by neither
  # organization, or by whichever reservation the lookup happened to find.
  def prefix_does_not_overlap
    return if prefix.blank?

    overlap = PrefixReservation.overlapping(prefix).where.not(id:).order(:prefix).first
    return if overlap.nil?

    owner = " for the #{overlap.organization.handle} organization" if overlap.organization
    errors.add(:prefix, "overlaps the existing '#{overlap.prefix}' reservation#{owner}")
  end

  def downcase_prefix_check
    return unless prefix.to_s != prefix.to_s.downcase
    errors.add(:prefix, "must be all lowercase")
  end
end
