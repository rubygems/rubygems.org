# frozen_string_literal: true

class GemNameReservation < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :downcase_name_check
  validate :rubygem_name_available, if: :needs_name_validation?

  has_many :audits, as: :auditable, inverse_of: :auditable, dependent: :nullify

  def self.reserved?(name)
    where(name: name.downcase).any?
  end

  private

  def needs_name_validation?
    new_record? || name_changed?
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
