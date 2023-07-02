class GemNameReservation < ApplicationRecord
  def self.reserved?(name)
    where(name: name.downcase).any?
  end
end
