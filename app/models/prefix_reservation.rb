# frozen_string_literal: true

class PrefixReservation < ApplicationRecord
  validates :prefix, presence: true,
    length: { maximum: Gemcutter::MAX_FIELD_LENGTH, minimum: 3 }
  validate :prefix_format
  validate :downcase_prefix_check
  validate :prefix_does_not_overlap

  belongs_to :organization, optional: true
  # Audits keep pointing at a destroyed reservation so its create and destroy
  # audits stay linked to each other.
  has_many :audits, as: :auditable, inverse_of: :auditable, dependent: nil

  # Prefixes are validated lowercase, so only the name needs downcasing.
  scope :covering, lambda { |name|
    where("left(?, length(prefix)) = prefix", name.to_s.downcase)
  }

  # Reservations where one prefix starts with the other, including an exact
  # match, so a gem name could match both.
  scope :overlapping, lambda { |prefix|
    value = prefix.to_s.downcase
    where("left(:value, length(prefix)) = prefix OR left(prefix, length(:value)) = :value", value:)
  }

  def self.reserved?(name)
    covering(name).exists?
  end

  # A new gem under the prefix must be claimed for the reserving organization
  # by a user who can claim the prefix. A gem already in the organization can
  # be renamed into the prefix, since an admin had to add it to the organization.
  def permitted?(rubygem)
    return false if organization.nil?
    return rubygem.organization_id == organization_id if rubygem.persisted?

    rubygem.claimed_organization == organization && claimable_by?(rubygem.claimed_by)
  end

  # Whether the user may claim a new gem under the prefix for the reserving
  # organization. Uses the same role check as Pusher, so a prefix with no
  # organization, or a deleted one, can't be claimed by anyone.
  def claimable_by?(user)
    return false if organization.nil?

    OrganizationPolicy.new(user, organization).add_gem?
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

  # A prefix with characters no gem name can contain would reserve nothing.
  # Unlike a gem name, a prefix may end with a separator, e.g. "acme-".
  def prefix_format
    return if prefix.blank?

    errors.add(:prefix, "can only include letters, numbers, periods, dashes, and underscores") unless Patterns::NAME_PATTERN.match?(prefix)
    errors.add(:prefix, "can not begin with a period, dash, or underscore") if Patterns::SPECIAL_CHAR_PREFIX_REGEXP.match?(prefix)
  end

  def downcase_prefix_check
    return unless prefix.to_s != prefix.to_s.downcase
    errors.add(:prefix, "must be all lowercase")
  end
end
