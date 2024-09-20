class GemNameReservation < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }, presence: true, length: { maximum: Gemcutter::MAX_FIELD_LENGTH }
  validate :downcase_name_check

  def self.reserved?(name)
    where(name: name.downcase).any?
  end

  private

  def downcase_name_check
    return unless name.to_s != name.to_s.downcase
    errors.add(:name, "must be all lowercase")
  end
end
