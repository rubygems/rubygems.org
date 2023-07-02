class GemNameReservation < ApplicationRecord
  validates :name, uniqueness: { case_sensitive: false }, presence: true

  def self.reserved?(name)
    where(name: name.downcase).any?
  end
end
