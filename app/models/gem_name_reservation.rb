# frozen_string_literal: true

class GemNameReservation < ApplicationRecord
  ORGANIZATION_LIMIT = 25

  validates :name, uniqueness: { case_sensitive: false }, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :downcase_name_check
  validate :rubygem_name_available, if: :needs_name_validation?
  validate :organization_within_limit, if: :needs_limit_validation?

  has_many :audits, as: :auditable, inverse_of: :auditable, dependent: :nullify

  belongs_to :organization, optional: true

  def self.reserved?(name)
    where(name: name.downcase).any?
  end

  private

  def needs_name_validation?
    new_record? || name_changed?
  end

  def needs_limit_validation?
    organization.present? && (new_record? || organization_id_changed?)
  end

  def organization_within_limit
    return if organization.gem_name_reservations_unlimited?
    return if organization.gem_name_reservations.count < ORGANIZATION_LIMIT

    errors.add(:base, :organization_limit_reached, count: ORGANIZATION_LIMIT)
  end

  def rubygem_name_available
    return unless Rubygem.where("lower(name) = ?", name&.downcase).any?
    errors.add(:name, "rubygem exists with name")
  end

  def downcase_name_check
    return unless name.to_s != name.to_s.downcase
    errors.add(:name, "must be all lowercase")
  end
end
