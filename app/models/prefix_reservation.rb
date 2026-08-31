# frozen_string_literal: true

class PrefixReservation < ApplicationRecord
  validates :prefix, uniqueness: { case_sensitive: false },
    presence: true,
    length: { maximum: Gemcutter::MAX_FIELD_LENGTH, minimum: 3 }
  validate :downcase_prefix_check

  belongs_to :organization

  def self.reserved?(name)
    stripped_name = name.to_s.downcase.strip
    pluck(:prefix).any? { |prefix| stripped_name.start_with?(prefix.downcase) }
  end

  private

  def downcase_prefix_check
    return unless prefix.to_s != prefix.to_s.downcase
    errors.add(:name, "must be all lowercase")
  end
end

